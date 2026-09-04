-- ⑬ 예방접종 현황(1~5) + 이용 규정 동의 + 데이케어 당일 예약 제한
-- Supabase 대시보드 SQL Editor 또는 `npm run db:migrate` 로 실행하세요.

-- 반려동물 예방접종 현황
--   {"1":"member","2":"admin", ...}  key = 백신 1~5,  value = 'member'(회원 확인) | 'admin'(관리자 확인)
alter table public.pets add column if not exists vaccinations jsonb not null default '{}'::jsonb;

-- 반려동물 등록 시 이용 규정 동의 시각
alter table public.pets add column if not exists rules_agreed_at timestamptz;

-- 관리자가 특정 반려동물의 백신 상태를 변경 (pets 테이블에 관리자 UPDATE 정책이 없으므로 security definer 함수로)
create or replace function public.set_vaccine_status(p_pet_id uuid, p_no int, p_status text)
returns public.pets
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pet public.pets;
begin
  if not public.is_admin() then
    raise exception '관리자만 사용할 수 있습니다.';
  end if;
  if p_no < 1 or p_no > 5 then
    raise exception '백신 번호는 1~5 입니다.';
  end if;
  if p_status not in ('member', 'admin', 'none') then
    raise exception '상태값이 올바르지 않습니다.';
  end if;

  if p_status = 'none' then
    update public.pets set vaccinations = vaccinations - p_no::text
      where id = p_pet_id returning * into v_pet;
  else
    update public.pets
      set vaccinations = jsonb_set(vaccinations, array[p_no::text], to_jsonb(p_status), true)
      where id = p_pet_id returning * into v_pet;
  end if;

  if v_pet.id is null then
    raise exception '반려동물을 찾을 수 없습니다.';
  end if;
  return v_pet;
end;
$$;

grant execute on function public.set_vaccine_status(uuid, int, text) to authenticated;

-- 데이케어(원데이 케어)는 당일 이용만 가능하도록 book_reservation 에 제약 추가
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
