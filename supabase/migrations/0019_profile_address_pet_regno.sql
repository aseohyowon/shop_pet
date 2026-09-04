-- ⑲ 회원 주소 + 반려동물 동물등록번호

alter table public.profiles add column if not exists postcode       text;
alter table public.profiles add column if not exists address        text;
alter table public.profiles add column if not exists address_detail text;

alter table public.pets add column if not exists registration_no text; -- 동물등록번호 (선택)

-- 회원가입 시 주소도 메타데이터에서 profiles 로 복사
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, phone, postcode, address, address_detail, role)
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
    new.raw_user_meta_data ->> 'postcode',
    new.raw_user_meta_data ->> 'address',
    new.raw_user_meta_data ->> 'address_detail',
    'customer'
  );
  return new;
end;
$$;
