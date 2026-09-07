<script setup lang="ts">
import type { Pet } from '~/types/database.types'

definePageMeta({ middleware: 'auth' })

const { user, profile, fetchProfile } = useAuth()
const { fetchMyReservations } = useReservations()
const { fetchMyOrders } = useOrders()
const { fetchMyPets } = usePets()
const { isWarm, contactEnabled } = useSiteTheme()

const points = computed(() => profile.value?.points ?? 0)

const orderStatusLabel: Record<string, string> = {
  pending: '결제 대기',
  paid: '결제완료',
  preparing: '배송준비',
  shipping: '배송중',
  completed: '배송완료',
  cancelled: '취소됨'
}

const statusLabel: Record<string, string> = {
  pending: '승인 대기',
  confirmed: '확정',
  rejected: '거절됨',
  cancelled: '취소됨',
  completed: '완료'
}
const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const toHHMM = (t: string) => t?.slice(0, 5)

const latestReservation = ref<any | null>(null)
const latestOrder = ref<any | null>(null)
const myPets = ref<Pet[]>([])

const latestOrderSummary = computed(() => {
  const items = latestOrder.value?.order_items ?? []
  if (items.length === 0) return '-'
  const first = items[0].products?.name ?? '상품'
  return items.length > 1 ? `${first} 외 ${items.length - 1}건` : first
})

const firstPet = computed(() => myPets.value[0] ?? null)

const displayName = computed(() => profile.value?.name ?? user.value?.email ?? '회원')

onMounted(async () => {
  const [reservations, orders, pets] = await Promise.all([
    fetchMyReservations(),
    fetchMyOrders(),
    fetchMyPets(),
    fetchProfile()
  ])
  latestReservation.value = reservations[0] ?? null
  latestOrder.value = orders[0] ?? null
  myPets.value = pets
})
</script>

