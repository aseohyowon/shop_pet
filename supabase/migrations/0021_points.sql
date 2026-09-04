-- ㉑ 포인트 제도
--   - 회원가입 시 1,000P 지급 (기존 회원도 소급 지급)
--   - 결제(쇼핑몰 주문 / 예약) 시 포인트로 차감, 전액 사용 가능
--   - 구매 적립: 실제 카드 결제 금액의 N% (관리자가 site_settings.point_earn_rate 로 설정)

-- ── 스키마 ─────────────────────────────────────────────
alter table public.profiles add column if not exists points int not null default 0;

alter table public.orders   add column if not exists points_used int not null default 0;
alter table public.payments add column if not exists points_used int not null default 0;

-- 적립률(%) 기본 0
insert into public.site_settings (key, value) values ('point_earn_rate', '0')
  on conflict (key) do nothing;

-- 포인트 원장
create table if not exists public.point_transactions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  amount       int  not null,            -- +적립 / -사용
  balance_after int not null,
  reason       text not null,            -- signup | earn | use | cancel | admin
  target_type  text,                     -- order | reservation | null
  target_id    uuid,
  memo         text,
  created_at   timestamptz not null default now()
);
create index if not exists point_transactions_user_idx
  on public.point_transactions (user_id, created_at desc);

alter table public.point_transactions enable row level security;

drop policy if exists "own point tx read" on public.point_transactions;
create policy "own point tx read"
  on public.point_transactions for select using (auth.uid() = user_id);

drop policy if exists "admin point tx read" on public.point_transactions;
create policy "admin point tx read"
  on public.point_transactions for select using (public.is_admin());
-- 쓰기는 security definer 함수로만

-- ── 내부 헬퍼: 포인트 이동 ──────────────────────────────
create or replace function public.apply_points(
  p_user uuid,
  p_amount int,
  p_reason text,
  p_target_type text default null,
  p_target_id uuid default null,
  p_memo text default null
)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance int;
begin
  if p_amount = 0 then
    return (select points from public.profiles where id = p_user);
  end if;

  update public.profiles
    set points = points + p_amount
    where id = p_user
    returning points into v_balance;

  if v_balance is null then
    raise exception '회원 정보를 찾을 수 없습니다.';
  end if;
  if v_balance < 0 then
    raise exception '보유 포인트가 부족합니다.';
  end if;

  insert into public.point_transactions
    (user_id, amount, balance_after, reason, target_type, target_id, memo)
  values
    (p_user, p_amount, v_balance, p_reason, p_target_type, p_target_id, p_memo);

  return v_balance;
end;
$$;

