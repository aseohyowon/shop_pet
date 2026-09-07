-- ㉗ 예약 추가 옵션 (추가 산책 / 스파) — 예약 시 선택, 결제 금액에 합산

alter table public.pricing_items add column if not exists is_option boolean not null default false;
update public.pricing_items set is_option = true
  where name in ('추가 산책', '스파 (3kg 이하)', '스파 (3kg 초과 ~ 5kg 이하)');

create table if not exists public.reservation_options (
  id              uuid primary key default gen_random_uuid(),
  reservation_id  uuid not null references public.reservations (id) on delete cascade,
  pricing_item_id uuid references public.pricing_items (id),
  name            text not null,
  unit_price      int  not null,
  quantity        int  not null default 1 check (quantity > 0),
  created_at      timestamptz not null default now()
);
create index if not exists reservation_options_resv_idx on public.reservation_options (reservation_id);

alter table public.reservation_options enable row level security;
drop policy if exists "own reservation options read" on public.reservation_options;
create policy "own reservation options read" on public.reservation_options for select
  using (exists (select 1 from public.reservations r where r.id = reservation_id and r.user_id = auth.uid()));
drop policy if exists "admin reservation options read" on public.reservation_options;
create policy "admin reservation options read" on public.reservation_options for select
  using (public.is_admin());

