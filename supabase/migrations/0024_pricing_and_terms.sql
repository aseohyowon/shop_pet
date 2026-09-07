-- ㉔ 요금표(pricing_items) + 예약 시 약관 동의
--   - 요금표: 관리자가 /admin/pricing 에서 자유롭게 수정. 데이케어 종일 / 호텔 1박 은
--     billing_key 로 표시해 예약 결제 기준가로 사용한다.
--   - 예약 시 이용약관 · 개인정보 수집이용 · 제3자 제공 3종 동의 필수 (reservations.terms_agreed_at)

-- ── 요금표 ─────────────────────────────────────────────
create table if not exists public.pricing_items (
  id          uuid primary key default gen_random_uuid(),
  category    text not null check (category in ('daycare', 'daycare_pass', 'hotel', 'spa')),
  name        text not null,
  price       int  not null default 0,
  unit        text,                       -- 표시용 단위 ('1시간', '1박', '8회' 등)
  note        text,                       -- 부가 설명 ('산책 1회 포함' 등)
  billing_key text unique,                -- 'hotel_night' | 'daycare_day' → 예약 결제 기준
  sort_order  int  not null default 0,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

alter table public.pricing_items enable row level security;

drop policy if exists "Anyone can read active pricing" on public.pricing_items;
create policy "Anyone can read active pricing"
  on public.pricing_items for select using (is_active or public.is_admin());

drop policy if exists "Admins manage pricing" on public.pricing_items;
create policy "Admins manage pricing"
  on public.pricing_items for all
  using (public.is_admin()) with check (public.is_admin());

insert into public.pricing_items (category, name, price, unit, note, billing_key, sort_order) values
  ('daycare',      '시간제 데이케어',        4000,  '1시간', '돌봄',          null,          10),
  ('daycare',      '종일 데이케어',          35000, '1일',   '산책 1회 포함 · 09:00~18:00', 'daycare_day', 20),
  ('daycare_pass', '종일 데이케어 8회권',    260000,'8회',   '종일 이용',     null,          10),
  ('daycare_pass', '종일 데이케어 12회권',   380000,'12회',  '종일 이용',     null,          20),
  ('daycare_pass', '종일 데이케어 16회권',   490000,'16회',  '종일 이용',     null,          30),
  ('daycare_pass', '종일 데이케어 20회권',   600000,'20회',  '종일 이용',     null,          40),
  ('hotel',        '호텔 1박',              45000, '1박',   '산책 1회 포함',  'hotel_night', 10),
  ('hotel',        '추가 산책',              5000,  '1회',   '호텔·데이케어 공통', null,       20),
  ('spa',          '스파 (3kg 이하)',        10000, '1회',   '별도 요금',      null,          10),
  ('spa',          '스파 (3kg 초과 ~ 5kg 이하)', 15000, '1회', '별도 요금',    null,          20)
on conflict do nothing;

-- ── 예약 결제 기준가를 pricing_items 에서 읽도록 ─────────
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
  v_resv    public.reservations;
  v_setting public.service_settings;
  v_units   int;
  v_price   int;
  v_amount  int;
  v_rate    numeric;
  v_points  int := greatest(0, coalesce(p_points_used, 0));
  v_payable int;
  v_balance int;
  v_payment public.payments;
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  select * into v_resv
    from public.reservations
    where id = p_reservation_id and user_id = auth.uid();
  if v_resv.id is null then
    raise exception '본인의 예약만 결제할 수 있습니다.';
  end if;

  if v_resv.deposit_paid or exists (
    select 1 from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id and status = 'paid'
  ) then
    raise exception '이미 결제가 완료된 예약입니다.';
  end if;

  delete from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id
      and user_id = auth.uid() and status = 'ready';

  select points into v_balance from public.profiles where id = auth.uid();
  if v_points > coalesce(v_balance, 0) then
    raise exception '보유 포인트(%P)보다 많이 사용할 수 없습니다.', coalesce(v_balance, 0);
  end if;

  select * into v_setting from public.service_settings where type = v_resv.type;
  v_rate := coalesce(v_setting.deposit_rate, 1);

  select price into v_price
    from public.pricing_items
    where billing_key = case when v_resv.type = 'hotel' then 'hotel_night' else 'daycare_day' end
      and is_active;
  if v_price is null then
    v_price := coalesce(v_setting.price, 0);
  end if;

  if v_resv.type = 'hotel' then
    v_units := greatest(1, (v_resv.end_date - v_resv.start_date));
  else
    v_units := 1;
  end if;

  v_amount := greatest(0, round(v_price * v_units * v_rate))::int;
  if v_amount = 0 then
    raise exception '결제 금액이 0원입니다. 관리자에게 문의해주세요.';
  end if;

  if v_points > v_amount then
    v_points := v_amount;
  end if;
  v_payable := v_amount - v_points;

  insert into public.payments (user_id, target_type, target_id, amount, status, points_used)
  values (auth.uid(), 'reservation', p_reservation_id, v_payable, 'ready', v_points)
  returning * into v_payment;

  if v_payable = 0 then
    perform public.consume_points_for_payment(v_payment.id);
    update public.payments
      set status = 'paid', method = '포인트', paid_at = now()
      where id = v_payment.id
      returning * into v_payment;
    update public.reservations
      set deposit_paid = true, status = 'confirmed'
      where id = p_reservation_id and status in ('pending', 'confirmed');
    perform public.award_purchase_points('reservation', p_reservation_id);
  end if;

  return v_payment;
end;
$$;

grant execute on function public.create_reservation_payment(uuid, int) to authenticated;

-- ── 예약 시 약관 동의 ──────────────────────────────────
alter table public.reservations add column if not exists terms_agreed_at timestamptz;

drop function if exists public.book_reservation(uuid, text, date, date, text, time, time);

create or replace function public.book_reservation(
  p_pet_id uuid,
  p_type text,
  p_start_date date,
  p_end_date date,
  p_memo text default null,
  p_start_time time default '09:00',
  p_end_time time default '21:00',
  p_terms_agreed boolean default false
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
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  if not p_terms_agreed then
    raise exception '이용약관 및 개인정보 동의가 필요합니다.';
  end if;

  if p_end_date < p_start_date then
    raise exception '종료일은 시작일 이후여야 합니다.';
  end if;

  if p_type = 'daycare' and p_end_date <> p_start_date then
    raise exception '데이케어는 당일 이용만 가능합니다.';
  end if;

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
      where type = p_type
        and status in ('pending', 'confirmed')
        and v_date between start_date and end_date;

    if v_booked >= v_capacity then
      raise exception '%에 정원이 마감되었습니다.', to_char(v_date, 'YYYY-MM-DD');
    end if;
  end loop;

  insert into public.reservations (user_id, pet_id, type, start_date, end_date, start_time, end_time, status, memo, terms_agreed_at)
  values (auth.uid(), p_pet_id, p_type, p_start_date, p_end_date, p_start_time, p_end_time, 'pending', p_memo, now())
  returning * into v_reservation;

  return v_reservation;
end;
$$;

grant execute on function public.book_reservation(uuid, text, date, date, text, time, time, boolean) to authenticated;
