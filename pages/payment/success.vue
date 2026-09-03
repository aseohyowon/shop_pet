<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'auth' })

const route = useRoute()
const router = useRouter()
const { confirmPayment } = usePayments()

const status = ref<'confirming' | 'error'>('confirming')
const errorMessage = ref('')

onMounted(async () => {
  const paymentId = route.query.orderId as string
  const paymentKey = route.query.paymentKey as string
  const amount = Number(route.query.amount)

  if (!paymentId || !paymentKey || !amount) {
    status.value = 'error'
    errorMessage.value = '결제 정보가 올바르지 않습니다.'
    return
  }

  try {
    const result = await confirmPayment({ paymentId, paymentKey, amount })
    const destination = result.targetType === 'order' ? '/mypage/orders?paid=1' : '/mypage/reservations?paid=1'
    await router.replace(destination)
  } catch (e: any) {
    status.value = 'error'
    errorMessage.value = e?.data?.statusMessage ?? e?.message ?? '결제 승인에 실패했습니다.'
  }
})
</script>

<template>
  <div class="card text-center">
    <template v-if="status === 'confirming'">
      <p class="text-2xl">⏳</p>
      <p class="mt-3 text-sm text-gray-500">결제를 확인하고 있습니다...</p>
    </template>
    <template v-else>
      <p class="text-2xl">⚠️</p>
      <p class="mt-3 font-semibold text-gray-900">결제 승인에 실패했습니다</p>
      <p class="mt-1 text-sm text-gray-500">{{ errorMessage }}</p>
      <NuxtLink to="/" class="btn-secondary mt-6 inline-block">홈으로</NuxtLink>
    </template>
  </div>
</template>
