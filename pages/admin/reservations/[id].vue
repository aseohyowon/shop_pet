<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const route = useRoute()
const router = useRouter()
const { fetchReservationById, updateReservationStatus } = useReservations()
const { fetchPaidPayment } = usePayments()
const { cancelPayment } = useRefunds()

const reservation = ref<any | null>(null)
const payment = ref<any | null>(null)
const loading = ref(true)
const errorMessage = ref('')

const showRefund = ref(false)
const refundReason = ref('')
const refundAmount = ref(0)
const refunding = ref(false)

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const statusLabel: Record<string, string> = {
  pending: '승인 대기',
  confirmed: '확정',
  rejected: '거절됨',
  cancelled: '취소됨',
  completed: '완료'
}
const toHHMM = (t: string) => t?.slice(0, 5)

const vaccStatusLabel = (no: number): string => {
  const s = reservation.value?.pets?.vaccinations?.[String(no)]
  return s === 'admin' ? `관리자확인 ${no}` : s === 'member' ? `회원확인 ${no}` : '미접종'
}

const load = async () => {
  reservation.value = await fetchReservationById(route.params.id as string)
  if (reservation.value?.deposit_paid) {
    payment.value = await fetchPaidPayment('reservation', reservation.value.id).catch(() => null)
    refundAmount.value = payment.value ? payment.value.amount - payment.value.refunded_amount : 0
  }
}

onMounted(async () => {
  try {
    await load()
  } finally {
    loading.value = false
  }
})

const handleAction = async (status: 'confirmed' | 'rejected') => {
  await updateReservationStatus(route.params.id as string, status)
  await router.push('/admin/reservations')
}

const doRefund = async () => {
  if (!payment.value) return
  refunding.value = true
  errorMessage.value = ''
  try {
    await cancelPayment({
      paymentId: payment.value.id,
      reason: refundReason.value || '관리자 예약 취소',
      cancelAmount: Math.max(0, Math.round(refundAmount.value))
    })
    showRefund.value = false
    await load()
  } catch (e: any) {
    errorMessage.value = e?.data?.statusMessage ?? e?.message ?? '환불 처리에 실패했습니다.'
  } finally {
    refunding.value = false
  }
}

const cancelUnpaid = async () => {
  if (!confirm('이 예약을 취소하시겠어요?')) return
  await updateReservationStatus(route.params.id as string, 'cancelled')
  await load()
}

// 0원 결제(정기권/포인트 전액) 예약 취소 — 서버가 정기권 회차/포인트 복원 처리
const cancelPaidZero = async () => {
  if (!payment.value) return
  if (!confirm('이 예약을 취소하시겠어요? (정기권/포인트는 복원됩니다)')) return
  refunding.value = true
  errorMessage.value = ''
  try {
    await cancelPayment({ paymentId: payment.value.id, reason: '관리자 예약 취소', cancelAmount: 0 })
    await load()
  } catch (e: any) {
    errorMessage.value = e?.data?.statusMessage ?? e?.message ?? '취소에 실패했습니다.'
  } finally {
    refunding.value = false
  }
}
</script>

