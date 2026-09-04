<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchMyOrders } = useOrders()
const { fetchPaidPayment } = usePayments()
const { cancelPayment } = useRefunds()

const orders = ref<any[]>([])
const loading = ref(true)
const cancelling = ref<string | null>(null)
const errorMessage = ref('')

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

const load = async () => {
  loading.value = true
  try {
    orders.value = await fetchMyOrders()
  } finally {
    loading.value = false
  }
}
onMounted(load)

// 배송 전(결제완료/배송준비)만 고객이 직접 취소 = 전액 환불
const canCancel = (o: any) => o.status === 'paid' || o.status === 'preparing'

const handleCancel = async (o: any) => {
  if (!confirm(`이 주문을 취소하고 전액 환불받으시겠어요?\n(${o.total_amount.toLocaleString()}원)`)) return
  errorMessage.value = ''
  cancelling.value = o.id
  try {
    const payment = await fetchPaidPayment('order', o.id)
    if (!payment) throw new Error('결제 정보를 찾을 수 없습니다. 고객센터로 문의해주세요.')
    await cancelPayment({ paymentId: payment.id, reason: '고객 주문 취소' })
    await load()
  } catch (e: any) {
    errorMessage.value = e?.data?.statusMessage ?? e?.message ?? '주문 취소에 실패했습니다.'
  } finally {
    cancelling.value = null
  }
}
</script>

<template>
  <div class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">마이페이지</h1>
    <p class="mb-6 text-gray-500">예약 내역과 주문 내역을 한 곳에서 확인하세요.</p>

    <CommonMypageTabs />

    <p v-if="errorMessage" class="mb-4 text-sm text-red-500">{{ errorMessage }}</p>
    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="orders.length === 0" class="py-8 text-center text-sm text-gray-400">주문 내역이 없습니다.</p>

    <div v-else class="space-y-3">
      <div v-for="o in orders" :key="o.id" class="card">
        <div class="flex items-center justify-between gap-3">
          <div class="min-w-0">
            <p class="font-semibold text-gray-900">{{ itemsSummary(o) }}</p>
            <p class="text-sm text-gray-400">
              {{ new Date(o.created_at).toLocaleDateString('ko-KR') }} · {{ o.total_amount.toLocaleString() }}원
            </p>
          </div>
          <div class="flex shrink-0 items-center gap-2">
            <span
              class="rounded-full px-3 py-1 text-xs font-semibold"
              :class="o.status === 'pending'
                ? 'bg-brand-50 text-brand-600'
                : o.status === 'cancelled'
                  ? 'bg-gray-100 text-gray-500'
                  : 'bg-gray-100 text-gray-600'"
            >
              {{ statusLabel[o.status] ?? o.status }}
            </span>
            <NuxtLink
              v-if="o.status === 'pending'"
              :to="`/checkout/order?resume=${o.id}`"
              class="btn-primary !px-3 !py-1.5 text-xs"
            >
              결제하기
            </NuxtLink>
            <button
              v-else-if="canCancel(o)"
              type="button"
              class="rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-500 hover:border-red-300 hover:text-red-500"
              :disabled="cancelling === o.id"
              @click="handleCancel(o)"
            >
              {{ cancelling === o.id ? '처리 중...' : '주문 취소' }}
            </button>
          </div>
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
        <p v-if="o.status === 'shipping' || o.status === 'completed'" class="mt-2 text-xs text-gray-400">
          배송이 시작된 주문은 <NuxtLink to="/contact" class="text-brand-600 underline">고객센터</NuxtLink>로 반품 문의해주세요.
        </p>
      </div>
    </div>
  </div>
</template>
