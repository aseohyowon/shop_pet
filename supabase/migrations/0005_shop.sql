-- ④ 쇼핑몰: 상품, 장바구니 + 상품 이미지 스토리지

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  price int not null check (price >= 0),
  stock int not null default 0 check (stock >= 0),
  category text,
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;

create policy "Anyone can view active products"
  on public.products for select
  using (is_active = true or public.is_admin());

create policy "Admins manage products"
  on public.products for all
  using (public.is_admin())
  with check (public.is_admin());

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  product_id uuid not null references public.products (id) on delete cascade,
  quantity int not null check (quantity > 0),
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

alter table public.cart_items enable row level security;

create policy "Users manage own cart"
  on public.cart_items for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 상품 이미지 업로드용 퍼블릭 버킷 (읽기는 누구나, 쓰기는 관리자만)
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

create policy "Public can view product images"
  on storage.objects for select
  using (bucket_id = 'product-images');

create policy "Admins can upload product images"
  on storage.objects for insert
  with check (bucket_id = 'product-images' and public.is_admin());

create policy "Admins can update product images"
  on storage.objects for update
  using (bucket_id = 'product-images' and public.is_admin());

create policy "Admins can delete product images"
  on storage.objects for delete
  using (bucket_id = 'product-images' and public.is_admin());
