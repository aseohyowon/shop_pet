-- ㉓ 배송비
--   기본 배송비 + 무료배송 기준(상품 합계) — 관리자가 site_settings 에서 설정
--   orders.total_amount = 상품합계 + 배송비 (배송비는 shipping_fee 로도 따로 보관)

alter table public.orders add column if not exists shipping_fee int not null default 0;

insert into public.site_settings (key, value) values
  ('shipping_fee', '3000'),
  ('free_shipping_threshold', '30000')
on conflict (key) do nothing;

drop function if exists public.create_order(jsonb, jsonb, int);

create function public.create_order(
  p_items jsonb,
  p_shipping jsonb default '{}'::jsonb,
  p_points_used int default 0
)
returns table (
  order_id uuid,
  payment_id uuid,
  total_amount int,
  shipping_fee int,
  payable_amount int,
  fully_paid boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item      jsonb;
  v_product   public.products;
  v_qty       int;
  v_goods     int := 0;
  v_fee       int := 0;
  v_threshold int;
  v_grand     int;
  v_points    int := greatest(0, coalesce(p_points_used, 0));
  v_payable   int;
  v_balance   int;
  v_order_id  uuid;
  v_payment_id uuid;
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception '주문할 상품이 없습니다.';
  end if;

  select points into v_balance from public.profiles where id = auth.uid();

  -- 이전 미결제(pending) 주문 정리
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

    v_goods := v_goods + v_product.price * v_qty;
  end loop;

  -- 배송비 산정 (상품 합계 기준)
  v_fee := coalesce((select value from public.site_settings where key = 'shipping_fee'), '0')::int;
  v_threshold := coalesce((select value from public.site_settings where key = 'free_shipping_threshold'), '0')::int;
  if v_threshold > 0 and v_goods >= v_threshold then
    v_fee := 0;
  end if;

  v_grand := v_goods + v_fee;

  if v_points > coalesce(v_balance, 0) then
    raise exception '보유 포인트(%P)보다 많이 사용할 수 없습니다.', coalesce(v_balance, 0);
  end if;
  if v_points > v_grand then
    v_points := v_grand;
  end if;
  v_payable := v_grand - v_points;

  update public.orders
    set total_amount = v_grand,
        shipping_fee = v_fee,
        points_used = v_points
    where id = v_order_id;

  insert into public.payments (user_id, target_type, target_id, amount, status, points_used)
  values (auth.uid(), 'order', v_order_id, v_payable, 'ready', v_points)
  returning id into v_payment_id;

  if v_payable = 0 then
    perform public.consume_points_for_payment(v_payment_id);
    update public.payments
      set status = 'paid', method = '포인트', paid_at = now()
      where id = v_payment_id;
    perform public.finalize_order(v_order_id);
    perform public.award_purchase_points('order', v_order_id);
    return query select v_order_id, v_payment_id, v_grand, v_fee, 0, true;
  else
    return query select v_order_id, v_payment_id, v_grand, v_fee, v_payable, false;
  end if;
end;
$$;

grant execute on function public.create_order(jsonb, jsonb, int) to authenticated;
