<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const route = useRoute()
const router = useRouter()
const { fetchCart } = useCart()
const { fetchMyOrderById } = useOrders()
const { profile, user } = useAuth()
const { createOrderPayment, resumeOrderPayment } = usePayments()
const { fetchMyBalance } = usePoints()
const { shippingFee: cfgShippingFee, freeShippingThreshold } = useSiteTheme()
const { embed: embedPostcode } = usePostcode()

// 재개 모드에선 주문에 저장된 배송비, 아니면 설정값 기준으로 계산
const resumeShippingFee = ref<number | null>(null)

const cartItems = ref<any[]>([])
const loading = ref(true)
const errorMessage = ref('')
const paymentInfo = ref<{ paymentId: string; amount: number; orderName: string } | null>(null)
const widgetRef = ref<{ requestPayment: () => Promise<void> } | null>(null)
const submitting = ref(false)

// 포인트
const pointBalance = ref(0)
const pointsToUse = ref(0)

// 결제 이어가기(미결제 주문 재개) 모드
const resumeMode = ref(false)
const savedAddress = ref('')
const savedRecipient = ref('')

const shipping = reactive({
  recipientName: '',
  recipientPhone: '',
  postcode: '',
  address: '', // 주소 검색으로 채움
  addressDetail: '', // 수동 입력
  shippingMemo: ''
})

const addressDetailRef = ref<HTMLInputElement | null>(null)
const postcodeBox = ref<HTMLElement | null>(null)
const showPostcode = ref(false)

const fullAddress = computed(() => {
  if (!shipping.address) return ''
  const zip = shipping.postcode ? `[${shipping.postcode}] ` : ''
  return `${zip}${shipping.address} ${shipping.addressDetail}`.trim()
})

const findAddress = async () => {
  if (paymentInfo.value) return
  errorMessage.value = ''
  showPostcode.value = true
  await nextTick()
  if (!postcodeBox.value) return
  try {
    await embedPostcode(
      postcodeBox.value,
      ({ zonecode, address }) => {
        shipping.postcode = zonecode
        shipping.address = address
        showPostcode.value = false
        nextTick(() => addressDetailRef.value?.focus())
      },
      () => {
        showPostcode.value = false
      }
    )
  } catch (e: any) {
    showPostcode.value = false
    errorMessage.value = e?.message ?? '주소 검색에 실패했습니다.'
  }
}

const total = computed(() => cartItems.value.reduce((sum, item) => sum + item.products.price * item.quantity, 0))

const shippingFee = computed(() => {
  if (resumeShippingFee.value != null) return resumeShippingFee.value
  const th = freeShippingThreshold.value
  if (th > 0 && total.value >= th) return 0
  return cfgShippingFee.value
})
const isFreeShipping = computed(() => shippingFee.value === 0)
const grandTotal = computed(() => total.value + shippingFee.value)

const maxUsablePoints = computed(() => Math.min(pointBalance.value, grandTotal.value))
const payable = computed(() => Math.max(0, grandTotal.value - pointsToUse.value))
const pointsLocked = computed(() => resumeMode.value || !!paymentInfo.value)

const clampPoints = () => {
  let v = Math.floor(Number(pointsToUse.value) || 0)
  if (v < 0) v = 0
  if (v > maxUsablePoints.value) v = maxUsablePoints.value
  pointsToUse.value = v
}
const useAllPoints = () => {
  pointsToUse.value = maxUsablePoints.value
}

const orderName = computed(() =>
  cartItems.value.length > 1
    ? `${cartItems.value[0]?.products.name} 외 ${cartItems.value.length - 1}건`
    : (cartItems.value[0]?.products.name ?? '주문')
)

onMounted(async () => {
  const resumeId = route.query.resume as string | undefined
  try {
    if (resumeId) {
      const order = await fetchMyOrderById(resumeId)
      if (!order) {
        errorMessage.value = '주문을 찾을 수 없습니다.'
        return
      }
      if (order.status !== 'pending') {
        await router.replace('/mypage/orders')
        return
      }
      resumeMode.value = true
      cartItems.value = (order.order_items ?? []).map((it: any) => ({
        id: it.id,
        quantity: it.quantity,
        products: {
          id: it.product_id,
          name: it.products?.name ?? '상품',
          price: it.price_at_order,
          image_url: it.products?.image_url
        }
      }))
      savedAddress.value = order.shipping_address ?? ''
      savedRecipient.value = [order.recipient_name, order.recipient_phone].filter(Boolean).join(' · ')
      pointsToUse.value = order.points_used ?? 0
      resumeShippingFee.value = order.shipping_fee ?? 0

      const payment = await resumeOrderPayment(resumeId)
      if (!payment) {
        errorMessage.value = '결제 정보가 만료되었습니다. 장바구니에서 다시 주문해주세요.'
        return
      }
      paymentInfo.value = { paymentId: payment.id, amount: payment.amount, orderName: orderName.value }
    } else {
      cartItems.value = await fetchCart()
      shipping.recipientName = profile.value?.name ?? ''
      shipping.recipientPhone = profile.value?.phone ?? ''
      shipping.postcode = profile.value?.postcode ?? ''
      shipping.address = profile.value?.address ?? ''
      shipping.addressDetail = profile.value?.address_detail ?? ''
    }
    pointBalance.value = await fetchMyBalance().catch(() => 0)
  } catch (e: any) {
    errorMessage.value = e?.message ?? '불러오는 데 실패했습니다.'
  } finally {
    loading.value = false
  }
})

