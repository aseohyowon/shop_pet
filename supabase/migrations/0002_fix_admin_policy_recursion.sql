-- 0001의 "Admins can view all profiles" 정책이 profiles를 직접 재조회하면서
-- 무한 재귀(42P17) 오류를 일으켜서, SECURITY DEFINER 함수로 우회하도록 수정.

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

drop policy if exists "Admins can view all profiles" on public.profiles;

create policy "Admins can view all profiles"
  on public.profiles for select
  using (public.is_admin());
