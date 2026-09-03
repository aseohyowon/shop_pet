-- ⑨ 사이트 테마 설정: 관리자가 고객용 화면 디자인(테마)을 선택할 수 있게 한다.
-- Supabase 대시보드 SQL Editor에서 그대로 실행하세요.

create table if not exists public.site_settings (
  key        text primary key,
  value      text not null,
  updated_at timestamptz not null default now()
);

-- 기본값 시드
insert into public.site_settings (key, value) values
  ('site_theme',   'default'),  -- 'default' | 'theme1' | 'theme2'
  ('home_variant', 'auto')      -- 'auto' | 'main1' | 'main2'
on conflict (key) do nothing;

alter table public.site_settings enable row level security;

-- 방문자 누구나 현재 테마를 읽을 수 있어야 화면이 그려짐 (비로그인 포함)
drop policy if exists "Anyone can read site settings" on public.site_settings;
create policy "Anyone can read site settings"
  on public.site_settings for select
  using (true);

-- 수정/추가는 관리자만
drop policy if exists "Admins can update site settings" on public.site_settings;
create policy "Admins can update site settings"
  on public.site_settings for update
  using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

drop policy if exists "Admins can insert site settings" on public.site_settings;
create policy "Admins can insert site settings"
  on public.site_settings for insert
  with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- updated_at 자동 갱신
create or replace function public.touch_site_settings_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_site_settings_updated on public.site_settings;
create trigger on_site_settings_updated
  before update on public.site_settings
  for each row execute procedure public.touch_site_settings_updated_at();
