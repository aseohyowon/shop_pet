-- ⑩ 쇼핑몰 카테고리 관리
-- Supabase 대시보드 SQL Editor에서 그대로 실행하세요.
-- products.category 는 "카테고리 이름"(text)을 그대로 유지하고,
-- categories 테이블은 관리자가 관리하는 "노출 목록/순서"로만 사용한다.

create table if not exists public.categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  sort_order int  not null default 0,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;

-- 방문자 누구나 활성 카테고리를 볼 수 있어야 쇼핑몰 필터가 그려짐
drop policy if exists "Anyone can read categories" on public.categories;
create policy "Anyone can read categories"
  on public.categories for select
  using (true);

drop policy if exists "Admins manage categories" on public.categories;
create policy "Admins manage categories"
  on public.categories for all
  using (public.is_admin())
  with check (public.is_admin());

-- 기존 상품에 이미 들어있는 카테고리 값들을 목록으로 옮겨온다
insert into public.categories (name, sort_order)
select distinct category, 0
from public.products
where category is not null and category <> ''
on conflict (name) do nothing;