<template>
  <div>
    <NuxtLink to="/admin/reservations" class="mb-4 inline-block text-sm text-gray-500 hover:text-gray-700">
      ← 예약 목록으로
    </NuxtLink>
    <h1 class="mb-6 text-2xl font-bold text-gray-900">예약 상세</h1>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <template v-else-if="reservation">
      <div class="grid gap-6 lg:grid-cols-2">
        <div class="card space-y-2">
          <p class="mb-2 font-semibold text-gray-900">예약 정보</p>
          <p class="text-sm text-gray-600">
            서비스: {{ typeLabel[reservation.type] }}<template v-if="reservation.type === 'daycare'"> ({{ reservation.daycare_hourly ? '시간제' : '종일' }})</template>
          </p>
          <p class="text-sm text-gray-600">
            기간: {{ reservation.start_date }} {{ toHHMM(reservation.start_time) }} ~
            {{ reservation.end_date }} {{ toHHMM(reservation.end_time) }}
          </p>
          <p class="text-sm text-gray-600">상태: {{ statusLabel[reservation.status] ?? reservation.status }}</p>
          <p class="text-sm text-gray-600">요청사항: {{ reservation.memo || '-' }}</p>
          <p v-if="(reservation.reservation_options ?? []).length" class="text-sm text-gray-600">
            추가 옵션:
            {{ reservation.reservation_options.map((o) => `${o.name}${o.quantity > 1 ? ` ×${o.quantity}` : ''}`).join(', ') }}
          </p>
          <p class="text-sm text-gray-600">
            약관 동의:
            <span :class="reservation.terms_agreed_at ? 'text-green-600' : 'text-red-500'">
              {{ reservation.terms_agreed_at ? `완료 (${new Date(reservation.terms_agreed_at).toLocaleString('ko-KR')})` : '미동의' }}
            </span>
          </p>
          <p class="mb-2 mt-4 font-semibold text-gray-900">보호자 정보</p>
          <p class="text-sm text-gray-600">이름: {{ reservation.profiles?.name }}</p>
          <p class="text-sm text-gray-600">연락처: {{ reservation.profiles?.phone }}</p>
          <p class="text-sm text-gray-600">이메일: {{ reservation.profiles?.email }}</p>
        </div>

        <div class="card space-y-2">
          <p class="mb-2 font-semibold text-gray-900">반려동물 정보</p>
          <p class="text-sm text-gray-600">이름: {{ reservation.pets?.name }}</p>
          <p class="text-sm text-gray-600">견종: {{ reservation.pets?.breed || '-' }}</p>
          <p class="text-sm text-gray-600">나이: {{ reservation.pets?.age ?? '-' }}세</p>
          <p class="text-sm text-gray-600">체중: {{ reservation.pets?.weight ?? '-' }}kg</p>
          <p class="text-sm text-gray-600">동물등록번호: {{ reservation.pets?.registration_no || '-' }}</p>
          <div class="pt-1">
            <p class="mb-1.5 text-sm text-gray-600">예방접종 현황</p>
            <div class="flex flex-wrap gap-1.5">
              <span
                v-for="no in [1, 2, 3, 4, 5]"
                :key="no"
                class="rounded-full px-2 py-0.5 text-xs font-semibold"
                :class="reservation.pets?.vaccinations?.[String(no)] === 'admin'
                  ? 'bg-green-100 text-green-700'
                  : reservation.pets?.vaccinations?.[String(no)] === 'member'
                    ? 'bg-amber-100 text-amber-700'
                    : 'bg-gray-100 text-gray-400'"
              >
                {{ vaccStatusLabel(no) }}
              </span>
            </div>
            <p class="mt-1.5 text-xs text-gray-400">
              규정 동의: {{ reservation.pets?.rules_agreed_at ? '완료' : '미확인' }}
            </p>
          </div>
          <p class="text-sm text-gray-600">특이사항: {{ reservation.pets?.notes || '-' }}</p>
        </div>
      </div>

      <!-- 결제 / 취소·환불 -->
      <div class="card mt-6">
        <p class="mb-3 font-semibold text-gray-900">결제 · 취소</p>
        <dl v-if="payment" class="mb-4 grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
          <div><dt class="text-gray-400">결제 금액</dt><dd class="text-gray-800">{{ payment.method === '정기권' ? '정기권 1회' : `${payment.amount.toLocaleString()}원` }}</dd></div>
          <div><dt class="text-gray-400">결제 수단</dt><dd class="text-gray-800">{{ payment.method || '-' }}</dd></div>
          <div v-if="payment.points_used > 0"><dt class="text-gray-400">포인트 사용</dt><dd class="text-brand-600">{{ payment.points_used.toLocaleString() }}P</dd></div>
          <div v-if="payment.refunded_amount > 0" class="col-span-2">
            <dt class="text-gray-400">환불됨</dt>
            <dd class="font-semibold text-red-500">{{ payment.refunded_amount.toLocaleString() }}원</dd>
          </div>
        </dl>
        <p v-else class="mb-4 text-sm text-gray-400">결제되지 않은 예약입니다.</p>

        <div class="flex flex-wrap gap-3">
          <template v-if="reservation.status === 'pending'">
            <button type="button" class="btn-primary" @click="handleAction('confirmed')">예약 승인</button>
            <button type="button" class="btn-secondary" @click="handleAction('rejected')">예약 거절</button>
          </template>

          <template v-if="reservation.status !== 'cancelled' && reservation.status !== 'rejected'">
            <button
              v-if="payment && payment.amount > 0 && payment.refunded_amount < payment.amount"
              type="button"
              class="btn-secondary !border-red-200 !text-red-500"
              @click="showRefund = !showRefund"
            >
              예약 취소 + 환불
            </button>
            <button
              v-else-if="payment && payment.amount === 0"
              type="button"
              class="btn-secondary !border-red-200 !text-red-500"
              :disabled="refunding"
              @click="cancelPaidZero"
            >
              예약 취소{{ payment.method === '정기권' ? ' (정기권 복원)' : '' }}
            </button>
            <button
              v-else-if="!payment"
              type="button"
              class="btn-secondary !border-red-200 !text-red-500"
              @click="cancelUnpaid"
            >
              예약 취소
            </button>
          </template>
        </div>

        <div v-if="showRefund && payment" class="mt-4 space-y-3 rounded-lg border border-gray-200 p-4">
          <div>
            <label class="label-field">환불 금액 (원)</label>
            <input v-model.number="refundAmount" type="number" min="0" :max="payment.amount - payment.refunded_amount" class="input-field" />
            <p class="mt-1 text-xs text-gray-400">
              최대 {{ (payment.amount - payment.refunded_amount).toLocaleString() }}원.
              환불 규정에 따라 일부만 돌려줄 수 있습니다.
            </p>
          </div>
          <div>
            <label class="label-field">사유</label>
            <input v-model="refundReason" type="text" class="input-field" placeholder="예: 고객 요청" />
          </div>
          <div class="flex gap-2">
            <button type="button" class="btn-secondary flex-1 !py-2 text-sm" @click="showRefund = false">닫기</button>
            <button type="button" class="btn-primary flex-1 !py-2 text-sm" :disabled="refunding" @click="doRefund">
              {{ refunding ? '처리 중...' : '취소 + 환불 실행' }}
            </button>
          </div>
        </div>

        <p v-if="errorMessage" class="mt-3 text-sm text-red-500">{{ errorMessage }}</p>
      </div>
    </template>
  </div>
</template>
