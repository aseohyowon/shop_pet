<script setup lang="ts">
import type { Category } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllCategories, createCategory, updateCategory, deleteCategory } = useCategories()

const categories = ref<Category[]>([])
const loading = ref(true)
const errorMessage = ref('')

const newName = ref('')
const newOrder = ref<number | null>(null)
const creating = ref(false)

// 행별 편집 상태
const editing = reactive<Record<string, { name: string; sort_order: number }>>({})

const load = async () => {
  loading.value = true
  try {
    categories.value = await fetchAllCategories()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '카테고리를 불러오지 못했습니다. (0010 마이그레이션을 실행했는지 확인하세요)'
  } finally {
    loading.value = false
  }
}
onMounted(load)

const handleCreate = async () => {
  errorMessage.value = ''
  if (!newName.value.trim()) return
  creating.value = true
  try {
    await createCategory({ name: newName.value, sortOrder: newOrder.value ?? 0 })
    newName.value = ''
    newOrder.value = null
    await load()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '카테고리 추가에 실패했습니다.'
  } finally {
    creating.value = false
  }
}

const startEdit = (c: Category) => {
  editing[c.id] = { name: c.name, sort_order: c.sort_order }
}
const cancelEdit = (id: string) => {
  delete editing[id]
}
const saveEdit = async (c: Category) => {
  const draft = editing[c.id]
  if (!draft) return
  try {
    await updateCategory(c.id, { name: draft.name, sortOrder: draft.sort_order }, c.name)
    delete editing[c.id]
    await load()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '수정에 실패했습니다.'
  }
}

const toggleActive = async (c: Category) => {
  try {
    await updateCategory(c.id, { isActive: !c.is_active })
    await load()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '변경에 실패했습니다.'
  }
}

const handleDelete = async (c: Category) => {
  if (!confirm(`"${c.name}" 카테고리를 삭제할까요?\n이 카테고리를 쓰던 상품은 '미분류'로 바뀝니다.`)) return
  try {
    await deleteCategory(c.id, c.name)
    await load()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '삭제에 실패했습니다.'
  }
}
</script>

<template>
  <div class="max-w-3xl">
    <h1 class="mb-1 text-2xl font-bold text-gray-900">카테고리 관리</h1>
    <p class="mb-6 text-sm text-gray-500">쇼핑몰 상품 분류와 필터 노출 순서를 관리합니다.</p>

    <!-- 추가 -->
    <form class="card mb-6 flex flex-wrap items-end gap-3" @submit.prevent="handleCreate">
      <div class="flex-1">
        <label class="label-field" for="cat-name">새 카테고리</label>
        <input id="cat-name" v-model="newName" type="text" class="input-field" placeholder="예: 사료, 간식, 장난감" />
      </div>
      <div class="w-24">
        <label class="label-field" for="cat-order">순서</label>
        <input id="cat-order" v-model.number="newOrder" type="number" class="input-field" placeholder="0" />
      </div>
      <button type="submit" class="btn-primary !py-2.5" :disabled="creating">추가</button>
    </form>

    <p v-if="errorMessage" class="mb-4 text-sm text-red-500">{{ errorMessage }}</p>
    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="categories.length === 0" class="py-8 text-center text-sm text-gray-400">등록된 카테고리가 없습니다.</p>

    <div v-else class="card overflow-x-auto">
      <table class="w-full min-w-[520px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">순서</th>
            <th class="py-3 pr-4 font-medium">이름</th>
            <th class="py-3 pr-4 font-medium">노출</th>
            <th class="py-3 font-medium">액션</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in categories" :key="c.id" class="border-b border-gray-100 last:border-0">
            <template v-if="editing[c.id]">
              <td class="py-2 pr-4"><input v-model.number="editing[c.id].sort_order" type="number" class="input-field !w-16 !py-1.5" /></td>
              <td class="py-2 pr-4"><input v-model="editing[c.id].name" type="text" class="input-field !py-1.5" /></td>
              <td class="py-2 pr-4 text-gray-400">-</td>
              <td class="py-2">
                <button type="button" class="mr-2 font-medium text-brand-600 hover:underline" @click="saveEdit(c)">저장</button>
                <button type="button" class="text-gray-500 hover:underline" @click="cancelEdit(c.id)">취소</button>
              </td>
            </template>
            <template v-else>
              <td class="py-3 pr-4 text-gray-500">{{ c.sort_order }}</td>
              <td class="py-3 pr-4 font-medium text-gray-800">{{ c.name }}</td>
              <td class="py-3 pr-4">
                <button
                  type="button"
                  class="rounded-full px-2.5 py-1 text-xs font-semibold"
                  :class="c.is_active ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-500'"
                  @click="toggleActive(c)"
                >
                  {{ c.is_active ? '노출 중' : '숨김' }}
                </button>
              </td>
              <td class="py-3">
                <button type="button" class="mr-2 text-brand-600 hover:underline" @click="startEdit(c)">수정</button>
                <button type="button" class="text-red-500 hover:underline" @click="handleDelete(c)">삭제</button>
              </td>
            </template>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
