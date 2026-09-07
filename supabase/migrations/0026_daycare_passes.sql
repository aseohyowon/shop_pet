-- ㉖ 데이케어 정기권 (온라인 구매 / 관리자 현장결제 등록 / 예약 시 회차 차감)

-- 결제 대상에 'pass' 추가
alter table public.payments drop constraint if exists payments_target_type_check;
alter table public.payments add constraint payments_target_type_check
  check (target_type in ('reservation', 'order', 'pass'));

-- ── 정기권 ─────────────────────────────────────────────
create table if not exists public.daycare_passes (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users (id) on delete cascade,
  pricing_item_id uuid references public.pricing_items (id),
  name            text not null,
  total_count     int  not null check (total_count > 0),
  used_count      int  not null default 0 check (used_count >= 0),
  status          text not null default 'pending' check (status in ('pending', 'active', 'void')),
  source          text not null check (source in ('online', 'admin')),
  memo            text,
  payment_id      uuid references public.payments (id),
  created_by      uuid,
  created_at      timestamptz not null default now()
);
create index if not exists daycare_passes_user_idx on public.daycare_passes (user_id, status);

alter table public.daycare_passes enable row level security;
drop policy if exists "own passes read" on public.daycare_passes;
create policy "own passes read" on public.daycare_passes for select using (auth.uid() = user_id);
drop policy if exists "admin passes read" on public.daycare_passes;
create policy "admin passes read" on public.daycare_passes for select using (public.is_admin());

-- ── 정기권 사용 이력 ───────────────────────────────────
create table if not exists public.daycare_pass_usages (
  id             uuid primary key default gen_random_uuid(),
  pass_id        uuid not null references public.daycare_passes (id) on delete cascade,
  reservation_id uuid not null references public.reservations (id) on delete cascade,
  used_at        timestamptz not null default now(),
  reverted_at    timestamptz,
  unique (reservation_id)
);
alter table public.daycare_pass_usages enable row level security;
drop policy if exists "own pass usages read" on public.daycare_pass_usages;
create policy "own pass usages read" on public.daycare_pass_usages for select
  using (exists (select 1 from public.daycare_passes p where p.id = pass_id and p.user_id = auth.uid()));
drop policy if exists "admin pass usages read" on public.daycare_pass_usages;
create policy "admin pass usages read" on public.daycare_pass_usages for select using (public.is_admin());

alter table public.reservations add column if not exists daycare_pass_id uuid references public.daycare_passes (id);

-- 정기권 회차 수를 unit('8회')/name 에서 추출
create or replace function public.pass_count_of(p_unit text, p_name text)
returns int
language sql
immutable
as $$
  select coalesce(
    nullif(regexp_replace(coalesce(p_unit, ''), '[^0-9]', '', 'g'), '')::int,
    nullif(regexp_replace(coalesce(p_name, ''), '[^0-9]', '', 'g'), '')::int
  )
$$;

