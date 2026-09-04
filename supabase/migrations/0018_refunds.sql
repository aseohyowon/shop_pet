-- ⑱ 취소 / 환불
-- Supabase 대시보드 SQL Editor 또는 `npm run db:migrate` 로 실행하세요.

-- 결제 테이블에 환불 정보
alter table public.payments add column if not exists refunded_amount int not null default 0;
alter table public.payments add column if not exists refunded_at timestamptz;
alter table public.payments add column if not exists cancel_reason text;

-- 예약 취소 시점별 환불율 (관리자 설정)
--   days_before N, refund_rate R  =>  "이용 N일 전까지 취소하면 R% 환불"
create table if not exists public.refund_policy_tiers (
  id          uuid primary key default gen_random_uuid(),
  days_before int  not null,
  refund_rate int  not null check (refund_rate between 0 and 100),
  created_at  timestamptz not null default now(),
  unique (days_before)
);

insert into public.refund_policy_tiers (days_before, refund_rate) values
  (7, 100),
  (3, 50),
  (1, 0)
on conflict (days_before) do nothing;

alter table public.refund_policy_tiers enable row level security;

drop policy if exists "Anyone can read refund policy" on public.refund_policy_tiers;
create policy "Anyone can read refund policy"
  on public.refund_policy_tiers for select using (true);

drop policy if exists "Admins manage refund policy" on public.refund_policy_tiers;
create policy "Admins manage refund policy"
  on public.refund_policy_tiers for all
  using (public.is_admin()) with check (public.is_admin());

-- 주문 취소 시 재고 복구 (결제 승인으로 이미 차감된 경우에만 호출)
create or replace function public.restore_order_stock(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.products p
    set stock = stock + oi.quantity
  from public.order_items oi
  where oi.order_id = p_order_id and oi.product_id = p.id;
end;
$$;

grant execute on function public.restore_order_stock(uuid) to service_role;
