<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchMyReservations, cancelMyPendingReservation } = useReservations()
const { fetchPaidPayment } = usePayments()
const { fetchRefundTiers, reservationRefund, cancelPayment } = useRefunds()

const reservations = ref<any[]>([])
const tiers = ref<any[]>([])
const loading = ref(true)
const cancelling = ref<string | null>(null)
const errorMessage = ref('')

const statusLabel: Record<string, string> = {
  pending: '승인 대기',
  confirmed: '확정',
  rejected: '거절됨',
  cancelled: '취소됨',
  completed: '완료'
}

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const toHHMM = (t: string) => t?.slice(0, 5)

const load = async () => {
  loading.value = true
  try {
    const [resv, t] = await Promise.all([fetchMyReservations(), fetchRefundTiers().catch(() => [])])
    reservations.value = resv
    tiers.value = t
  } finally {
    loading.value = false
  }
}
onMounted(load)

const isCancellable = (r: any) =>
  r.status !== 'cancelled' && r.status !== 'rejected' && r.status !== 'completed'

const handleCancel = async (r: any) => {
  errorMessage.value = ''

  // 미결제 예약 → 그냥 취소
  if (!r.deposit_paid) {
    if (r.status !== 'pending') return
    if (!confirm('이 예약을 취소하시겠어요?')) return
    cancelling.value = r.id
    try {
      await cancelMyPendingReservation(r.id)
      await load()
    } catch (e: any) {
      errorMessage.value = e?.message ?? '취소에 실패했습니다.'
    } finally {
      cancelling.value = null
    }
    return
  }

  // 결제 완료 예약 → 환불 규정 적용
  cancelling.value = r.id
  try {
    const payment = await fetchPaidPayment('reservation', r.id)
    if (!payment) throw new Error('결제 정보를 찾을 수 없습니다. 고객센터로 문의해주세요.')
    const refund = reservationRefund(r.start_date, payment.amount, tiers.value)
    const pointLine = payment.points_used > 0
      ? `사용 포인트 ${payment.points_used.toLocaleString()}P 는 전액 복원됩니다.\n`
      : ''
    const msg =
      `이용일까지 ${refund.daysUntil}일 남음 · 환불 규정 ${refund.rate}%\n` +
      `환불 예정 금액: ${refund.amount.toLocaleString()}원 (결제 ${payment.amount.toLocaleString()}원)\n` +
      pointLine +
      `\n예약을 취소하시겠어요?`
    if (!confirm(msg)) {
      cancelling.value = null
      return
    }
    await cancelPayment({ paymentId: payment.id, reason: '고객 예약 취소' })
    await load()
  } catch (e: any) {
    errorMessage.value = e?.data?.statusMessage ?? e?.message ?? '예약 취소에 실패했습니다.'
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
    <p v-else-if="reservations.length === 0" class="py-8 text-center text-sm text-gray-400">
      예약 내역이 없습니다.
    </p>

    <div v-else class="space-y-3">
      <div v-for="r in reservations" :key="r.id" class="card flex items-center justify-between gap-3">
        <div class="min-w-0">
          <p class="font-semibold text-gray-900">{{ typeLabel[r.type] }} · {{ r.pets?.name }}</p>
          <p class="text-sm text-gray-400">
            {{ r.start_date }} {{ toHHMM(r.start_time) }} ~ {{ r.end_date }} {{ toHHMM(r.end_time) }}
          </p>
        </div>
        <div class="flex shrink-0 items-center gap-2">
          <span
            class="rounded-full px-3 py-1 text-xs font-semibold"
            :class="r.status === 'confirmed' || r.status === 'completed'
              ? 'bg-green-50 text-green-600'
              : r.status === 'rejected' || r.status === 'cancelled'
                ? 'bg-gray-100 text-gray-500'
                : 'bg-brand-50 text-brand-600'"
          >
            {{ !r.deposit_paid && r.status === 'pending' ? '결제 대기' : statusLabel[r.status] ?? r.status }}
          </span>
          <NuxtLink
            v-if="!r.deposit_paid && r.status !== 'rejected' && r.status !== 'cancelled'"
            :to="`/checkout/reservation?id=${r.id}`"
            class="btn-primary !px-3 !py-1.5 text-xs"
          >
            결제하기
          </NuxtLink>
          <button
            v-if="isCancellable(r)"
            type="button"
            class="rounded-lg border border-gray-300 px-3 py-1.5 text-xs font-medium text-gray-500 hover:border-red-300 hover:text-red-500"
            :disabled="cancelling === r.id"
            @click="handleCancel(r)"
          >
            {{ cancelling === r.id ? '처리 중...' : '예약 취소' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