-- ── 결제 시 포인트 차감 (payments.points_used 만큼) ──────
create or replace function public.consume_points_for_payment(p_payment_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pay public.payments;
  v_bal int;
  v_use int;
begin
  select * into v_pay from public.payments where id = p_payment_id;
  if v_pay.id is null or v_pay.points_used <= 0 then
    return;
  end if;

  -- 이미 차감했으면 skip
  if exists (
    select 1 from public.point_transactions
    where target_type = v_pay.target_type and target_id = v_pay.target_id and reason = 'use'
  ) then
    return;
  end if;

  select points into v_bal from public.profiles where id = v_pay.user_id;
  v_use := least(v_pay.points_used, greatest(v_bal, 0));
  if v_use > 0 then
    perform public.apply_points(
      v_pay.user_id, -v_use, 'use', v_pay.target_type, v_pay.target_id, '결제 시 포인트 사용'
    );
  end if;
end;
$$;

-- ── 구매 적립 ───────────────────────────────────────────
create or replace function public.award_purchase_points(p_target_type text, p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pay  public.payments;
  v_rate numeric;
  v_earn int;
begin
  select * into v_pay
    from public.payments
    where target_type = p_target_type and target_id = p_target_id and status = 'paid'
    order by created_at desc
    limit 1;
  if v_pay.id is null or v_pay.amount <= 0 then
    return;
  end if;

  if exists (
    select 1 from public.point_transactions
    where target_type = p_target_type and target_id = p_target_id and reason = 'earn'
  ) then
    return;
  end if;

  v_rate := coalesce((select value from public.site_settings where key = 'point_earn_rate'), '0')::numeric;
  v_earn := floor(v_pay.amount * v_rate / 100.0)::int;
  if v_earn > 0 then
    perform public.apply_points(
      v_pay.user_id, v_earn, 'earn', p_target_type, p_target_id, '구매 적립'
    );
  end if;
end;
$$;

-- ── 취소 시: 사용 포인트 복원 + 적립 포인트 회수 ─────────
create or replace function public.revert_purchase_points(p_target_type text, p_target_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user   uuid;
  v_used   int;
  v_earned int;
  v_bal    int;
begin
  select user_id into v_user
    from public.payments
    where target_type = p_target_type and target_id = p_target_id
    order by created_at desc
    limit 1;
  if v_user is null then
    return;
  end if;

  -- 이미 되돌렸으면 skip
  if exists (
    select 1 from public.point_transactions
    where target_type = p_target_type and target_id = p_target_id and reason = 'cancel'
  ) then
    return;
  end if;

  select coalesce(sum(-amount), 0) into v_used
    from public.point_transactions
    where target_type = p_target_type and target_id = p_target_id and reason = 'use';

  select coalesce(sum(amount), 0) into v_earned
    from public.point_transactions
    where target_type = p_target_type and target_id = p_target_id and reason = 'earn';

  if v_used > 0 then
    perform public.apply_points(
      v_user, v_used, 'cancel', p_target_type, p_target_id, '취소 - 사용 포인트 복원'
    );
  end if;

  if v_earned > 0 then
    select points into v_bal from public.profiles where id = v_user;
    perform public.apply_points(
      v_user, -least(v_earned, greatest(v_bal, 0)), 'cancel', p_target_type, p_target_id, '취소 - 적립 포인트 회수'
    );
  end if;
end;
$$;

-- ── 관리자 수동 지급/차감 ───────────────────────────────
create or replace function public.admin_adjust_points(p_user uuid, p_amount int, p_memo text default null)
returns int
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception '관리자만 사용할 수 있습니다.';
  end if;
  if p_amount = 0 then
    raise exception '변경할 포인트를 입력해주세요.';
  end if;
  return public.apply_points(p_user, p_amount, 'admin', null, null, coalesce(p_memo, '관리자 조정'));
end;
$$;

grant execute on function public.apply_points(uuid, int, text, text, uuid, text) to service_role;
grant execute on function public.consume_points_for_payment(uuid) to service_role;
grant execute on function public.award_purchase_points(text, uuid) to service_role;
grant execute on function public.revert_purchase_points(text, uuid) to service_role;
grant execute on function public.admin_adjust_points(uuid, int, text) to authenticated;

-- ── 회원가입 트리거: 프로필 생성 + 1,000P 지급 ──────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, phone, postcode, address, address_detail, role, points)
  values (
    new.id,
    new.email,
    coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'nickname',
      new.raw_user_meta_data ->> 'preferred_username',
      new.raw_user_meta_data ->> 'user_name'
    ),
    new.raw_user_meta_data ->> 'phone',
    new.raw_user_meta_data ->> 'postcode',
    new.raw_user_meta_data ->> 'address',
    new.raw_user_meta_data ->> 'address_detail',
    'customer',
    0
  );

  perform public.apply_points(new.id, 1000, 'signup', null, null, '회원가입 축하 포인트');
  return new;
end;
$$;

-- ── 기존 회원 소급 지급 (포인트 이력이 없는 고객만) ─────
do $$
declare
  r record;
begin
  for r in
    select p.id from public.profiles p
    where p.role = 'customer'
      and not exists (select 1 from public.point_transactions t where t.user_id = p.id)
  loop
    perform public.apply_points(r.id, 1000, 'signup', null, null, '기존 회원 소급 지급');
  end loop;
end $$;

-- ── create_order: 포인트 사용 반영 ──────────────────────
drop function if exists public.create_order(jsonb, jsonb);

create or replace function public.create_order(
  p_items jsonb,
  p_shipping jsonb default '{}'::jsonb,
  p_points_used int default 0
)
returns table (order_id uuid, payment_id uuid, total_amount int, payable_amount int, fully_paid boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item     jsonb;
  v_product  public.products;
  v_qty      int;
  v_total    int := 0;
  v_points   int := greatest(0, coalesce(p_points_used, 0));
  v_payable  int;
  v_balance  int;
  v_order_id uuid;
  v_payment_id uuid;
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception '주문할 상품이 없습니다.';
  end if;

  select points into v_balance from public.profiles where id = auth.uid();
  if v_points > coalesce(v_balance, 0) then
    raise exception '보유 포인트(%P)보다 많이 사용할 수 없습니다.', coalesce(v_balance, 0);
  end if;

  -- 이전 미결제(pending) 주문 + ready 결제 정리 (포인트는 아직 차감 전이므로 복원 불필요)
  delete from public.payments
    where user_id = auth.uid()
      and target_type = 'order'
      and status = 'ready'
      and target_id in (select id from public.orders where user_id = auth.uid() and status = 'pending');
  delete from public.orders where user_id = auth.uid() and status = 'pending';

  insert into public.orders (
    user_id, status, total_amount, points_used,
    recipient_name, recipient_phone, shipping_address, shipping_memo
  )
  values (
    auth.uid(), 'pending', 0, v_points,
    nullif(p_shipping ->> 'recipient_name', ''),
    nullif(p_shipping ->> 'recipient_phone', ''),
    nullif(p_shipping ->> 'shipping_address', ''),
    nullif(p_shipping ->> 'shipping_memo', '')
  )
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::int;

    select * into v_product from public.products where id = (v_item ->> 'product_id')::uuid;

    if v_product.id is null or not v_product.is_active then
      raise exception '판매 중이 아닌 상품이 포함되어 있습니다.';
    end if;
    if v_product.stock < v_qty then
      raise exception '%의 재고가 부족합니다.', v_product.name;
    end if;

    insert into public.order_items (order_id, product_id, quantity, price_at_order)
    values (v_order_id, v_product.id, v_qty, v_product.price);

    v_total := v_total + v_product.price * v_qty;
  end loop;

  if v_points > v_total then
    v_points := v_total;
  end if;
  v_payable := v_total - v_points;

  update public.orders set total_amount = v_total, points_used = v_points where id = v_order_id;

  insert into public.payments (user_id, target_type, target_id, amount, status, points_used)
  values (auth.uid(), 'order', v_order_id, v_payable, 'ready', v_points)
  returning id into v_payment_id;

  if v_payable = 0 then
    -- 포인트로 전액 결제: 즉시 확정
    perform public.consume_points_for_payment(v_payment_id);
    update public.payments
      set status = 'paid', method = '포인트', paid_at = now()
      where id = v_payment_id;
    perform public.finalize_order(v_order_id);
    perform public.award_purchase_points('order', v_order_id);
    return query select v_order_id, v_payment_id, v_total, 0, true;
  else
    return query select v_order_id, v_payment_id, v_total, v_payable, false;
  end if;
end;
$$;

grant execute on function public.create_order(jsonb, jsonb, int) to authenticated;

-- ── create_reservation_payment: 포인트 사용 반영 ────────
drop function if exists public.create_reservation_payment(uuid);

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
  v_amount  int;
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

  -- 진행 중(ready)인 결제가 있으면 정리하고 다시 만든다 (포인트 사용액이 바뀔 수 있으므로)
  delete from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id
      and user_id = auth.uid() and status = 'ready';

  select points into v_balance from public.profiles where id = auth.uid();
  if v_points > coalesce(v_balance, 0) then
    raise exception '보유 포인트(%P)보다 많이 사용할 수 없습니다.', coalesce(v_balance, 0);
  end if;

  select * into v_setting from public.service_settings where type = v_resv.type;
  if v_setting.type is null then
    raise exception '서비스 요금 정보가 없습니다.';
  end if;

  if v_resv.type = 'hotel' then
    v_units := greatest(1, (v_resv.end_date - v_resv.start_date));
  else
    v_units := 1;
  end if;

  v_amount := greatest(0, round(v_setting.price * v_units * v_setting.deposit_rate))::int;
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
