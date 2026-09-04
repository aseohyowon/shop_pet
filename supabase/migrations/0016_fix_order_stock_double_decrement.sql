-- ⑯ [버그 수정] create_order 가 주문 생성 시점에 재고를 차감하고 있었음.
-- finalize_order(결제 승인 시)에서도 차감하므로 재고가 2배로 빠지고,
-- 결제하지 않고 이탈하면 재고가 묶인 채로 남는 문제가 있었다. (0007 의도 복원)
-- => create_order 는 재고를 "확인만" 하고, 차감은 finalize_order 에서만 한다.

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

    -- 재고 차감은 하지 않음 (finalize_order 에서 결제 승인 후 차감)

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

grant execute on function public.create_order(jsonb, jsonb) to authenticated;
