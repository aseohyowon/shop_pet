<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllReservations } = useReservations()
const { fetchAllOrdersForAdmin } = useOrders()
const { fetchAllProductsForAdmin } = useProducts()
const { countOpenInquiries } = useInquiries()

const LOW_STOCK = 5

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const statusLabel: Record<string, string> = {
  pending: '승인 대기',
  confirmed: '확정',
  rejected: '거절됨',
  cancelled: '취소됨',
  completed: '완료'
}
const toHHMM = (t: string) => t?.slice(0, 5)

const reservations = ref<any[]>([])
const orders = ref<any[]>([])
const products = ref<any[]>([])
const openInquiries = ref(0)
const loading = ref(true)

const todayStr = new Date().toISOString().slice(0, 10)

const todayReservations = computed(() =>
  reservations.value.filter((r) => todayStr >= r.start_date && todayStr <= r.end_date)
)
const pendingCount = computed(() => reservations.value.filter((r) => r.status === 'pending').length)
const unhandledOrderCount = computed(() => orders.value.filter((o) => o.status === 'paid' || o.status === 'preparing').length)
const todayRevenue = computed(() =>
  orders.value
    .filter((o) => o.status !== 'pending' && o.status !== 'cancelled' && o.created_at.slice(0, 10) === todayStr)
    .reduce((sum, o) => sum + o.total_amount, 0)
)
const lowStockProducts = computed(() =>
  products.value.filter((p) => p.is_active && p.stock <= LOW_STOCK).sort((a, b) => a.stock - b.stock)
)
const stockIssueOrders = computed(() =>
  orders.value.filter((o) => o.stock_issue && o.status !== 'cancelled')
)

const stats = computed(() => [
  { label: '오늘 예약', value: `${todayReservations.value.length}건`, icon: 'calendar_month', to: '/admin/reservations', accent: false },
  { label: '승인 대기 예약', value: `${pendingCount.value}건`, icon: 'hourglass_top', to: '/admin/reservations', accent: pendingCount.value > 0 },
  { label: '미처리 주문', value: `${unhandledOrderCount.value}건`, icon: 'inventory_2', to: '/admin/orders', accent: false },
  { label: '오늘 매출', value: `${todayRevenue.value.toLocaleString()}원`, icon: 'payments', to: '/admin/orders', accent: false },
  { label: '재고 부족 상품', value: `${lowStockProducts.value.length}건`, icon: 'warning', to: '/admin/products', accent: lowStockProducts.value.length > 0 },
  { label: '미답변 문의', value: `${openInquiries.value}건`, icon: 'mark_chat_unread', to: '/admin/inquiries', accent: openInquiries.value > 0 },
  { label: '재고 부족 주문', value: `${stockIssueOrders.value.length}건`, icon: 'production_quantity_limits', to: '/admin/orders', accent: stockIssueOrders.value.length > 0 }
])