const validateShipping = () => {
  if (!shipping.recipientName.trim()) return '수령인 이름을 입력해주세요.'
  if (!shipping.recipientPhone.trim()) return '수령인 연락처를 입력해주세요.'
  if (!shipping.address.trim()) return '주소 찾기로 배송지 주소를 선택해주세요.'
  if (!shipping.addressDetail.trim()) return '상세주소를 입력해주세요.'
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
    clampPoints()
    submitting.value = true
    try {
      const { paymentId, payableAmount, fullyPaid } = await createOrderPayment(
        cartItems.value.map((item) => ({ productId: item.products.id, quantity: item.quantity })),
        {
          recipientName: shipping.recipientName,
          recipientPhone: shipping.recipientPhone,
          shippingAddress: fullAddress.value,
          shippingMemo: shipping.shippingMemo
        },
        pointsToUse.value
      )
      if (fullyPaid) {
        // 포인트로 전액 결제 완료 → 결제창 없이 바로 완료
        await router.replace('/mypage/orders?paid=1')
        return
      }
      paymentInfo.value = { paymentId, amount: payableAmount, orderName: orderName.value }
      await nextTick()
    } catch (e: any) {
      errorMessage.value = e?.data?.message ?? e?.message ?? '주문 생성에 실패했습니다.'
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
    <p class="mb-8 text-gray-500">
      {{ resumeMode ? '미결제 주문의 결제를 이어서 진행합니다.' : '배송지를 입력하고 결제를 진행해주세요.' }}
    </p>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <p v-else-if="errorMessage && cartItems.length === 0" class="py-8 text-center text-sm text-gray-400">
      {{ errorMessage }}
      <NuxtLink to="/shop" class="mt-2 block text-brand-600 hover:underline">쇼핑몰로 가기</NuxtLink>
    </p>

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
        <div class="flex justify-between border-t border-gray-100 pt-4 text-sm text-gray-500">
          <span>상품 금액</span>
          <span>{{ total.toLocaleString() }}원</span>
        </div>
        <div class="flex justify-between text-sm text-gray-500">
          <span>배송비</span>
          <span v-if="isFreeShipping" class="text-brand-600">무료</span>
          <span v-else>{{ shippingFee.toLocaleString() }}원</span>
        </div>
        <p
          v-if="!resumeMode && !isFreeShipping && freeShippingThreshold > 0"
          class="text-xs text-gray-400"
        >
          {{ (freeShippingThreshold - total).toLocaleString() }}원 더 담으면 무료배송
        </p>
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

      <!-- 배송지: 신규 주문이면 입력 폼, 이어가기면 저장된 배송지 표시 -->
      <div class="card mt-4 space-y-4">
        <p class="font-semibold text-gray-900">배송지 정보</p>

        <template v-if="resumeMode">
          <p class="text-sm text-gray-600">{{ savedRecipient || '-' }}</p>
          <p class="text-sm text-gray-600">{{ savedAddress || '배송지 정보 없음' }}</p>
        </template>

        <template v-else>
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
            <label class="label-field" for="ship-postcode">주소</label>
            <div class="flex gap-2">
              <input
                id="ship-postcode"
                :value="shipping.postcode"
                type="text"
                class="input-field flex-1"
                placeholder="우편번호"
                readonly
              />
              <button
                type="button"
                class="btn-secondary shrink-0 !px-4 !py-2 text-sm"
                :disabled="!!paymentInfo"
                @click="findAddress"
              >
                주소 찾기
              </button>
            </div>
            <div
              v-show="showPostcode"
              ref="postcodeBox"
              class="mt-2 h-[420px] w-full overflow-hidden rounded-lg border border-gray-200"
            />
            <input
              :value="shipping.address"
              type="text"
              class="input-field mt-2"
              placeholder="도로명/지번 주소 (주소 찾기 버튼으로 선택)"
              readonly
            />
            <input
              ref="addressDetailRef"
              v-model="shipping.addressDetail"
              type="text"
              class="input-field mt-2"
              :disabled="!!paymentInfo"
              placeholder="상세주소 (동/호수 등)"
            />
          </div>
          <div>
            <label class="label-field" for="ship-memo">배송 메모 (선택)</label>
            <input id="ship-memo" v-model="shipping.shippingMemo" type="text" class="input-field" :disabled="!!paymentInfo" placeholder="부재 시 문 앞에 놓아주세요" />
          </div>
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
      <p v-if="user" class="mt-2 text-center text-xs text-gray-400">{{ user.email }}</p>
    </template>
  </div>
</template>
