-- ⑭ 예약 서비스 가격 (호텔 1박 요금 / 데이케어 1일 요금) — 관리자가 설정
-- Supabase 대시보드 SQL Editor 또는 `npm run db:migrate` 로 실행하세요.

alter table public.service_settings add column if not exists price int not null default 0;
-- 결제 시 받을 비율 (1.0 = 전액, 0.3 = 예약금 30%)
alter table public.service_settings add column if not exists deposit_rate numeric(3, 2) not null default 1.0;

update public.service_settings set price = 50000 where type = 'hotel' and price = 0;
update public.service_settings set price = 30000 where type = 'daycare' and price = 0;

-- 예약금 결제 금액을 서버에서 산정 (클라이언트가 금액을 임의로 넘기지 못하게)
drop function if exists public.create_reservation_payment(uuid, int);

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

  select * into v_setting from public.service_settings where type = v_resv.type;
  if v_setting.type is null then
    raise exception '서비스 요금 정보가 없습니다.';
  end if;

  -- 호텔: 박 수 = 종료일 - 시작일, 데이케어: 1일
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
