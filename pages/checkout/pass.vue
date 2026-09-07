<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const router = useRouter()
const { fetchPassProducts } = usePasses()
const { createPassPayment, resumePassPayment } = usePayments()
const { fetchMyBalance } = usePoints()

const product = ref<any | null>(null)
const loading = ref(true)
const errorMessage = ref('')
const submitting = ref(false)

const pointBalance = ref(0)
const pointsToUse = ref(0)
const paymentInfo = ref<{ paymentId: string; amount: number; orderName: string } | null>(null)
const widgetRef = ref<{ requestPayment: () => Promise<void> } | null>(null)

const price = computed(() => product.value?.price ?? 0)
const maxUsablePoints = computed(() => Math.min(pointBalance.value, price.value))
const payable = computed(() => Math.max(0, price.value - pointsToUse.value))
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

onMounted(async () => {
  const itemId = route.query.item as string | undefined
  try {
    const [products, bal] = await Promise.all([fetchPassProducts(), fetchMyBalance().catch(() => 0)])
    pointBalance.value = bal
    product.value = products.find((p) => p.id === itemId) ?? null
    if (!product.value) errorMessage.value = '정기권 상품을 찾을 수 없습니다.'
  } catch (e: any) {
    errorMessage.value = e?.message ?? '불러오는 데 실패했습니다.'
  } finally {
    loading.value = false
  }
})

const handlePay = async () => {
  errorMessage.value = ''
  if (!paymentInfo.value) {
    if (!product.value) return
    clampPoints()
    submitting.value = true
    try {
      const { paymentId, payableAmount, fullyPaid } = await createPassPayment(product.value.id, pointsToUse.value)
      if (fullyPaid) {
        await router.replace('/mypage/passes?paid=1')
        return
      }
      paymentInfo.value = { paymentId, amount: payableAmount, orderName: product.value.name }
      await nextTick()
    } catch (e: any) {
      errorMessage.value = e?.data?.message ?? e?.message ?? '결제 준비에 실패했습니다.'
      submitting.value = false
      return
    }
  }
  try {
    await widgetRef.value?.requestPayment()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '결제 요청 중 오류가 발생했습니다.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="container-page max-w-lg py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">정기권 구매</h1>
    <p class="mb-8 text-gray-500">구매한 정기권은 종일 데이케어 예약 시 1회씩 차감됩니다.</p>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="!product" class="py-8 text-center text-sm text-gray-400">
      {{ errorMessage || '정기권 상품을 찾을 수 없습니다.' }}
      <NuxtLink to="/mypage/passes" class="mt-2 block text-brand-600 hover:underline">정기권 내역으로</NuxtLink>
    </p>

    <template v-else>
      <div class="card space-y-3">
        <div class="flex items-start justify-between">
          <div>
            <p class="font-semibold text-gray-900">{{ product.name }}</p>
            <p v-if="product.note" class="text-sm text-gray-400">{{ product.note }}</p>
          </div>
          <p class="text-lg font-bold text-brand-600">{{ price.toLocaleString() }}원</p>
        </div>
        <div v-if="pointsToUse > 0" class="flex justify-between border-t border-gray-100 pt-3 text-sm text-brand-600">
          <span>포인트 사용</span>
          <span>-{{ pointsToUse.toLocaleString() }}P</span>
        </div>
        <div class="flex justify-between border-t border-gray-100 pt-3 font-bold text-gray-900">
          <span>최종 결제금액</span>
          <span>{{ payable.toLocaleString() }}원</span>
        </div>
      </div>

      <!-- 포인트 -->
      <div class="card mt-4 space-y-3">
        <div class="flex items-center justify-between">
          <p class="font-semibold text-gray-900">포인트 사용</p>
          <p class="text-sm text-gray-500">보유 <span class="font-semibold text-brand-600">{{ pointBalance.toLocaleString() }}P</span></p>
        </div>
        <template v-if="pointsLocked">
          <p class="text-sm text-gray-600">{{ pointsToUse > 0 ? `${pointsToUse.toLocaleString()}P 사용` : '포인트 미사용' }}</p>
        </template>
        <template v-else>
          <div class="flex gap-2">
            <input
              v-model.number="pointsToUse"
              type="number"
              min="0"
              :max="maxUsablePoints"
              class="input-field flex-1"
              placeholder="0"
              @blur="clampPoints"
            />
            <button type="button" class="btn-secondary shrink-0 !px-4 !py-2 text-sm" @click="useAllPoints">전액 사용</button>
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
        <template v-else-if="payable === 0">포인트로 구매 완료하기</template>
        <template v-else>결제 진행하기</template>
      </button>
    </template>
  </div>
</template>
