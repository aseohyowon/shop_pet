<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const { fetchReservationById } = useReservations()
const { createReservationPayment } = usePayments()

const reservation = ref<any | null>(null)
const loading = ref(true)
const errorMessage = ref('')
const paymentInfo = ref<{ paymentId: string; amount: number; orderName: string } | null>(null)
const widgetRef = ref<{ requestPayment: () => Promise<void> } | null>(null)
const submitting = ref(false)

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const toHHMM = (t: string) => t?.slice(0, 5)

const DEPOSIT_AMOUNT = 30000 // TODO(⑤ 이후): 실제 예약금 산정 로직으로 교체 (현재는 임시 고정 금액)

onMounted(async () => {
  const id = route.query.id as string | undefined
  if (!id) {
    loading.value = false
    return
  }

  try {
    reservation.value = await fetchReservationById(id)
    if (reservation.value && !reservation.value.deposit_paid) {
      const payment = await createReservationPayment(id, DEPOSIT_AMOUNT)
      paymentInfo.value = {
        paymentId: payment.id,
        amount: payment.amount,
        orderName: `${typeLabel[reservation.value.type]} 예약금 (${reservation.value.pets?.name})`
      }
    }
  } catch (e: any) {
    errorMessage.value = e?.message ?? '예약금 결제 준비에 실패했습니다.'
  } finally {
    loading.value = false
  }
})

const handlePay = async () => {
  if (!widgetRef.value) return
  submitting.value = true
  try {
    await widgetRef.value.requestPayment()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '결제 요청 중 오류가 발생했습니다.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="container-page max-w-lg py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">예약금 결제</h1>
    <p class="mb-8 text-gray-500">예약을 확정하려면 예약금 결제가 필요합니다.</p>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <p v-else-if="!reservation" class="py-8 text-center text-sm text-gray-400">
      결제할 예약을 찾을 수 없습니다.
      <NuxtLink to="/mypage/reservations" class="text-brand-600 hover:underline">내 예약 내역 보기</NuxtLink>
    </p>

    <p v-else-if="reservation.deposit_paid" class="py-8 text-center text-sm text-gray-400">
      이미 예약금이 결제된 예약입니다.
      <NuxtLink to="/mypage/reservations" class="text-brand-600 hover:underline">내 예약 내역 보기</NuxtLink>
    </p>

    <template v-else>
      <div class="card space-y-4">
        <div class="flex justify-between text-sm text-gray-500">
          <span>서비스</span>
          <span>{{ typeLabel[reservation.type] }}</span>
        </div>
        <div class="flex justify-between text-sm text-gray-500">
          <span>기간</span>
          <span>
            {{ reservation.start_date }} {{ toHHMM(reservation.start_time) }} ~
            {{ reservation.end_date }} {{ toHHMM(reservation.end_time) }}
          </span>
        </div>
        <div class="flex justify-between text-sm text-gray-500">
          <span>반려동물</span>
          <span>{{ reservation.pets?.name }} ({{ reservation.pets?.breed || '견종 미입력' }})</span>
        </div>
        <div class="flex justify-between border-t border-gray-100 pt-4 font-bold text-gray-900">
          <span>예약금</span>
          <span>{{ DEPOSIT_AMOUNT.toLocaleString() }}원</span>
        </div>
      </div>

      <div v-if="paymentInfo" class="card mt-4">
        <PaymentWidget
          ref="widgetRef"
          :payment-id="paymentInfo.paymentId"
          :amount="paymentInfo.amount"
          :order-name="paymentInfo.orderName"
        />
      </div>

      <p v-if="errorMessage" class="mt-3 text-sm text-red-500">{{ errorMessage }}</p>

      <button type="button" class="btn-primary mt-6 w-full" :disabled="submitting || !paymentInfo" @click="handlePay">
        {{ submitting ? '결제 요청 중...' : `${DEPOSIT_AMOUNT.toLocaleString()}원 결제하기` }}
      </button>
    </template>
  </div>
</template>