<template>
  <!-- ══════════ Warm 테마 ══════════ -->
  <div v-if="isWarm" class="container-warm flex flex-col gap-gutter py-stack-lg md:flex-row">
    <!-- 사이드바 -->
    <aside class="w-full shrink-0 md:w-64">
      <div class="sticky top-28 rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-6 shadow-[0_4px_20px_-2px_rgba(68,42,16,0.05)]">
        <nav class="flex flex-col gap-2">
          <NuxtLink to="/mypage" class="flex items-center gap-3 rounded-lg bg-surface-container-high px-4 py-3 font-bold text-primary" active-class="">
            <span class="material-symbols-outlined icon-filled">person</span> 내 정보
          </NuxtLink>
          <NuxtLink to="/mypage/reservations" class="flex items-center gap-3 rounded-lg px-4 py-3 font-medium text-on-surface-variant transition-colors hover:bg-surface-container hover:text-primary">
            <span class="material-symbols-outlined">calendar_today</span> 예약 내역
          </NuxtLink>
          <NuxtLink to="/mypage/orders" class="flex items-center gap-3 rounded-lg px-4 py-3 font-medium text-on-surface-variant transition-colors hover:bg-surface-container hover:text-primary">
            <span class="material-symbols-outlined">shopping_bag</span> 주문 내역
          </NuxtLink>
          <NuxtLink to="/mypage/passes" class="flex items-center gap-3 rounded-lg px-4 py-3 font-medium text-on-surface-variant transition-colors hover:bg-surface-container hover:text-primary">
            <span class="material-symbols-outlined">confirmation_number</span> 정기권
          </NuxtLink>
          <NuxtLink to="/mypage/points" class="flex items-center gap-3 rounded-lg px-4 py-3 font-medium text-on-surface-variant transition-colors hover:bg-surface-container hover:text-primary">
            <span class="material-symbols-outlined">savings</span> 포인트
          </NuxtLink>
          <NuxtLink v-if="contactEnabled" to="/mypage/inquiries" class="flex items-center gap-3 rounded-lg px-4 py-3 font-medium text-on-surface-variant transition-colors hover:bg-surface-container hover:text-primary">
            <span class="material-symbols-outlined">support_agent</span> 문의 내역
          </NuxtLink>
        </nav>
      </div>
    </aside>

    <!-- 본문 -->
    <div class="flex w-full flex-grow flex-col gap-stack-lg">
      <!-- 프로필 요약 -->
      <section class="grid grid-cols-1 gap-gutter md:grid-cols-3">
        <div class="relative flex flex-col items-center gap-6 overflow-hidden rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-6 shadow-sm sm:flex-row sm:items-start md:col-span-2">
          <div class="absolute -right-10 -top-10 h-40 w-40 rounded-full bg-secondary-fixed/30 blur-2xl"></div>
          <div class="z-10 flex h-24 w-24 items-center justify-center rounded-full border-4 border-surface bg-primary-fixed text-3xl shadow-sm">🐶</div>
          <div class="z-10 flex-grow text-center sm:text-left">
            <h1 class="mb-1 font-headline-lg-mobile text-headline-lg-mobile text-on-surface md:font-headline-lg md:text-headline-lg">
              안녕하세요, {{ displayName }}님!
            </h1>
            <p class="mb-3 font-body-md text-body-md text-on-surface-variant">
              오늘도 <span v-if="firstPet">{{ firstPet.name }}와 </span>행복한 하루 보내세요.
            </p>
            <NuxtLink to="/mypage/points" class="mb-4 inline-flex items-center gap-2 rounded-full bg-secondary-fixed/40 px-4 py-1.5 font-label-md text-label-md text-primary transition-colors hover:bg-secondary-fixed/60">
              <span class="material-symbols-outlined text-[18px]">savings</span>
              보유 포인트 {{ points.toLocaleString() }}P
            </NuxtLink>
            <div class="flex flex-wrap justify-center gap-3 sm:justify-start">
              <NuxtLink to="/mypage/reservations" class="rounded-lg bg-primary px-5 py-2.5 font-label-md text-label-md text-on-primary shadow-sm transition-colors hover:bg-primary-container">예약 내역</NuxtLink>
              <NuxtLink to="/mypage/orders" class="rounded-lg border border-outline-variant bg-surface-container-high px-5 py-2.5 font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container-highest">주문 내역</NuxtLink>
            </div>
          </div>
        </div>

        <div class="flex h-full flex-col gap-gutter">
          <div class="flex flex-grow items-center gap-4 rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-5 shadow-sm">
            <div class="h-16 w-16 shrink-0 rounded-full border-2 border-primary p-1">
              <div class="flex h-full w-full items-center justify-center rounded-full bg-surface-container text-2xl">🐾</div>
            </div>
            <div class="flex-grow">
              <h3 class="font-headline-md text-lg text-on-surface">{{ firstPet?.name ?? '반려동물 미등록' }}</h3>
              <p class="font-label-sm text-label-sm text-on-surface-variant">
                <template v-if="firstPet">{{ firstPet.breed || '견종 미입력' }}<span v-if="firstPet.age"> · {{ firstPet.age }}살</span></template>
                <template v-else>예약 시 등록할 수 있어요</template>
              </p>
            </div>
          </div>
          <div class="flex-grow rounded-2xl border-l-4 border-l-secondary border-surface-container-highest bg-gradient-to-br from-surface to-surface-container-low p-5 shadow-sm">
            <h3 class="mb-1 flex items-center gap-1 font-label-sm text-label-sm text-on-surface-variant">
              <span class="material-symbols-outlined text-[16px]">stars</span> 등록 반려동물
            </h3>
            <div class="flex items-baseline gap-1">
              <span class="font-headline-lg text-headline-lg font-bold text-secondary">{{ myPets.length }}</span>
              <span class="font-body-md text-body-md text-on-surface-variant">마리</span>
            </div>
          </div>
        </div>
      </section>

      <!-- 예약 현황 -->
      <section class="rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-6 shadow-sm md:p-8">
        <div class="mb-6 flex items-end justify-between">
          <div>
            <h2 class="font-headline-md text-headline-md text-on-surface">예약 현황</h2>
            <p class="mt-1 font-body-md text-sm text-on-surface-variant">최근 예약 및 이용 내역을 확인하세요.</p>
          </div>
          <NuxtLink to="/mypage/reservations" class="flex items-center font-label-md text-label-md text-primary hover:text-surface-tint">
            전체보기 <span class="material-symbols-outlined text-[18px]">chevron_right</span>
          </NuxtLink>
        </div>
        <div v-if="latestReservation" class="flex flex-col gap-4 rounded-xl border border-outline-variant/50 bg-surface-container-lowest p-5 shadow-sm sm:flex-row sm:items-center">
          <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-primary-fixed text-primary">
            <span class="material-symbols-outlined icon-filled">{{ latestReservation.type === 'hotel' ? 'hotel' : 'sunny' }}</span>
          </div>
          <div class="flex-grow">
            <div class="mb-1 flex items-center gap-2">
              <span class="rounded-full bg-primary px-2 py-0.5 font-label-sm text-[10px] uppercase tracking-wider text-on-primary">
                {{ statusLabel[latestReservation.status] ?? latestReservation.status }}
              </span>
            </div>
            <h3 class="font-label-md text-label-md text-on-surface">
              {{ typeLabel[latestReservation.type] }} · {{ latestReservation.pets?.name }}
            </h3>
            <p class="mt-1 flex items-center gap-1 font-body-md text-sm text-on-surface-variant">
              <span class="material-symbols-outlined text-[14px]">calendar_month</span>
              {{ latestReservation.start_date }} {{ toHHMM(latestReservation.start_time) }} ~
              {{ latestReservation.end_date }} {{ toHHMM(latestReservation.end_time) }}
            </p>
          </div>
          <NuxtLink
            v-if="!latestReservation.deposit_paid && latestReservation.status !== 'rejected' && latestReservation.status !== 'cancelled'"
            :to="`/checkout/reservation?id=${latestReservation.id}`"
            class="btn-warm shrink-0 !min-h-0 !px-4 !py-2 text-sm"
          >
            결제하기
          </NuxtLink>
        </div>
        <p v-else class="rounded-xl border border-outline-variant/50 p-5 font-body-md text-sm text-on-surface-variant">예약 내역이 없습니다.</p>
      </section>

      <!-- 쇼핑 내역 -->
      <section class="rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-6 shadow-sm md:p-8">
        <div class="mb-6 flex items-end justify-between">
          <div>
            <h2 class="font-headline-md text-headline-md text-on-surface">쇼핑 내역</h2>
            <p class="mt-1 font-body-md text-sm text-on-surface-variant">최근 구매하신 상품입니다.</p>
          </div>
          <NuxtLink to="/mypage/orders" class="flex items-center font-label-md text-label-md text-primary hover:text-surface-tint">
            전체보기 <span class="material-symbols-outlined text-[18px]">chevron_right</span>
          </NuxtLink>
        </div>
        <div v-if="latestOrder" class="flex gap-4 rounded-xl border border-outline-variant/50 bg-surface-container-lowest p-4">
          <div class="flex h-20 w-20 shrink-0 items-center justify-center rounded-lg border border-outline-variant/20 bg-surface text-3xl">📦</div>
          <div class="flex flex-grow flex-col justify-between">
            <div>
              <div class="mb-1 flex items-start justify-between">
                <span class="font-label-sm text-label-sm font-medium text-secondary">
                  {{ orderStatusLabel[latestOrder.status] ?? latestOrder.status }}
                </span>
                <span class="font-label-sm text-[11px] text-on-surface-variant">
                  {{ new Date(latestOrder.created_at).toLocaleDateString('ko-KR') }} 결제
                </span>
              </div>
              <h3 class="line-clamp-2 font-label-md text-label-md leading-tight text-on-surface">{{ latestOrderSummary }}</h3>
            </div>
            <div class="mt-2 flex items-end justify-between">
              <span class="font-headline-md text-base text-on-surface">{{ latestOrder.total_amount.toLocaleString() }}원</span>
              <NuxtLink
                v-if="latestOrder.status === 'pending'"
                :to="`/checkout/order?resume=${latestOrder.id}`"
                class="rounded-lg bg-primary px-3 py-1 font-label-sm text-label-sm text-on-primary hover:bg-primary-container"
              >
                결제하기
              </NuxtLink>
              <a
                v-else-if="latestOrder.tracking_number"
                :href="trackingUrl(latestOrder.tracking_courier, latestOrder.tracking_number)"
                target="_blank"
                rel="noopener"
                class="rounded-lg border border-primary/30 px-3 py-1 font-label-sm text-label-sm text-primary hover:bg-primary-fixed/20"
              >
                배송조회
              </a>
            </div>
          </div>
        </div>
        <p v-else class="rounded-xl border border-outline-variant/50 p-5 font-body-md text-sm text-on-surface-variant">주문 내역이 없습니다.</p>
      </section>
    </div>
  </div>

  <!-- ══════════ 기본 테마 ══════════ -->
  <div v-else class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">마이페이지</h1>
    <p class="mb-6 text-gray-500">
      {{ profile?.name ?? user?.email }}님, 예약 내역과 주문 내역을 한 곳에서 확인하세요.
    </p>

    <CommonMypageTabs />

    <NuxtLink to="/mypage/points" class="card mb-6 flex items-center justify-between transition hover:border-brand-200">
      <span class="font-semibold text-gray-900">보유 포인트</span>
      <span class="text-xl font-bold text-brand-600">{{ points.toLocaleString() }}P</span>
    </NuxtLink>

    <div class="grid gap-6 md:grid-cols-2">
      <div class="card">
        <p class="mb-4 font-semibold text-gray-900">최근 예약</p>
        <div v-if="latestReservation" class="flex items-center justify-between border-b border-gray-100 pb-3 text-sm">
          <div>
            <p class="font-medium text-gray-800">{{ typeLabel[latestReservation.type] }} · {{ latestReservation.pets?.name }}</p>
            <p class="text-gray-400">
              {{ latestReservation.start_date }} {{ toHHMM(latestReservation.start_time) }} ~
              {{ latestReservation.end_date }} {{ toHHMM(latestReservation.end_time) }}
            </p>
          </div>
          <span class="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-600">
            {{ statusLabel[latestReservation.status] ?? latestReservation.status }}
          </span>
        </div>
        <p v-else class="border-b border-gray-100 pb-3 text-sm text-gray-400">예약 내역이 없습니다.</p>
        <NuxtLink to="/mypage/reservations" class="mt-4 inline-block text-sm font-semibold text-brand-600">
          예약 내역 전체보기 →
        </NuxtLink>
      </div>

      <div class="card">
        <p class="mb-4 font-semibold text-gray-900">최근 주문</p>
        <div v-if="latestOrder" class="flex items-center justify-between border-b border-gray-100 pb-3 text-sm">
          <div>
            <p class="font-medium text-gray-800">{{ latestOrderSummary }}</p>
            <p class="text-gray-400">{{ new Date(latestOrder.created_at).toLocaleDateString('ko-KR') }} 주문</p>
          </div>
          <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-semibold text-gray-600">
            {{ orderStatusLabel[latestOrder.status] ?? latestOrder.status }}
          </span>
        </div>
        <p v-else class="border-b border-gray-100 pb-3 text-sm text-gray-400">주문 내역이 없습니다.</p>
        <NuxtLink to="/mypage/orders" class="mt-4 inline-block text-sm font-semibold text-brand-600">
          주문 내역 전체보기 →
        </NuxtLink>
      </div>
    </div>
  </div>
</template>