create or replace function public.reservation_options_total(p_reservation_id uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(sum(unit_price * quantity), 0)::int
  from public.reservation_options
  where reservation_id = p_reservation_id
$$;

-- ── book_reservation: p_options 추가 ───────────────────
drop function if exists public.book_reservation(uuid, text, date, date, text, time, time, boolean, boolean);

create or replace function public.book_reservation(
  p_pet_id uuid,
  p_type text,
  p_start_date date,
  p_end_date date,
  p_memo text default null,
  p_start_time time default '09:00',
  p_end_time time default '21:00',
  p_terms_agreed boolean default false,
  p_daycare_hourly boolean default false,
  p_options jsonb default '[]'::jsonb
)
returns public.reservations
language plpgsql
security definer
set search_path = public
as $$
declare
  v_date date;
  v_capacity int;
  v_booked int;
  v_reservation public.reservations;
  v_opt jsonb;
  v_opt_item public.pricing_items;
  v_qty int;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다.'; end if;
  if not p_terms_agreed then raise exception '이용약관 및 개인정보 동의가 필요합니다.'; end if;
  if p_end_date < p_start_date then raise exception '종료일은 시작일 이후여야 합니다.'; end if;
  if p_type = 'daycare' and p_end_date <> p_start_date then raise exception '데이케어는 당일 이용만 가능합니다.'; end if;

  if p_start_time < time '09:00' or p_start_time > time '21:00'
     or p_end_time < time '09:00' or p_end_time > time '21:00' then
    raise exception '이용 시간은 09:00 ~ 21:00 사이여야 합니다.';
  end if;
  if p_end_date = p_start_date and p_end_time <= p_start_time then
    raise exception '종료 시간은 시작 시간 이후여야 합니다.';
  end if;

  if not exists (select 1 from public.pets where id = p_pet_id and owner_id = auth.uid()) then
    raise exception '본인 소유의 반려동물만 선택할 수 있습니다.';
  end if;

  if exists (
    select 1 from public.reservations
    where pet_id = p_pet_id
      and status in ('pending', 'confirmed')
      and daterange(start_date, end_date, '[]') && daterange(p_start_date, p_end_date, '[]')
  ) then
    raise exception '해당 반려동물은 이미 겹치는 기간에 예약이 있습니다. 예약 내역을 확인해주세요.';
  end if;

  for v_date in select generate_series(p_start_date, p_end_date, interval '1 day')::date loop
    perform pg_advisory_xact_lock(hashtextextended(p_type || v_date::text, 0));
    select coalesce(
      (select max_capacity from public.daily_capacity where date = v_date and type = p_type),
      (select default_capacity from public.service_settings where type = p_type),
      0
    ) into v_capacity;
    select count(*) into v_booked
      from public.reservations
      where type = p_type and status in ('pending', 'confirmed')
        and v_date between start_date and end_date;
    if v_booked >= v_capacity then
      raise exception '%에 정원이 마감되었습니다.', to_char(v_date, 'YYYY-MM-DD');
    end if;
  end loop;

  insert into public.reservations (user_id, pet_id, type, start_date, end_date, start_time, end_time, status, memo, terms_agreed_at, daycare_hourly)
  values (auth.uid(), p_pet_id, p_type, p_start_date, p_end_date, p_start_time, p_end_time, 'pending', p_memo, now(),
          (p_type = 'daycare' and p_daycare_hourly))
  returning * into v_reservation;

  -- 추가 옵션
  for v_opt in select * from jsonb_array_elements(coalesce(p_options, '[]'::jsonb)) loop
    v_qty := greatest(1, coalesce((v_opt ->> 'quantity')::int, 1));
    select * into v_opt_item from public.pricing_items
      where id = (v_opt ->> 'pricing_item_id')::uuid and is_option and is_active;
    if v_opt_item.id is null then
      raise exception '선택할 수 없는 옵션이 포함되어 있습니다.';
    end if;
    insert into public.reservation_options (reservation_id, pricing_item_id, name, unit_price, quantity)
    values (v_reservation.id, v_opt_item.id, v_opt_item.name, v_opt_item.price, v_qty);
  end loop;

  return v_reservation;
end;
$$;

grant execute on function public.book_reservation(uuid, text, date, date, text, time, time, boolean, boolean, jsonb) to authenticated;

-- ── create_reservation_payment: 옵션 금액 합산 ─────────
create or replace function public.create_reservation_payment(
  p_reservation_id uuid,
  p_points_used int default 0
)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_resv       public.reservations;
  v_setting    public.service_settings;
  v_units      int;
  v_hours      int;
  v_day_price  int;
  v_hour_price int;
  v_base       int;
  v_options    int;
  v_amount     int;
  v_rate       numeric;
  v_points     int := greatest(0, coalesce(p_points_used, 0));
  v_payable    int;
  v_balance    int;
  v_payment    public.payments;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다.'; end if;

  select * into v_resv from public.reservations where id = p_reservation_id and user_id = auth.uid();
  if v_resv.id is null then raise exception '본인의 예약만 결제할 수 있습니다.'; end if;

  if v_resv.deposit_paid or exists (
    select 1 from public.payments where target_type = 'reservation' and target_id = p_reservation_id and status = 'paid'
  ) then
    raise exception '이미 결제가 완료된 예약입니다.';
  end if;

  delete from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id and user_id = auth.uid() and status = 'ready';

  select points into v_balance from public.profiles where id = auth.uid();
  if v_points > coalesce(v_balance, 0) then
    raise exception '보유 포인트(%P)보다 많이 사용할 수 없습니다.', coalesce(v_balance, 0);
  end if;

  select * into v_setting from public.service_settings where type = v_resv.type;
  v_rate := coalesce(v_setting.deposit_rate, 1);

  if v_resv.type = 'hotel' then
    select price into v_day_price from public.pricing_items where billing_key = 'hotel_night' and is_active;
    v_day_price := coalesce(v_day_price, v_setting.price, 0);
    v_units := greatest(1, (v_resv.end_date - v_resv.start_date));
    v_base := v_day_price * v_units;
  elsif v_resv.daycare_hourly then
    select price into v_hour_price from public.pricing_items where billing_key = 'daycare_hourly' and is_active;
    select price into v_day_price  from public.pricing_items where billing_key = 'daycare_day' and is_active;
    v_hour_price := coalesce(v_hour_price, 4000);
    v_day_price  := coalesce(v_day_price, v_setting.price, 35000);
    v_hours := greatest(1, ceil(extract(epoch from (v_resv.end_time - v_resv.start_time)) / 3600.0)::int);
    v_base := least(v_hours * v_hour_price, v_day_price);
  else
    select price into v_day_price from public.pricing_items where billing_key = 'daycare_day' and is_active;
    v_day_price := coalesce(v_day_price, v_setting.price, 0);
    v_base := v_day_price;
  end if;

  v_options := public.reservation_options_total(p_reservation_id);
  v_amount := greatest(0, round(v_base * v_rate))::int + v_options;
  if v_amount = 0 then
    raise exception '결제 금액이 0원입니다. 관리자에게 문의해주세요.';
  end if;

  if v_points > v_amount then v_points := v_amount; end if;
  v_payable := v_amount - v_points;

  insert into public.payments (user_id, target_type, target_id, amount, status, points_used)
  values (auth.uid(), 'reservation', p_reservation_id, v_payable, 'ready', v_points)
  returning * into v_payment;

  if v_payable = 0 then
    perform public.consume_points_for_payment(v_payment.id);
    update public.payments set status = 'paid', method = '포인트', paid_at = now()
      where id = v_payment.id returning * into v_payment;
    update public.reservations set deposit_paid = true, status = 'confirmed'
      where id = p_reservation_id and status in ('pending', 'confirmed');
    perform public.award_purchase_points('reservation', p_reservation_id);
  end if;

  return v_payment;
end;
$$;
grant execute on function public.create_reservation_payment(uuid, int) to authenticated;

-- ── 정기권은 옵션 있는 예약에 사용 불가 ────────────────
create or replace function public.redeem_pass_for_reservation(p_reservation_id uuid, p_pass_id uuid)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_resv    public.reservations;
  v_pass    public.daycare_passes;
  v_payment public.payments;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다.'; end if;

  select * into v_resv from public.reservations where id = p_reservation_id and user_id = auth.uid();
  if v_resv.id is null then raise exception '본인의 예약만 결제할 수 있습니다.'; end if;
  if v_resv.type <> 'daycare' or v_resv.daycare_hourly then
    raise exception '정기권은 종일 데이케어 예약에만 사용할 수 있습니다.';
  end if;
  if public.reservation_options_total(p_reservation_id) > 0 then
    raise exception '추가 옵션이 있는 예약은 정기권으로 결제할 수 없습니다. 결제를 진행해주세요.';
  end if;
  if v_resv.deposit_paid or exists (
    select 1 from public.payments where target_type = 'reservation' and target_id = p_reservation_id and status = 'paid'
  ) then
    raise exception '이미 결제가 완료된 예약입니다.';
  end if;

  select * into v_pass from public.daycare_passes where id = p_pass_id and user_id = auth.uid() for update;
  if v_pass.id is null or v_pass.status <> 'active' then raise exception '사용할 수 없는 정기권입니다.'; end if;
  if v_pass.used_count >= v_pass.total_count then raise exception '정기권 잔여 횟수가 없습니다.'; end if;

  delete from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id and user_id = auth.uid() and status = 'ready';

  update public.daycare_passes set used_count = used_count + 1 where id = p_pass_id;
  insert into public.daycare_pass_usages (pass_id, reservation_id) values (p_pass_id, p_reservation_id);

  insert into public.payments (user_id, target_type, target_id, amount, status, method, paid_at)
  values (auth.uid(), 'reservation', p_reservation_id, 0, 'paid', '정기권', now())
  returning * into v_payment;

  update public.reservations set deposit_paid = true, status = 'confirmed', daycare_pass_id = p_pass_id
  where id = p_reservation_id and status in ('pending', 'confirmed');

  return v_payment;
end;
$$;
grant execute on function public.redeem_pass_for_reservation(uuid, uuid) to authenticated;
