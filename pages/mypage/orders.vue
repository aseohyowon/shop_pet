<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchMyOrders } = useOrders()

const orders = ref<any[]>([])
const loading = ref(true)

const statusLabel: Record<string, string> = {
  pending: '결제 대기',
  paid: '결제완료',
  preparing: '배송준비',
  shipping: '배송중',
  completed: '배송완료',
  cancelled: '취소됨'
}

const itemsSummary = (order: any) => {
  const items = order.order_items ?? []
  if (items.length === 0) return '-'
  const first = items[0].products?.name ?? '상품'
  return items.length > 1 ? `${first} 외 ${items.length - 1}건` : first
}

onMounted(async () => {
  try {
    orders.value = await fetchMyOrders()
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">마이페이지</h1>
    <p class="mb-6 text-gray-500">예약 내역과 주문 내역을 한 곳에서 확인하세요.</p>

    <CommonMypageTabs />

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="orders.length === 0" class="py-8 text-center text-sm text-gray-400">주문 내역이 없습니다.</p>

    <div v-else class="space-y-3">
      <div v-for="o in orders" :key="o.id" class="card">
        <div class="flex items-center justify-between">
          <div>
            <p class="font-semibold text-gray-900">{{ itemsSummary(o) }}</p>
            <p class="text-sm text-gray-400">
              {{ new Date(o.created_at).toLocaleDateString('ko-KR') }} · {{ o.total_amount.toLocaleString() }}원
            </p>
          </div>
          <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-semibold text-gray-600">
            {{ statusLabel[o.status] ?? o.status }}
          </span>
        </div>
        <div v-if="o.tracking_number" class="mt-3 flex flex-wrap items-center gap-2 border-t border-gray-100 pt-3 text-sm">
          <span class="text-gray-500">
            {{ courierLabel(o.tracking_courier) || '택배' }} · {{ o.tracking_number }}
          </span>
          <a
            :href="trackingUrl(o.tracking_courier, o.tracking_number)"
            target="_blank"
            rel="noopener"
            class="rounded-lg border border-brand-200 px-3 py-1 text-xs font-semibold text-brand-600 hover:bg-brand-50"
          >
            배송조회
          </a>
        </div>
        <p v-else-if="o.shipping_address" class="mt-3 border-t border-gray-100 pt-3 text-xs text-gray-400">
          배송지: {{ o.shipping_address }}
        </p>
      </div>
    </div>
  </div>
</template>
