<script setup lang="ts">
import type { Product } from '~/types/database.types'

const route = useRoute()
const router = useRouter()
const user = useSupabaseUser()
const { fetchProductById } = useProducts()
const { addToCart } = useCart()

const product = ref<Product | null>(null)
const loading = ref(true)
const quantity = ref(1)
const message = ref('')

onMounted(async () => {
  try {
    product.value = await fetchProductById(route.params.id as string)
  } finally {
    loading.value = false
  }
})

const goToLoginIfNeeded = () => {
  if (!user.value) {
    router.push(`/login?redirect=${encodeURIComponent(route.fullPath)}`)
    return false
  }
  return true
}

const handleAddToCart = async () => {
  if (!product.value || !goToLoginIfNeeded()) return
  await addToCart(product.value.id, quantity.value, product.value.stock)
  message.value = '장바구니에 담았습니다.'
}

const handleBuyNow = async () => {
  if (!product.value || !goToLoginIfNeeded()) return
  await addToCart(product.value.id, quantity.value, product.value.stock)
  await router.push('/cart')
}
</script>

<template>
  <div class="container-page py-12">
    <p v-if="loading" class="py-16 text-center text-sm text-gray-400">불러오는 중...</p>

    <div v-else-if="product" class="grid gap-10 lg:grid-cols-2">
      <div class="flex h-80 items-center justify-center overflow-hidden rounded-xl bg-brand-50">
        <img v-if="product.image_url" :src="product.image_url" :alt="product.name" class="h-full w-full object-cover" />
        <span v-else class="text-8xl">🐾</span>
      </div>

      <div>
        <p class="text-sm text-gray-400">{{ product.category || '기타' }}</p>
        <h1 class="mb-2 text-2xl font-bold text-gray-900">{{ product.name }}</h1>
        <p class="mb-4 text-2xl font-bold text-brand-600">{{ product.price.toLocaleString() }}원</p>
        <p class="mb-6 text-sm text-gray-500">{{ product.description }}</p>
        <p class="mb-6 text-sm" :class="product.stock === 0 ? 'text-red-500' : 'text-gray-400'">
          {{ product.stock === 0 ? '품절된 상품입니다' : `재고 ${product.stock}개 남음` }}
        </p>

        <div class="mb-6 flex items-center gap-3">
          <label class="label-field mb-0" for="quantity">수량</label>
          <input
            id="quantity"
            v-model.number="quantity"
            type="number"
            min="1"
            :max="Math.max(product.stock, 1)"
            class="input-field w-24"
            :disabled="product.stock === 0"
          />
        </div>

        <p v-if="message" class="mb-3 text-sm text-green-600">{{ message }}</p>

        <div class="flex gap-3">
          <button type="button" class="btn-secondary flex-1" :disabled="product.stock === 0" @click="handleAddToCart">
            장바구니 담기
          </button>
          <button type="button" class="btn-primary flex-1" :disabled="product.stock === 0" @click="handleBuyNow">
            바로 구매
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
