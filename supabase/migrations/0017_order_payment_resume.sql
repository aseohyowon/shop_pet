-- ⑰ 결제 실패/이탈 대응
--   (A) create_order 가 주문 생성 시 장바구니를 비워서, 결제 실패 시 장바구니가 사라지는 문제
--       → 장바구니 비우기를 finalize_order(결제 승인 후)로 이동
--   (B) 결제 안 한 pending 주문이 계속 쌓이는 문제
--       → create_order 시작 시 이 사용자의 이전 미결제 주문을 정리

create or replace function public.create_order(p_items jsonb, p_shipping jsonb default '{}'::jsonb)
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

  -- (B) 이 사용자의 미결제(pending) 주문 + 관련 ready 결제 정리 → 중복 누적 방지
  delete from public.payments
    where user_id = auth.uid()
      and target_type = 'order'
      and status = 'ready'
      and target_id in (select id from public.orders where user_id = auth.uid() and status = 'pending');
  delete from public.orders where user_id = auth.uid() and status = 'pending'; -- order_items 는 cascade

  insert into public.orders (
    user_id, status, total_amount,
    recipient_name, recipient_phone, shipping_address, shipping_memo
  )
  values (
    auth.uid(), 'pending', 0,
    nullif(p_shipping ->> 'recipient_name', ''),
    nullif(p_shipping ->> 'recipient_phone', ''),
    nullif(p_shipping ->> 'shipping_address', ''),
    nullif(p_shipping ->> 'shipping_memo', '')
  )
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::int;

    select * into v_product from public.products
      where id = (v_item ->> 'product_id')::uuid;

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

  update public.orders set total_amount = v_total where id = v_order_id;

  -- (A) 장바구니는 여기서 비우지 않는다. finalize_order(결제 승인) 에서 비운다.

  insert into public.payments (user_id, target_type, target_id, amount, status)
  values (auth.uid(), 'order', v_order_id, v_total, 'ready')
  returning id into v_payment_id;

  return query select v_order_id, v_payment_id, v_total;
end;
$$;

grant execute on function public.create_order(jsonb, jsonb) to authenticated;


-- 결제 승인 후: 재고 차감 + 주문 'paid' + 장바구니 비우기
create or replace function public.finalize_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
  v_user uuid;
begin
  select user_id into v_user from public.orders where id = p_order_id;

  for v_item in
    select oi.product_id, oi.quantity, p.stock, p.name
    from public.order_items oi
    join public.products p on p.id = oi.product_id
    where oi.order_id = p_order_id
    for update of p
  loop
    if v_item.stock < v_item.quantity then
      raise exception '%의 재고가 부족합니다.', v_item.name;
    end if;

    update public.products set stock = stock - v_item.quantity where id = v_item.product_id;
  end loop;

  update public.orders set status = 'paid' where id = p_order_id;

  -- 결제 완료된 주문의 상품을 장바구니에서 제거 (남아있다면)
  if v_user is not null then
    delete from public.cart_items
      where user_id = v_user
        and product_id in (select product_id from public.order_items where order_id = p_order_id);
  end if;
end;
$$;

grant execute on function public.finalize_order(uuid) to service_role;
