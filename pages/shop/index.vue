<script setup lang="ts">
import type { Product } from '~/types/database.types'

const { fetchProducts } = useProducts()
const { fetchActiveCategories } = useCategories()
const { isWarm } = useSiteTheme()

const products = ref<Product[]>([])
const managedCategories = ref<string[]>([])
const loading = ref(true)

// 기본 테마: 단일 카테고리 선택
const selectedCategory = ref<string>('all')
// Warm 테마: 다중 카테고리 + 정렬
const checkedCategories = ref<string[]>([])
const sortBy = ref<'recommended' | 'price-asc' | 'price-desc' | 'newest'>('recommended')
const visibleCount = ref(9)

onMounted(async () => {
  try {
    const [productList, cats] = await Promise.all([
      fetchProducts(),
      fetchActiveCategories().catch(() => [])
    ])
    products.value = productList
    managedCategories.value = cats.map((c) => c.name)
  } finally {
    loading.value = false
  }
})

// 관리자가 등록한 '노출 중' 카테고리를 그대로(순서대로) 사용, 없으면 상품에서 추출
const realCategories = computed(() => {
  if (managedCategories.value.length > 0) {
    const extra = [...new Set(products.value.map((p) => p.category).filter(Boolean) as string[])]
      .filter((c) => !managedCategories.value.includes(c))
    return [...managedCategories.value, ...extra]
  }
  return [...new Set(products.value.map((p) => p.category).filter(Boolean) as string[])]
})

const categories = computed(() => ['all', ...realCategories.value])

const filteredProducts = computed(() =>
  selectedCategory.value === 'all'
    ? products.value
    : products.value.filter((p) => p.category === selectedCategory.value)
)

// Warm 전용
const warmFiltered = computed(() => {
  let list = products.value
  if (checkedCategories.value.length > 0) {
    list = list.filter((p) => p.category && checkedCategories.value.includes(p.category))
  }
  const sorted = [...list]
  if (sortBy.value === 'price-asc') sorted.sort((a, b) => a.price - b.price)
  else if (sortBy.value === 'price-desc') sorted.sort((a, b) => b.price - a.price)
  else if (sortBy.value === 'newest') sorted.sort((a, b) => (a.created_at < b.created_at ? 1 : -1))
  return sorted
})

const warmVisible = computed(() => warmFiltered.value.slice(0, visibleCount.value))

const toggleCategory = (c: string) => {
  const i = checkedCategories.value.indexOf(c)
  if (i === -1) checkedCategories.value.push(c)
  else checkedCategories.value.splice(i, 1)
  visibleCount.value = 9
}
</script>

