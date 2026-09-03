<script setup lang="ts">
// 예약금 결제 / 상품 결제가 공용으로 재사용하는 토스페이먼츠 결제 모듈
// 현재 키가 "API 개별연동" 타입이라 결제창(구버전, tossPayments.payment()) 방식을 사용합니다.

const props = defineProps<{
  paymentId: string // 우리 payments.id (토스 orderId로 사용)
  amount: number
  orderName: string
}>()

const config = useRuntimeConfig()
const user = useSupabaseUser()
const { profile } = useAuth()

const requestPayment = async () => {
  const { loadTossPayments } = await import('@tosspayments/tosspayments-sdk')
  const tossPayments = await loadTossPayments(config.public.tossClientKey as string)
  const payment = tossPayments.payment({ customerKey: user.value?.sub ?? 'anonymous' })

  await payment.requestPayment({
    method: 'CARD',
    amount: { currency: 'KRW', value: props.amount },
    orderId: props.paymentId,
    orderName: props.orderName,
    successUrl: `${window.location.origin}/payment/success`,
    failUrl: `${window.location.origin}/payment/fail`,
    customerEmail: user.value?.email ?? undefined,
    customerName: profile.value?.name ?? undefined
  })
}

defineExpose({ requestPayment })
</script>

<template>
  <p class="text-sm text-gray-400">카드 결제 버튼을 누르면 토스페이먼츠 결제창으로 이동합니다.</p>
</template>
