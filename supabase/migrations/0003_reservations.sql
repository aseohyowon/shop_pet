-- ③ 예약 시스템: 반려동물, 정원 설정, 예약 테이블 + 예약 생성 RPC(동시성/중복예약 방지)

-- 반려동물 정보
create table if not exists public.pets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  breed text,
  age int,
  weight numeric,
  is_vaccinated boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.pets enable row level security;

create policy "Users manage own pets"
  on public.pets for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "Admins view all pets"
  on public.pets for select
  using (public.is_admin());

-- 서비스별 기본 정원 (관리자가 날짜별로 daily_capacity에 예외를 두지 않으면 이 값을 사용)
create table if not exists public.service_settings (
  type text primary key check (type in ('hotel', 'daycare')),
  default_capacity int not null
);

insert into public.service_settings (type, default_capacity) values
  ('hotel', 5),
  ('daycare', 10)
on conflict (type) do nothing;

alter table public.service_settings enable row level security;

create policy "Anyone can read service settings"
  on public.service_settings for select
  using (true);

create policy "Admins manage service settings"
  on public.service_settings for all
  using (public.is_admin())
  with check (public.is_admin());

-- 날짜별 정원 예외 (특정 날짜만 정원을 다르게 설정하고 싶을 때)
create table if not exists public.daily_capacity (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  type text not null check (type in ('hotel', 'daycare')),
  max_capacity int not null,
  unique (date, type)
);

alter table public.daily_capacity enable row level security;

create policy "Anyone can read daily capacity"
  on public.daily_capacity for select
  using (true);

create policy "Admins manage daily capacity"
  on public.daily_capacity for all
  using (public.is_admin())
  with check (public.is_admin());

-- 예약
create table if not exists public.reservations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  pet_id uuid not null references public.pets (id) on delete cascade,
  type text not null check (type in ('hotel', 'daycare')),
  start_date date not null,
  end_date date not null,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'rejected', 'cancelled', 'completed')),
  memo text,
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);

alter table public.reservations enable row level security;

create policy "Users view own reservations"
  on public.reservations for select
  using (user_id = auth.uid());

-- 본인의 승인 대기 중인 예약만 취소 가능 (pending -> cancelled)
create policy "Users cancel own pending reservations"
  on public.reservations for update
  using (user_id = auth.uid() and status = 'pending')
  with check (user_id = auth.uid() and status = 'cancelled');

create policy "Admins manage all reservations"
  on public.reservations for all
  using (public.is_admin())
  with check (public.is_admin());

-- 예약 생성은 이 함수로만 (직접 insert 정책은 두지 않음) : 날짜별 정원을 원자적으로 확인 후 생성
create or replace function public.book_reservation(
  p_pet_id uuid,
  p_type text,
  p_start_date date,
  p_end_date date,
  p_memo text default null
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

  if not exists (select 1 from public.pets where id = p_pet_id and owner_id = auth.uid()) then
    raise exception '본인 소유의 반려동물만 선택할 수 있습니다.';
  end if;

  for v_date in select generate_series(p_start_date, p_end_date, interval '1 day')::date loop
    -- 같은 날짜/서비스 종류에 대한 동시 예약 시도를 직렬화
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

  insert into public.reservations (user_id, pet_id, type, start_date, end_date, status, memo)
  values (auth.uid(), p_pet_id, p_type, p_start_date, p_end_date, 'pending', p_memo)
  returning * into v_reservation;

  return v_reservation;
end;
$$;

grant execute on function public.book_reservation(uuid, text, date, date, text) to authenticated;

-- 달력에 표시할 날짜별 예약 가능 현황 (개인정보 없이 집계값만 반환)
create or replace function public.get_availability(
  p_type text,
  p_start date,
  p_end date
)
returns table (date date, capacity int, booked int, remaining int)
language sql
security definer
set search_path = public
stable
as $$
  select
    d::date as date,
    coalesce(
      (select max_capacity from public.daily_capacity dc where dc.date = d::date and dc.type = p_type),
      (select default_capacity from public.service_settings s where s.type = p_type),
      0
    ) as capacity,
    (
      select count(*)::int from public.reservations r
      where r.type = p_type
        and r.status in ('pending', 'confirmed')
        and d::date between r.start_date and r.end_date
    ) as booked,
    coalesce(
      (select max_capacity from public.daily_capacity dc where dc.date = d::date and dc.type = p_type),
      (select default_capacity from public.service_settings s where s.type = p_type),
      0
    ) - (
      select count(*)::int from public.reservations r
      where r.type = p_type
        and r.status in ('pending', 'confirmed')
        and d::date between r.start_date and r.end_date
    ) as remaining
  from generate_series(p_start, p_end, interval '1 day') as d;
$$;

grant execute on function public.get_availability(text, date, date) to anon, authenticated;
