-- ㉒ 예약/주문 방어 로직
--   G. 결제 후 재고 부족 → 주문을 'paid' 로 두되 stock_issue 메모를 남겨 관리자에게 노출
--   H. 같은 반려동물의 기간 겹치는 중복 예약 방지

alter table public.orders add column if not exists stock_issue text;

-- ── G. finalize_order: 재고가 모자라도 실패하지 않고 가능한 만큼 차감 + 이슈 기록 ──
create or replace function public.finalize_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item  record;
  v_user  uuid;
  v_take  int;
  v_issue text := null;
begin
  select user_id into v_user from public.orders where id = p_order_id;

  for v_item in
    select oi.product_id, oi.quantity, p.stock, p.name
    from public.order_items oi
    join public.products p on p.id = oi.product_id
    where oi.order_id = p_order_id
    for update of p
  loop
    v_take := least(v_item.quantity, greatest(v_item.stock, 0));
    if v_take > 0 then
      update public.products set stock = stock - v_take where id = v_item.product_id;
    end if;
    if v_take < v_item.quantity then
      v_issue := coalesce(v_issue || ', ', '') || v_item.name || ' ' || (v_item.quantity - v_take) || '개 부족';
    end if;
  end loop;

  update public.orders
    set status = 'paid',
        stock_issue = v_issue
    where id = p_order_id;

  if v_user is not null then
    delete from public.cart_items
      where user_id = v_user
        and product_id in (select product_id from public.order_items where order_id = p_order_id);
  end if;
end;
$$;

grant execute on function public.finalize_order(uuid) to service_role;

-- ── H. book_reservation: 같은 반려동물 기간 겹침 예약 차단 ──
create or replace function public.book_reservation(
  p_pet_id uuid,
  p_type text,
  p_start_date date,
  p_end_date date,
  p_memo text default null,
  p_start_time time default '09:00',
  p_end_time time default '21:00'
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

  -- 같은 반려동물의 기간이 겹치는 예약(진행 중)이 있으면 차단
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

  insert into public.reservations (user_id, pet_id, type, start_date, end_date, start_time, end_time, status, memo)
  values (auth.uid(), p_pet_id, p_type, p_start_date, p_end_date, p_start_time, p_end_time, 'pending', p_memo)
  returning * into v_reservation;

  return v_reservation;
end;
$$;

grant execute on function public.book_reservation(uuid, text, date, date, text, time, time) to authenticated;
