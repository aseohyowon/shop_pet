<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchCart, updateQuantity, removeFromCart } = useCart()
const { shippingFee: cfgShippingFee, freeShippingThreshold } = useSiteTheme()

const cartItems = ref<any[]>([])
const loading = ref(true)

const load = async () => {
  loading.value = true
  try {
    cartItems.value = await fetchCart()
  } finally {
    loading.value = false
  }
}

onMounted(load)

const total = computed(() =>
  cartItems.value.reduce((sum, item) => sum + item.products.price * item.quantity, 0)
)
const shipFee = computed(() => {
  if (cartItems.value.length === 0) return 0
  const th = freeShippingThreshold.value
  if (th > 0 && total.value >= th) return 0
  return cfgShippingFee.value
})
const grandTotal = computed(() => total.value + shipFee.value)

const handleQuantityChange = async (item: any, value: number) => {
  const clamped = Math.min(Math.max(value, 1), item.products.stock)
  await updateQuantity(item.id, clamped)
  await load()
}

const handleRemove = async (item: any) => {
  await removeFromCart(item.id)
  await load()
}
</script>

<template>
  <div class="container-page py-12">
    <h1 class="mb-8 text-2xl font-bold text-gray-900">장바구니</h1>

    <p v-if="loading" class="py-16 text-center text-sm text-gray-400">불러오는 중...</p>

    <div v-else class="grid gap-8 lg:grid-cols-3">
      <div class="space-y-4 lg:col-span-2">
        <div v-for="item in cartItems" :key="item.id" class="card flex items-center gap-4">
          <div class="flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-brand-50">
            <img v-if="item.products.image_url" :src="item.products.image_url" :alt="item.products.name" class="h-full w-full object-cover" />
            <span v-else class="text-2xl">🐾</span>
          </div>
          <div class="flex-1">
            <p class="font-semibold text-gray-900">{{ item.products.name }}</p>
            <p class="text-sm text-gray-400">{{ item.products.price.toLocaleString() }}원</p>
          </div>
          <input
            type="number"
            min="1"
            :max="item.products.stock"
            :value="item.quantity"
            class="input-field w-20"
            @change="handleQuantityChange(item, Number(($event.target as HTMLInputElement).value))"
          />
          <button type="button" class="text-sm text-gray-400 hover:text-red-500" @click="handleRemove(item)">삭제</button>
        </div>

        <p v-if="cartItems.length === 0" class="py-16 text-center text-gray-400">
          장바구니가 비어있습니다.
        </p>
      </div>

      <div class="lg:col-span-1">
        <div class="card sticky top-24 space-y-3">
          <p class="font-semibold text-gray-900">결제 요약</p>
          <div class="flex justify-between text-sm text-gray-500">
            <span>상품 합계</span>
            <span>{{ total.toLocaleString() }}원</span>
          </div>
          <div class="flex justify-between text-sm text-gray-500">
            <span>배송비</span>
            <span v-if="shipFee === 0" class="text-brand-600">무료</span>
            <span v-else>{{ shipFee.toLocaleString() }}원</span>
          </div>
          <p
            v-if="cartItems.length > 0 && shipFee > 0 && freeShippingThreshold > 0"
            class="text-xs text-gray-400"
          >
            {{ (freeShippingThreshold - total).toLocaleString() }}원 더 담으면 무료배송
          </p>
          <div class="flex justify-between border-t border-gray-100 pt-3 font-bold text-gray-900">
            <span>총 결제금액</span>
            <span>{{ grandTotal.toLocaleString() }}원</span>
          </div>
          <NuxtLink
            to="/checkout/order"
            class="btn-primary block w-full text-center"
            :class="cartItems.length === 0 ? 'pointer-events-none opacity-50' : ''"
          >
            주문하기
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>