onMounted(async () => {
  try {
    const [reservationData, orderData, productData, inquiryCount] = await Promise.all([
      fetchAllReservations(),
      fetchAllOrdersForAdmin(),
      fetchAllProductsForAdmin(),
      countOpenInquiries().catch(() => 0)
    ])
    reservations.value = reservationData
    orders.value = orderData
    products.value = productData
    openInquiries.value = inquiryCount
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="flex flex-col gap-stack-lg">
    <div>
      <h1 class="font-headline-lg-mobile md:font-headline-lg text-headline-lg-mobile md:text-headline-lg text-on-surface">
        대시보드
      </h1>
      <p class="mt-1 font-body-md text-body-md text-on-surface-variant">
        {{ new Date().toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'short' }) }} · 오늘의 현황을 확인하세요.
      </p>
    </div>

    <!-- Stat bento -->
    <div class="grid grid-cols-2 gap-gutter lg:grid-cols-3">
      <NuxtLink
        v-for="s in stats"
        :key="s.label"
        :to="s.to"
        class="admin-card relative overflow-hidden transition-all hover:-translate-y-0.5"
        :class="s.accent ? '!border-l-4 !border-l-secondary' : ''"
      >
        <div
          v-if="!s.accent"
          class="pointer-events-none absolute -right-8 -top-8 h-24 w-24 rounded-full bg-primary-fixed/40 blur-2xl"
        />
        <span
          class="relative z-10 mb-3 flex h-10 w-10 items-center justify-center rounded-full"
          :class="s.accent ? 'bg-secondary-container/40 text-secondary' : 'bg-primary-fixed text-primary'"
        >
          <span class="material-symbols-outlined text-[20px]">{{ s.icon }}</span>
        </span>
        <p class="relative z-10 font-headline-lg text-headline-lg" :class="s.accent ? 'text-secondary' : 'text-on-surface'">
          {{ s.value }}
        </p>
        <p class="relative z-10 font-label-sm text-label-sm text-on-surface-variant">{{ s.label }}</p>
      </NuxtLink>
    </div>

    <div class="grid gap-gutter lg:grid-cols-2">
      <!-- Today's reservations -->
      <section class="admin-card">
        <div class="mb-5 flex items-end justify-between">
          <div>
            <h2 class="font-headline-md text-headline-md text-on-surface">오늘의 예약</h2>
            <p class="mt-1 font-body-md text-sm text-on-surface-variant">진행 중인 호텔 · 데이케어 예약입니다.</p>
          </div>
          <NuxtLink to="/admin/reservations" class="flex items-center font-label-md text-label-md text-primary hover:text-surface-tint">
            예약 관리 <span class="material-symbols-outlined text-[18px]">chevron_right</span>
          </NuxtLink>
        </div>
        <p v-if="loading" class="font-body-md text-sm text-on-surface-variant">불러오는 중...</p>
        <p v-else-if="todayReservations.length === 0" class="font-body-md text-sm text-on-surface-variant">
          오늘 진행 중인 예약이 없습니다.
        </p>
        <div v-else class="flex flex-col gap-3">
          <div
            v-for="r in todayReservations"
            :key="r.id"
            class="flex items-center gap-4 rounded-xl border border-outline-variant/50 bg-surface-container-lowest p-4 shadow-sm"
          >
            <span class="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-primary-fixed text-primary">
              <span class="material-symbols-outlined icon-filled">{{ r.type === 'daycare' ? 'sunny' : 'hotel' }}</span>
            </span>
            <div class="min-w-0 flex-grow">
              <p class="truncate font-label-md text-label-md text-on-surface">{{ r.pets?.name }} · {{ typeLabel[r.type] }}</p>
              <p class="truncate font-body-md text-sm text-on-surface-variant">
                {{ r.start_date }} {{ toHHMM(r.start_time) }} ~ {{ r.end_date }} {{ toHHMM(r.end_time) }}
              </p>
            </div>
            <span
              class="admin-chip shrink-0"
              :class="r.status === 'pending'
                ? 'bg-secondary-fixed text-secondary'
                : r.status === 'confirmed' || r.status === 'completed'
                  ? 'bg-primary text-on-primary'
                  : 'bg-surface-container-high text-on-surface-variant'"
            >
              {{ statusLabel[r.status] ?? r.status }}
            </span>
          </div>
        </div>
      </section>

      <!-- Low stock -->
      <section class="admin-card">
        <div class="mb-5 flex items-end justify-between">
          <div>
            <h2 class="font-headline-md text-headline-md text-on-surface">재고 부족 상품</h2>
            <p class="mt-1 font-body-md text-sm text-on-surface-variant">재고 {{ LOW_STOCK }}개 이하 상품입니다.</p>
          </div>
          <NuxtLink to="/admin/products" class="flex items-center font-label-md text-label-md text-primary hover:text-surface-tint">
            상품 관리 <span class="material-symbols-outlined text-[18px]">chevron_right</span>
          </NuxtLink>
        </div>
        <p v-if="loading" class="font-body-md text-sm text-on-surface-variant">불러오는 중...</p>
        <p v-else-if="lowStockProducts.length === 0" class="font-body-md text-sm text-on-surface-variant">
          재고가 부족한 상품이 없습니다.
        </p>
        <div v-else class="flex flex-col gap-2">
          <NuxtLink
            v-for="p in lowStockProducts"
            :key="p.id"
            :to="`/admin/products/${p.id}/edit`"
            class="flex items-center justify-between rounded-xl border border-outline-variant/50 bg-surface-container-lowest px-4 py-3 shadow-sm transition-colors hover:border-primary/30"
          >
            <span class="min-w-0 truncate font-label-md text-label-md text-on-surface">{{ p.name }}</span>
            <span
              class="admin-chip shrink-0"
              :class="p.stock === 0 ? 'bg-error-container text-on-error-container' : 'bg-secondary-fixed text-secondary'"
            >
              {{ p.stock === 0 ? '품절' : `${p.stock}개` }}
            </span>
          </NuxtLink>
        </div>
      </section>
    </div>
  </div>
</template>
