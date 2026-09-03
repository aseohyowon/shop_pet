<script setup lang="ts">
import type { Product } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllProductsForAdmin, deleteProduct, updateProduct } = useProducts()

const LOW_STOCK = 5

const products = ref<Product[]>([])
const loading = ref(true)
const keyword = ref('')
const categoryFilter = ref('all')
const statusFilter = ref<'all' | 'active' | 'hidden' | 'low'>('all')

const stockDraft = reactive<Record<string, number>>({})

const load = async () => {
  loading.value = true
  try {
    products.value = await fetchAllProductsForAdmin()
  } finally {
    loading.value = false
  }
}
onMounted(load)

const categories = computed(() => {
  const set = new Set(products.value.map((p) => p.category).filter(Boolean) as string[])
  return [...set].sort()
})

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return products.value.filter((p) => {
    if (kw && !p.name.toLowerCase().includes(kw)) return false
    if (categoryFilter.value !== 'all' && (p.category ?? '') !== categoryFilter.value) return false
    if (statusFilter.value === 'active' && !p.is_active) return false
    if (statusFilter.value === 'hidden' && p.is_active) return false
    if (statusFilter.value === 'low' && p.stock > LOW_STOCK) return false
    return true
  })
})

const handleDelete = async (id: string) => {
  if (!confirm('이 상품을 삭제할까요?')) return
  await deleteProduct(id)
  await load()
}

const toggleActive = async (p: Product) => {
  await updateProduct(p.id, { isActive: !p.is_active })
  p.is_active = !p.is_active
}

const startStockEdit = (p: Product) => {
  stockDraft[p.id] = p.stock
}
const saveStock = async (p: Product) => {
  const next = stockDraft[p.id]
  if (next == null || next < 0) return
  await updateProduct(p.id, { stock: next })
  p.stock = next
  delete stockDraft[p.id]
}
</script>

<template>
  <div>
    <div class="mb-6 flex items-center justify-between">
      <h1 class="text-2xl font-bold text-gray-900">상품 관리</h1>
      <NuxtLink to="/admin/products/new" class="btn-primary !py-2">+ 상품 등록</NuxtLink>
    </div>

    <!-- 필터 -->
    <div class="mb-4 flex flex-wrap items-center gap-3">
      <input v-model="keyword" type="search" class="input-field !w-56" placeholder="상품명 검색" />
      <select v-model="categoryFilter" class="input-field !w-40">
        <option value="all">전체 카테고리</option>
        <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
      </select>
      <select v-model="statusFilter" class="input-field !w-36">
        <option value="all">전체 상태</option>
        <option value="active">진열 중</option>
        <option value="hidden">숨김</option>
        <option value="low">재고 부족</option>
      </select>
      <span class="text-sm text-gray-400">{{ filtered.length }}개</span>
    </div>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="filtered.length === 0" class="py-8 text-center text-sm text-gray-400">조건에 맞는 상품이 없습니다.</p>

    <div v-else class="card overflow-x-auto">
      <table class="w-full min-w-[720px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">상품명</th>
            <th class="py-3 pr-4 font-medium">카테고리</th>
            <th class="py-3 pr-4 font-medium">가격</th>
            <th class="py-3 pr-4 font-medium">재고</th>
            <th class="py-3 pr-4 font-medium">진열</th>
            <th class="py-3 font-medium">액션</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in filtered" :key="p.id" class="border-b border-gray-100 last:border-0">
            <td class="py-3 pr-4 font-medium text-gray-800">{{ p.name }}</td>
            <td class="py-3 pr-4 text-gray-600">{{ p.category || '미분류' }}</td>
            <td class="py-3 pr-4 text-gray-600">{{ p.price.toLocaleString() }}원</td>
            <td class="py-3 pr-4">
              <div v-if="stockDraft[p.id] != null" class="flex items-center gap-1">
                <input v-model.number="stockDraft[p.id]" type="number" min="0" class="input-field !w-20 !py-1" />
                <button type="button" class="text-xs font-medium text-brand-600 hover:underline" @click="saveStock(p)">저장</button>
              </div>
              <button
                v-else
                type="button"
                class="rounded px-1.5 py-0.5 font-medium hover:bg-gray-100"
                :class="p.stock === 0 ? 'text-red-500' : p.stock <= LOW_STOCK ? 'text-amber-600' : 'text-gray-600'"
                title="클릭해서 재고 수정"
                @click="startStockEdit(p)"
              >
                {{ p.stock === 0 ? '품절' : `${p.stock}개` }}{{ p.stock > 0 && p.stock <= LOW_STOCK ? ' ⚠' : '' }}
              </button>
            </td>
            <td class="py-3 pr-4">
              <button
                type="button"
                class="rounded-full px-2.5 py-1 text-xs font-semibold"
                :class="p.is_active ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-500'"
                @click="toggleActive(p)"
              >
                {{ p.is_active ? '진열 중' : '숨김' }}
              </button>
            </td>
            <td class="py-3">
              <NuxtLink :to="`/admin/products/${p.id}/edit`" class="mr-2 text-brand-600 hover:underline">수정</NuxtLink>
              <button type="button" class="text-red-500 hover:underline" @click="handleDelete(p.id)">삭제</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
