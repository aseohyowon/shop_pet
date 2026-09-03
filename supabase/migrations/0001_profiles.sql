-- ② 회원 인증 단계: profiles 테이블 (auth.users 확장)
-- Supabase 대시보드 SQL Editor에서 그대로 실행하세요.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  name text,
  phone text,
  role text not null default 'customer' check (role in ('customer', 'admin')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- 본인 프로필 조회
create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

-- 본인 프로필 수정
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- 관리자는 전체 프로필 조회 가능
-- (본인 행은 위 정책으로 항상 보이므로 재귀 없이 안전하게 동작함)
create policy "Admins can view all profiles"
  on public.profiles for select
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- 회원가입 시 auth.users에 새 행이 생기면 profiles에도 자동으로 행을 생성
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, phone, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'name',
    new.raw_user_meta_data ->> 'phone',
    'customer'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 관리자 계정 만들기:
-- 1) Supabase 대시보드 > Authentication > Add user 로 이메일/비밀번호 계정 생성
-- 2) 아래 SQL로 해당 계정의 role을 admin으로 변경 (이메일만 바꿔서 실행)
-- update public.profiles set role = 'admin' where email = 'admin@example.com';
