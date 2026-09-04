-- ⑳ 1:1 문의 메뉴 노출 on/off (관리자 설정)
-- 기본값 'off' — 지금은 문의 메뉴를 숨긴다. 관리자 페이지에서 켤 수 있음.

insert into public.site_settings (key, value)
values ('contact_enabled', 'off')
on conflict (key) do nothing;
