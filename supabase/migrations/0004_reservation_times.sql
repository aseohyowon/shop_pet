-- 예약에 이용 시간(09:00 ~ 21:00) 추가

alter table public.reservations
  add column if not exists start_time time not null default '09:00',
  add column if not exists end_time time not null default '21:00';

alter table public.reservations
  add constraint reservations_start_time_range check (start_time >= time '09:00' and start_time <= time '21:00'),
  add constraint reservations_end_time_range check (end_time >= time '09:00' and end_time <= time '21:00');

-- book_reservation()에 시간 파라미터 추가 (기존 5개 인자 버전은 제거하고 교체)
drop function if exists public.book_reservation(uuid, text, date, date, text);

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