-- ── 온라인 구매: 결제 레코드 생성 ──────────────────────
create or replace function public.create_pass_payment(p_pricing_item_id uuid, p_points_used int default 0)
returns table (pass_id uuid, payment_id uuid, amount int, payable_amount int, fully_paid boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item    public.pricing_items;
  v_count   int;
  v_points  int := greatest(0, coalesce(p_points_used, 0));
  v_payable int;
  v_balance int;
  v_pass_id uuid;
  v_payment_id uuid;
begin
  if auth.uid() is null then raise exception '로그인이 필요합니다.'; end if;

  select * into v_item from public.pricing_items where id = p_pricing_item_id and is_active;
  if v_item.id is null or v_item.category <> 'daycare_pass' then
    raise exception '구매할 수 없는 상품입니다.';
  end if;

  v_count := public.pass_count_of(v_item.unit, v_item.name);
  if v_count is null or v_count <= 0 then
    raise exception '정기권 회차 정보를 확인할 수 없습니다.';
  end if;

  select points into v_balance from public.profiles where id = auth.uid();
  if v_points > coalesce(v_balance, 0) then
    raise exception '보유 포인트(%P)보다 많이 사용할 수 없습니다.', coalesce(v_balance, 0);
  end if;
  if v_points > v_item.price then v_points := v_item.price; end if;
  v_payable := v_item.price - v_points;

  -- 이전 미결제 정기권 구매 정리
  delete from public.payments
    where user_id = auth.uid() and target_type = 'pass' and status = 'ready'
      and target_id in (select id from public.daycare_passes where user_id = auth.uid() and status = 'pending');
  delete from public.daycare_passes where user_id = auth.uid() and status = 'pending';

  insert into public.daycare_passes (user_id, pricing_item_id, name, total_count, status, source)
  values (auth.uid(), v_item.id, v_item.name, v_count, 'pending', 'online')
  returning id into v_pass_id;

  insert into public.payments (user_id, target_type, target_id, amount, status, points_used)
  values (auth.uid(), 'pass', v_pass_id, v_payable, 'ready', v_points)
  returning id into v_payment_id;

  update public.daycare_passes set payment_id = v_payment_id where id = v_pass_id;

  if v_payable = 0 then
    perform public.consume_points_for_payment(v_payment_id);
    update public.payments set status = 'paid', method = '포인트', paid_at = now() where id = v_payment_id;
    update public.daycare_passes set status = 'active' where id = v_pass_id;
    perform public.award_purchase_points('pass', v_pass_id);
    return query select v_pass_id, v_payment_id, v_item.price, 0, true;
  else
    return query select v_pass_id, v_payment_id, v_item.price, v_payable, false;
  end if;
end;
$$;
grant execute on function public.create_pass_payment(uuid, int) to authenticated;

-- ── 결제 승인 후 활성화 ────────────────────────────────
create or replace function public.activate_pass(p_pass_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.daycare_passes set status = 'active' where id = p_pass_id and status = 'pending';
end;
$$;
grant execute on function public.activate_pass(uuid) to service_role;

-- ── 예약에 정기권 1회 차감 ─────────────────────────────
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

-- ── 취소 시 정기권 회차 복원 ───────────────────────────
create or replace function public.restore_pass_for_reservation(p_reservation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_usage public.daycare_pass_usages;
begin
  select * into v_usage from public.daycare_pass_usages where reservation_id = p_reservation_id and reverted_at is null;
  if v_usage.id is null then return; end if;
  update public.daycare_passes set used_count = greatest(0, used_count - 1) where id = v_usage.pass_id;
  update public.daycare_pass_usages set reverted_at = now() where id = v_usage.id;
end;
$$;
grant execute on function public.restore_pass_for_reservation(uuid) to service_role;

-- ── 관리자: 현장결제 정기권 지급 ───────────────────────
create or replace function public.admin_grant_pass(p_user uuid, p_pricing_item_id uuid, p_memo text default null)
returns public.daycare_passes
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item  public.pricing_items;
  v_count int;
  v_pass  public.daycare_passes;
begin
  if not public.is_admin() then raise exception '관리자만 사용할 수 있습니다.'; end if;
  select * into v_item from public.pricing_items where id = p_pricing_item_id;
  if v_item.id is null or v_item.category <> 'daycare_pass' then raise exception '정기권 상품이 아닙니다.'; end if;
  v_count := public.pass_count_of(v_item.unit, v_item.name);
  if v_count is null or v_count <= 0 then raise exception '정기권 회차 정보를 확인할 수 없습니다.'; end if;

  insert into public.daycare_passes (user_id, pricing_item_id, name, total_count, status, source, memo, created_by)
  values (p_user, v_item.id, v_item.name, v_count, 'active', 'admin', p_memo, auth.uid())
  returning * into v_pass;
  return v_pass;
end;
$$;
grant execute on function public.admin_grant_pass(uuid, uuid, text) to authenticated;

-- ── 관리자: 정기권 무효화 ──────────────────────────────
create or replace function public.admin_void_pass(p_pass_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception '관리자만 사용할 수 있습니다.'; end if;
  update public.daycare_passes set status = 'void' where id = p_pass_id;
end;
$$;
grant execute on function public.admin_void_pass(uuid) to authenticated;
