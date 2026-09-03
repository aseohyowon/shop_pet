<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchCart } = useCart()
const { profile, user } = useAuth()
const { createOrderPayment } = usePayments()

const cartItems = ref<any[]>([])
const loading = ref(true)
const errorMessage = ref('')
const paymentInfo = ref<{ paymentId: string; amount: number; orderName: string } | null>(null)
const widgetRef = ref<{ requestPayment: () => Promise<void> } | null>(null)
const submitting = ref(false)

const shipping = reactive({
  recipientName: '',
  recipientPhone: '',
  shippingAddress: '',
  shippingMemo: ''
})

const total = computed(() => cartItems.value.reduce((sum, item) => sum + item.products.price * item.quantity, 0))

onMounted(async () => {
  try {
    cartItems.value = await fetchCart()
    shipping.recipientName = profile.value?.name ?? ''
    shipping.recipientPhone = profile.value?.phone ?? ''
  } catch (e: any) {
    errorMessage.value = e?.message ?? '장바구니를 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
})

const orderName = computed(() =>
  cartItems.value.length > 1
    ? `${cartItems.value[0]?.products.name} 외 ${cartItems.value.length - 1}건`
    : (cartItems.value[0]?.products.name ?? '주문')
)

const validateShipping = () => {
  if (!shipping.recipientName.trim()) return '수령인 이름을 입력해주세요.'
  if (!shipping.recipientPhone.trim()) return '수령인 연락처를 입력해주세요.'
  if (!shipping.shippingAddress.trim()) return '배송지 주소를 입력해주세요.'
  return ''
}

const handlePay = async () => {
  errorMessage.value = ''

  // 아직 주문 생성 전이면: 배송지 검증 → 주문+결제 레코드 생성
  if (!paymentInfo.value) {
    const msg = validateShipping()
    if (msg) {
      errorMessage.value = msg
      return
    }
    submitting.value = true
    try {
      const { paymentId, totalAmount } = await createOrderPayment(
        cartItems.value.map((item) => ({ productId: item.products.id, quantity: item.quantity })),
        { ...shipping }
      )
      paymentInfo.value = { paymentId, amount: totalAmount, orderName: orderName.value }
      await nextTick()
    } catch (e: any) {
      errorMessage.value = e?.message ?? '주문 생성에 실패했습니다.'
      submitting.value = false
      return
    }
  }

  // 결제창 호출
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
    <h1 class="mb-2 text-2xl font-bold text-gray-900">주문 결제</h1>
    <p class="mb-8 text-gray-500">배송지를 입력하고 결제를 진행해주세요.</p>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <p v-else-if="cartItems.length === 0" class="py-8 text-center text-sm text-gray-400">
      장바구니가 비어있습니다.
      <NuxtLink to="/shop" class="text-brand-600 hover:underline">쇼핑몰로 가기</NuxtLink>
    </p>

    <template v-else>
      <!-- 주문 상품 -->
      <div class="card space-y-3">
        <div v-for="item in cartItems" :key="item.id" class="flex justify-between text-sm text-gray-500">
          <span>{{ item.products.name }} × {{ item.quantity }}</span>
          <span>{{ (item.products.price * item.quantity).toLocaleString() }}원</span>
        </div>
        <div class="flex justify-between border-t border-gray-100 pt-4 font-bold text-gray-900">
          <span>총 결제금액</span>
          <span>{{ total.toLocaleString() }}원</span>
        </div>
      </div>

      <!-- 배송지 -->
      <div class="card mt-4 space-y-4">
        <p class="font-semibold text-gray-900">배송지 정보</p>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="label-field" for="ship-name">수령인</label>
            <input id="ship-name" v-model="shipping.recipientName" type="text" class="input-field" :disabled="!!paymentInfo" placeholder="홍길동" />
          </div>
          <div>
            <label class="label-field" for="ship-phone">연락처</label>
            <input id="ship-phone" v-model="shipping.recipientPhone" type="tel" class="input-field" :disabled="!!paymentInfo" placeholder="010-0000-0000" />
          </div>
        </div>
        <div>
          <label class="label-field" for="ship-addr">주소</label>
          <input id="ship-addr" v-model="shipping.shippingAddress" type="text" class="input-field" :disabled="!!paymentInfo" placeholder="도로명 주소 + 상세주소" />
        </div>
        <div>
          <label class="label-field" for="ship-memo">배송 메모 (선택)</label>
          <input id="ship-memo" v-model="shipping.shippingMemo" type="text" class="input-field" :disabled="!!paymentInfo" placeholder="부재 시 문 앞에 놓아주세요" />
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

      <button type="button" class="btn-primary mt-6 w-full" :disabled="submitting" @click="handlePay">
        {{ submitting ? '처리 중...' : paymentInfo ? `${total.toLocaleString()}원 결제하기` : '결제 진행하기' }}
      </button>
      <p v-if="user" class="mt-2 text-center text-xs text-gray-400">{{ user.email }}</p>
    </template>
  </div>
</template>
