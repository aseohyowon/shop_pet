<script setup lang="ts">
import type { Category } from '~/types/database.types'

const props = defineProps<{
  submitLabel?: string
  submitting?: boolean
  errorMessage?: string
  existingImageUrl?: string | null
}>()

const emit = defineEmits<{ submit: [] }>()

const name = defineModel<string>('name', { default: '' })
const category = defineModel<string>('category', { default: '' })
const price = defineModel<number | null>('price', { default: null })
const stock = defineModel<number | null>('stock', { default: null })
const description = defineModel<string>('description', { default: '' })
const imageFile = defineModel<File | null>('imageFile', { default: null })

const { fetchAllCategories } = useCategories()
const categoryList = ref<Category[]>([])
const manualCategory = ref(false)

onMounted(async () => {
  try {
    categoryList.value = await fetchAllCategories()
    // 기존 상품의 카테고리가 목록에 없으면(레거시 값) 직접 입력 모드로
    if (category.value && !categoryList.value.some((c) => c.name === category.value)) {
      manualCategory.value = true
    }
  } catch {
    manualCategory.value = true
  }
})

const previewUrl = ref<string | null>(null)

watch(imageFile, (file) => {
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  previewUrl.value = file ? URL.createObjectURL(file) : null
})

const displayImageUrl = computed(() => previewUrl.value ?? props.existingImageUrl ?? null)

const handleFileChange = (e: Event) => {
  const file = (e.target as HTMLInputElement).files?.[0]
  imageFile.value = file ?? null
}
</script>

<template>
  <form class="card max-w-xl space-y-4" @submit.prevent="emit('submit')">
    <div>
      <label class="label-field" for="product-name">상품명</label>
      <input id="product-name" v-model="name" type="text" required class="input-field" placeholder="유기농 사료 3kg" />
    </div>
    <div class="grid grid-cols-2 gap-4">
      <div>
        <label class="label-field" for="product-category">카테고리</label>
        <select v-if="!manualCategory" id="product-category" v-model="category" class="input-field">
          <option value="">미분류</option>
          <option v-for="c in categoryList" :key="c.id" :value="c.name">
            {{ c.name }}{{ c.is_active ? '' : ' (숨김)' }}
          </option>
        </select>
        <input
          v-else
          id="product-category"
          v-model="category"
          type="text"
          class="input-field"
          placeholder="사료"
        />
        <button
          type="button"
          class="mt-1 text-xs text-gray-400 hover:text-brand-600"
          @click="manualCategory = !manualCategory"
        >
          {{ manualCategory ? '목록에서 선택' : '직접 입력' }}
        </button>
      </div>
      <div>
        <label class="label-field" for="product-price">가격 (원)</label>
        <input id="product-price" v-model.number="price" type="number" min="0" required class="input-field" placeholder="32000" />
      </div>
    </div>
    <div>
      <label class="label-field" for="product-stock">재고 수량</label>
      <input id="product-stock" v-model.number="stock" type="number" min="0" required class="input-field" placeholder="24" />
    </div>
    <div>
      <label class="label-field" for="product-description">상품 설명</label>
      <textarea id="product-description" v-model="description" rows="4" class="input-field" placeholder="상품 설명을 입력해주세요" />
    </div>
    <div>
      <label class="label-field">상품 이미지</label>
      <div class="flex items-center gap-4">
        <div class="flex h-24 w-24 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-gray-200 bg-gray-50">
          <img v-if="displayImageUrl" :src="displayImageUrl" alt="" class="h-full w-full object-cover" />
          <span v-else class="text-2xl text-gray-300">🐾</span>
        </div>
        <input type="file" accept="image/*" class="input-field" @change="handleFileChange" />
      </div>
    </div>

    <p v-if="errorMessage" class="text-sm text-red-500">{{ errorMessage }}</p>

    <div class="flex gap-3 pt-2">
      <button type="submit" class="btn-primary flex-1" :disabled="submitting">
        {{ submitting ? '처리 중...' : submitLabel ?? '등록하기' }}
      </button>
      <NuxtLink to="/admin/products" class="btn-secondary flex-1 text-center">취소</NuxtLink>
    </div>
  </form>
</template>
