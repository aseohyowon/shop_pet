<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const router = useRouter()
const { fetchReservationById } = useReservations()
const { createReservationPayment } = usePayments()
const { fetchServiceSettings, nights, hoursBetween } = useServiceSettings()
const { fetchMyBalance } = usePoints()

const reservation = ref<any | null>(null)
const settings = ref<Record<string, any>>({})
const loading = ref(true)
const errorMessage = ref('')
const paymentInfo = ref<{ paymentId: string; amount: number; orderName: string } | null>(null)
const widgetRef = ref<{ requestPayment: () => Promise<void> } | null>(null)
const submitting = ref(false)

// 포인트
const pointBalance = ref(0)
const pointsToUse = ref(0)

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const toHHMM = (t: string) => t?.slice(0, 5)

const units = computed(() => {
  const r = reservation.value
  if (!r) return 1
  return r.type === 'hotel' ? nights(r.start_date, r.end_date) : 1
})

const daycareHours = computed(() => {
  const r = reservation.value
  return r ? hoursBetween(toHHMM(r.start_time), toHHMM(r.end_time)) : 1
})

// 예약금 비율 적용 전 총액
const priceBaseAmount = computed(() => {
  const r = reservation.value
  const s = r && settings.value?.[r.type]
  if (!s) return 0
  if (r.type === 'hotel') return s.price * units.value
  if (r.daycare_hourly) return Math.min(daycareHours.value * (s.hourly_price ?? 4000), s.price)
  return s.price
})

// 결제 레코드 생성 전 예상 금액 (서비스 요금 기준)
const expectedAmount = computed(() => {
  const r = reservation.value
  const s = r && settings.value?.[r.type]
  if (!s) return 0
  return Math.round(priceBaseAmount.value * Number(s.deposit_rate ?? 1))
})

const baseAmount = computed(() => paymentInfo.value?.amount != null
  ? paymentInfo.value.amount + pointsToUse.value
  : expectedAmount.value)

const maxUsablePoints = computed(() => Math.min(pointBalance.value, baseAmount.value))
const payable = computed(() => Math.max(0, baseAmount.value - pointsToUse.value))
const pointsLocked = computed(() => !!paymentInfo.value)

const clampPoints = () => {
  let v = Math.floor(Number(pointsToUse.value) || 0)
  if (v < 0) v = 0
  if (v > maxUsablePoints.value) v = maxUsablePoints.value
  pointsToUse.value = v
}
const useAllPoints = () => {
  pointsToUse.value = maxUsablePoints.value
}

const priceBreakdown = computed(() => {
  const r = reservation.value
  if (!r) return ''
  const s = settings.value?.[r.type]
  if (!s) return ''
  const rateNote = s.deposit_rate < 1 ? ` · 예약금 ${Math.round(s.deposit_rate * 100)}%` : ''
  let base: string
  if (r.type === 'hotel') {
    base = `${s.price.toLocaleString()}원 × ${units.value}박`
  } else if (r.daycare_hourly) {
    const capped = daycareHours.value * (s.hourly_price ?? 4000) >= s.price
    base = capped
      ? `시간제 ${daycareHours.value}시간 → 종일요금 적용`
      : `${(s.hourly_price ?? 4000).toLocaleString()}원 × ${daycareHours.value}시간`
  } else {
    base = `${s.price.toLocaleString()}원 × 1일`
  }
  return `${base}${rateNote}`
})

onMounted(async () => {
  const id = route.query.id as string | undefined
  if (!id) {
    loading.value = false
    return
  }

  try {
    const [resv, svc, bal] = await Promise.all([
      fetchReservationById(id),
      fetchServiceSettings().catch(() => ({})),
      fetchMyBalance().catch(() => 0)
    ])
    reservation.value = resv
    settings.value = svc
    pointBalance.value = bal
  } catch (e: any) {
    errorMessage.value = e?.message ?? '결제 준비에 실패했습니다.'
  } finally {
    loading.value = false
  }
})

