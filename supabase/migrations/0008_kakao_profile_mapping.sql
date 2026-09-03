-- 카카오 소셜 로그인 대응: 카카오가 주는 메타데이터는 이메일 회원가입과 키 이름이 달라서
-- (예: name 대신 full_name/nickname) 여러 후보를 순서대로 확인해 profiles.name을 채우도록 수정.

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
    coalesce(
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'nickname',
      new.raw_user_meta_data ->> 'preferred_username',
      new.raw_user_meta_data ->> 'user_name'
    ),
    new.raw_user_meta_data ->> 'phone',
    'customer'
  );
  return new;
end;
$$;