<template>
  <!-- ══════════ Warm 테마 ══════════ -->
  <div v-if="isWarm" class="container-warm py-stack-lg">
    <!-- 프로모션 배너 -->
    <div class="relative mb-stack-lg h-[240px] w-full overflow-hidden rounded-xl md:h-[320px]">
      <div
        class="absolute inset-0 bg-cover bg-center"
        style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAK85tGMBkvDs1OEQUOO06yNrFM99lwVvRLBWF5tvyszy5q1_A8fcF-AnbrzL4q3gRD5APA02199xx161DGkHNoOr7DDP8w1oVhhW1dlu6PoQb2lsOVVE3RXmQTZmQ79tLXIjXZ7iZA2KCjCes4tckdO7nP2t7fcty91XsEFONFt9dE7sy9h5JNmfhcFguRRVWrb9fsvSWhi3Hk-lGdmQNsoGAUNUZGpowWC92q4E_axJ0JD3W29oVJOw')"
      ></div>
      <div class="absolute inset-0 bg-gradient-to-r from-primary-container/80 to-transparent"></div>
      <div class="absolute inset-0 flex max-w-2xl flex-col justify-center p-8 md:p-12">
        <span class="mb-3 w-max rounded-full bg-secondary-container px-3 py-1 font-label-sm text-on-secondary-container">엄선된 상품</span>
        <h1 class="mb-3 font-headline-xl text-headline-lg-mobile text-on-primary md:text-headline-xl">댕이를 부탁해 샵</h1>
        <p class="max-w-md font-body-lg text-body-lg text-surface-container-low">
          수제 간식부터 프리미엄 사료, 안전한 장난감까지. 우리 아이를 위한 좋은 것만 모았습니다.
        </p>
      </div>
    </div>

    <div class="flex flex-col gap-gutter md:flex-row">
      <!-- 필터 -->
      <aside class="w-full shrink-0 md:w-64">
        <div class="sticky top-28 rounded-xl border border-surface-container bg-surface-container-lowest p-6 shadow-sm">
          <h3 class="mb-6 flex items-center gap-2 font-headline-md text-headline-md text-primary">
            <span class="material-symbols-outlined">filter_list</span> 필터
          </h3>
          <div v-if="realCategories.length > 0">
            <h4 class="mb-3 font-label-md text-label-md text-on-surface">카테고리</h4>
            <div class="space-y-2">
              <label
                v-for="c in realCategories"
                :key="c"
                class="group flex cursor-pointer items-center gap-3"
              >
                <input
                  type="checkbox"
                  class="h-5 w-5 rounded border-outline text-primary focus:ring-primary"
                  :checked="checkedCategories.includes(c)"
                  @change="toggleCategory(c)"
                />
                <span class="font-body-md text-on-surface-variant transition-colors group-hover:text-primary">{{ c }}</span>
              </label>
            </div>
          </div>
          <p v-else class="font-body-md text-sm text-on-surface-variant">등록된 카테고리가 없습니다.</p>
        </div>
      </aside>

      <!-- 상품 목록 -->
      <div class="flex-grow">
        <div class="mb-6 flex items-center justify-between">
          <p class="font-body-md text-on-surface-variant">{{ warmFiltered.length }}개 상품</p>
          <select
            v-model="sortBy"
            class="rounded-lg border border-outline bg-surface-container-lowest px-3 py-2 font-body-md text-on-surface-variant focus:border-primary focus:ring-primary"
          >
            <option value="recommended">추천순</option>
            <option value="price-asc">낮은 가격순</option>
            <option value="price-desc">높은 가격순</option>
            <option value="newest">신상품순</option>
          </select>
        </div>

        <p v-if="loading" class="py-16 text-center font-body-md text-sm text-on-surface-variant">불러오는 중...</p>
        <p v-else-if="warmFiltered.length === 0" class="py-16 text-center font-body-md text-sm text-on-surface-variant">조건에 맞는 상품이 없습니다.</p>

        <div v-else class="grid grid-cols-1 gap-gutter sm:grid-cols-2 lg:grid-cols-3">
          <NuxtLink
            v-for="p in warmVisible"
            :key="p.id"
            :to="`/shop/${p.id}`"
            class="flex flex-col rounded-xl border border-surface-container bg-surface-container-lowest p-4 transition-all duration-300 hover:-translate-y-1 hover:shadow-lg"
          >
            <div class="relative mb-4 aspect-square overflow-hidden rounded-lg bg-surface-container-low">
              <img v-if="p.image_url" :src="p.image_url" :alt="p.name" class="h-full w-full object-cover" />
              <span v-else class="flex h-full w-full items-center justify-center text-5xl">🐾</span>
            </div>
            <div class="flex-grow">
              <h3 class="mb-1 font-label-md text-label-md text-on-surface">{{ p.name }}</h3>
              <p class="mb-4 font-body-md text-body-md text-on-surface-variant">{{ p.category || '기타' }}</p>
            </div>
            <div class="mt-auto flex items-center justify-between">
              <span class="font-headline-md text-headline-md text-primary">₩{{ p.price.toLocaleString() }}</span>
              <span
                class="flex h-11 w-11 items-center justify-center rounded-full bg-surface-container-high text-primary"
                :class="p.stock === 0 ? 'opacity-40' : ''"
              >
                <span class="material-symbols-outlined">{{ p.stock === 0 ? 'block' : 'chevron_right' }}</span>
              </span>
            </div>
            <p v-if="p.stock === 0" class="mt-2 font-label-sm text-label-sm text-error">품절</p>
          </NuxtLink>
        </div>

        <div v-if="!loading && warmVisible.length < warmFiltered.length" class="mt-12 flex justify-center">
          <button
            type="button"
            class="rounded-xl border-2 border-primary px-8 py-3 font-label-md text-primary transition-colors hover:bg-primary hover:text-on-primary"
            @click="visibleCount += 9"
          >
            상품 더 보기
          </button>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ 기본 테마 ══════════ -->
  <div v-else class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">쇼핑몰</h1>
    <p class="mb-6 text-gray-500">엄선된 사료와 용품을 만나보세요.</p>

    <div v-if="categories.length > 1" class="mb-6 flex flex-wrap gap-2">
      <button
        v-for="c in categories"
        :key="c"
        type="button"
        class="rounded-full border px-4 py-1.5 text-sm font-medium transition"
        :class="selectedCategory === c ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
        @click="selectedCategory = c"
      >
        {{ c === 'all' ? '전체' : c }}
      </button>
    </div>

    <p v-if="loading" class="py-16 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="filteredProducts.length === 0" class="py-16 text-center text-sm text-gray-400">등록된 상품이 없습니다.</p>

    <div v-else class="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
      <NuxtLink
        v-for="p in filteredProducts"
        :key="p.id"
        :to="`/shop/${p.id}`"
        class="card flex flex-col gap-3 transition hover:shadow-md"
      >
        <div class="flex h-32 items-center justify-center overflow-hidden rounded-lg bg-brand-50">
          <img v-if="p.image_url" :src="p.image_url" :alt="p.name" class="h-full w-full object-cover" />
          <span v-else class="text-4xl">🐾</span>
        </div>
        <div>
          <p class="text-xs text-gray-400">{{ p.category || '기타' }}</p>
          <p class="font-semibold text-gray-900">{{ p.name }}</p>
          <p class="mt-1 font-bold text-brand-600">{{ p.price.toLocaleString() }}원</p>
          <p v-if="p.stock === 0" class="mt-1 text-xs text-red-500">품절</p>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>