// 결제 준비: 포인트 반영해 결제 레코드 생성
const preparePayment = async () => {
  const id = route.query.id as string
  clampPoints()
  errorMessage.value = ''
  submitting.value = true
  try {
    const payment: any = await createReservationPayment(id, pointsToUse.value)
    if (payment?.status === 'paid' || payment?.amount === 0) {
      // 포인트로 전액 결제 완료
      await router.replace('/mypage/reservations?paid=1')
      return
    }
    paymentInfo.value = {
      paymentId: payment.id,
      amount: payment.amount,
      orderName: `${typeLabel[reservation.value.type]} 예약 (${reservation.value.pets?.name})`
    }
    await nextTick()
  } catch (e: any) {
    errorMessage.value = e?.data?.message ?? e?.message ?? '결제 준비에 실패했습니다.'
  } finally {
    submitting.value = false
  }
}

const handlePay = async () => {
  if (!paymentInfo.value) {
    await preparePayment()
    return
  }
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
    <h1 class="mb-2 text-2xl font-bold text-gray-900">예약 결제</h1>
    <p class="mb-8 text-gray-500">예약을 확정하려면 결제가 필요합니다.</p>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <p v-else-if="!reservation" class="py-8 text-center text-sm text-gray-400">
      결제할 예약을 찾을 수 없습니다.
      <NuxtLink to="/mypage/reservations" class="text-brand-600 hover:underline">내 예약 내역 보기</NuxtLink>
    </p>

    <p v-else-if="reservation.deposit_paid" class="py-8 text-center text-sm text-gray-400">
      이미 결제된 예약입니다.
      <NuxtLink to="/mypage/reservations" class="text-brand-600 hover:underline">내 예약 내역 보기</NuxtLink>
    </p>

    <template v-else>
      <div class="card space-y-4">
        <div class="flex justify-between text-sm text-gray-500">
          <span>서비스</span>
          <span>
            {{ typeLabel[reservation.type] }}
            <template v-if="reservation.type === 'daycare'">({{ reservation.daycare_hourly ? '시간제' : '종일' }})</template>
          </span>
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
        <div class="flex justify-between border-t border-gray-100 pt-4 text-sm text-gray-500">
          <span>예약 금액</span>
          <span class="text-right">
            <span class="block">{{ baseAmount.toLocaleString() }}원</span>
            <span v-if="priceBreakdown" class="block text-xs text-gray-400">{{ priceBreakdown }}</span>
          </span>
        </div>
        <div v-if="pointsToUse > 0" class="flex justify-between text-sm text-brand-600">
          <span>포인트 사용</span>
          <span>-{{ pointsToUse.toLocaleString() }}P</span>
        </div>
        <div class="flex justify-between border-t border-gray-100 pt-3 font-bold text-gray-900">
          <span>최종 결제금액</span>
          <span>{{ payable.toLocaleString() }}원</span>
        </div>
      </div>

      <!-- 포인트 사용 -->
      <div class="card mt-4 space-y-3">
        <div class="flex items-center justify-between">
          <p class="font-semibold text-gray-900">포인트 사용</p>
          <p class="text-sm text-gray-500">보유 <span class="font-semibold text-brand-600">{{ pointBalance.toLocaleString() }}P</span></p>
        </div>
        <template v-if="pointsLocked">
          <p class="text-sm text-gray-600">
            {{ pointsToUse > 0 ? `${pointsToUse.toLocaleString()}P 사용` : '포인트 미사용' }}
          </p>
        </template>
        <template v-else>
          <div class="flex gap-2">
            <input
              v-model.number="pointsToUse"
              type="number"
              min="0"
              :max="maxUsablePoints"
              step="1"
              inputmode="numeric"
              class="input-field flex-1"
              placeholder="0"
              @blur="clampPoints"
            />
            <button type="button" class="btn-secondary shrink-0 !px-4 !py-2 text-sm" @click="useAllPoints">
              전액 사용
            </button>
          </div>
          <p class="text-xs text-gray-400">1P = 1원 · 최대 {{ maxUsablePoints.toLocaleString() }}P 사용 가능</p>
        </template>
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

      <button type="button" class="btn-primary mt-6 w-full" :disabled="submitting" @click="handlePay">
        <template v-if="submitting">처리 중...</template>
        <template v-else-if="paymentInfo">{{ payable.toLocaleString() }}원 결제하기</template>
        <template v-else-if="payable === 0">포인트로 결제 완료하기</template>
        <template v-else>결제 진행하기</template>
      </button>
    </template>
  </div>
</template>
