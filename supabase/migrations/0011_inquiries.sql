-- ⑪ 1:1 문의 (홈 문의하기 폼 / 고객센터)
-- Supabase 대시보드 SQL Editor에서 그대로 실행하세요.

create table if not exists public.inquiries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles (id) on delete set null,
  name        text not null,
  phone       text,
  email       text,
  message     text not null,
  status      text not null default 'open' check (status in ('open', 'answered', 'closed')),
  answer      text,
  answered_at timestamptz,
  created_at  timestamptz not null default now()
);

alter table public.inquiries enable row level security;

-- 비로그인 방문자도 문의 남길 수 있음. 로그인 상태면 user_id는 본인 것만 허용.
drop policy if exists "Anyone can create inquiry" on public.inquiries;
create policy "Anyone can create inquiry"
  on public.inquiries for insert
  with check (user_id is null or user_id = auth.uid());

drop policy if exists "Users view own inquiries" on public.inquiries;
create policy "Users view own inquiries"
  on public.inquiries for select
  using (user_id is not null and user_id = auth.uid());

drop policy if exists "Admins manage inquiries" on public.inquiries;
create policy "Admins manage inquiries"
  on public.inquiries for all
  using (public.is_admin())
  with check (public.is_admin());

create index if not exists inquiries_status_idx on public.inquiries (status, created_at desc);
