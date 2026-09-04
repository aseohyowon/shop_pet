-- ⑮ 예약 결제 중복 방지 + 결제 완료 시 자동 확정
-- Supabase 대시보드 SQL Editor 또는 `npm run db:migrate` 로 실행하세요.

-- create_reservation_payment: 이미 결제됐거나 진행 중인 결제가 있으면 새로 만들지 않는다.
create or replace function public.create_reservation_payment(p_reservation_id uuid)
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

  -- 이미 결제 완료
  if v_resv.deposit_paid or exists (
    select 1 from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id and status = 'paid'
  ) then
    raise exception '이미 결제가 완료된 예약입니다.';
  end if;

  -- 진행 중(ready)인 결제가 있으면 그대로 재사용 (결제 화면 재진입 시 중복 생성 방지)
  select * into v_payment
    from public.payments
    where target_type = 'reservation' and target_id = p_reservation_id
      and user_id = auth.uid() and status = 'ready'
    order by created_at desc
    limit 1;
  if v_payment.id is not null then
    return v_payment;
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

  insert into public.payments (user_id, target_type, target_id, amount, status)
  values (auth.uid(), 'reservation', p_reservation_id, v_amount, 'ready')
  returning * into v_payment;

  return v_payment;
end;
$$;

grant execute on function public.create_reservation_payment(uuid) to authenticated;
