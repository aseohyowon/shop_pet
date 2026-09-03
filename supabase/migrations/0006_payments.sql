-- ⑤ 결제 연동: 주문, 주문상품, 결제 테이블 + 주문 생성/예약금 결제 생성 RPC

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'paid', 'preparing', 'shipping', 'completed', 'cancelled')),
  total_amount int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.orders enable row level security;

create policy "Users view own orders"
  on public.orders for select
  using (user_id = auth.uid());

create policy "Admins manage all orders"
  on public.orders for all
  using (public.is_admin())
  with check (public.is_admin());

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id uuid not null references public.products (id),
  quantity int not null check (quantity > 0),
  price_at_order int not null
);

alter table public.order_items enable row level security;

create policy "Users view own order items"
  on public.order_items for select
  using (exists (select 1 from public.orders o where o.id = order_id and o.user_id = auth.uid()));

create policy "Admins manage all order items"
  on public.order_items for all
  using (public.is_admin())
  with check (public.is_admin());

-- 예약금 결제 여부
alter table public.reservations add column if not exists deposit_paid boolean not null default false;

-- 결제 (예약금 결제 / 상품 결제 공용)
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  target_type text not null check (target_type in ('reservation', 'order')),
  target_id uuid not null,
  amount int not null,
  status text not null default 'ready' check (status in ('ready', 'paid', 'failed', 'cancelled')),
  toss_payment_key text,
  method text,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.payments enable row level security;

create policy "Users view own payments"
  on public.payments for select
  using (user_id = auth.uid());

create policy "Admins view all payments"
  on public.payments for select
  using (public.is_admin());

-- 주문 생성: 재고 확인 + 차감 + 장바구니 비우기 + 결제 레코드 생성을 원자적으로 처리
create or replace function public.create_order(p_items jsonb)
returns table (order_id uuid, payment_id uuid, total_amount int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
  v_product public.products;
  v_qty int;
  v_total int := 0;
  v_order_id uuid;
  v_payment_id uuid;
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception '주문할 상품이 없습니다.';
  end if;

  insert into public.orders (user_id, status, total_amount)
  values (auth.uid(), 'pending', 0)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::int;

    select * into v_product from public.products
      where id = (v_item ->> 'product_id')::uuid
      for update;

    if v_product.id is null or not v_product.is_active then
      raise exception '판매 중이 아닌 상품이 포함되어 있습니다.';
    end if;

    if v_product.stock < v_qty then
      raise exception '%의 재고가 부족합니다.', v_product.name;
    end if;

    update public.products set stock = stock - v_qty where id = v_product.id;

    insert into public.order_items (order_id, product_id, quantity, price_at_order)
    values (v_order_id, v_product.id, v_qty, v_product.price);

    v_total := v_total + v_product.price * v_qty;
  end loop;

  update public.orders set total_amount = v_total where id = v_order_id;

  delete from public.cart_items where user_id = auth.uid();

  insert into public.payments (user_id, target_type, target_id, amount, status)
  values (auth.uid(), 'order', v_order_id, v_total, 'ready')
  returning id into v_payment_id;

  return query select v_order_id, v_payment_id, v_total;
end;
$$;

grant execute on function public.create_order(jsonb) to authenticated;

-- 예약금 결제 레코드 생성
create or replace function public.create_reservation_payment(p_reservation_id uuid, p_amount int default 30000)
returns public.payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_payment public.payments;
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  if not exists (select 1 from public.reservations where id = p_reservation_id and user_id = auth.uid()) then
    raise exception '본인의 예약만 결제할 수 있습니다.';
  end if;

  insert into public.payments (user_id, target_type, target_id, amount, status)
  values (auth.uid(), 'reservation', p_reservation_id, p_amount, 'ready')
  returning * into v_payment;

  return v_payment;
end;
$$;

grant execute on function public.create_reservation_payment(uuid, int) to authenticated;
