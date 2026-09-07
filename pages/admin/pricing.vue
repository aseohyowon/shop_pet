<script setup lang="ts">
import type { PricingItem, PricingCategory } from '~/types/database.types'
import { PRICING_CATEGORIES } from '~/composables/usePricing'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAll, createItem, updateItem, deleteItem } = usePricing()

const items = ref<PricingItem[]>([])
const loading = ref(true)
const savingId = ref<string | null>(null)
const message = ref<{ ok: boolean; text: string } | null>(null)

const load = async () => {
  loading.value = true
  try {
    items.value = await fetchAll()
  } finally {
    loading.value = false
  }
}
onMounted(load)

const byCategory = (cat: PricingCategory) => items.value.filter((i) => i.category === cat)

const save = async (item: PricingItem) => {
  savingId.value = item.id
  message.value = null
  try {
    await updateItem(item.id, {
      name: item.name,
      price: item.price,
      unit: item.unit ?? '',
      note: item.note ?? '',
      sort_order: item.sort_order,
      is_active: item.is_active
    })
    message.value = { ok: true, text: `"${item.name}" 저장됨` }
  } catch (e: any) {
    message.value = { ok: false, text: e?.message ?? '저장 실패' }
  } finally {
    savingId.value = null
  }
}

const remove = async (item: PricingItem) => {
  if (item.billing_key) {
    message.value = { ok: false, text: '예약 결제 기준 항목은 삭제할 수 없습니다. (가격만 수정하세요)' }
    return
  }
  if (!confirm(`"${item.name}" 항목을 삭제할까요?`)) return
  await deleteItem(item.id)
  await load()
}

const newItem = reactive<{ category: PricingCategory; name: string; price: number; unit: string; note: string }>({
  category: 'daycare',
  name: '',
  price: 0,
  unit: '',
  note: ''
})
const adding = ref(false)
const add = async () => {
  if (!newItem.name.trim()) {
    message.value = { ok: false, text: '항목명을 입력하세요.' }
    return
  }
  adding.value = true
  try {
    const maxSort = Math.max(0, ...byCategory(newItem.category).map((i) => i.sort_order))
    await createItem({
      category: newItem.category,
      name: newItem.name.trim(),
      price: newItem.price,
      unit: newItem.unit || null,
      note: newItem.note || null,
      sort_order: maxSort + 10
    })
    newItem.name = ''
    newItem.price = 0
    newItem.unit = ''
    newItem.note = ''
    await load()
    message.value = { ok: true, text: '항목이 추가되었습니다.' }
  } catch (e: any) {
    message.value = { ok: false, text: e?.message ?? '추가 실패' }
  } finally {
    adding.value = false
  }
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-gray-900">가격 관리</h1>
      <p class="mt-1 text-sm text-gray-500">
        고객 <NuxtLink to="/pricing" target="_blank" class="text-brand-600 underline">요금 안내 페이지</NuxtLink>에 표시되는 요금표입니다.
        <strong>예약 결제 기준</strong> 표시가 있는 항목(종일 데이케어 · 호텔 1박)은 온라인 예약 결제 금액에 사용됩니다.
      </p>
    </div>

    <p v-if="message" class="mb-4 text-sm" :class="message.ok ? 'text-green-600' : 'text-red-500'">{{ message.text }}</p>
    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <div v-else class="space-y-8">
      <section v-for="cat in PRICING_CATEGORIES" :key="cat.key" class="card">
        <p class="mb-4 font-semibold text-gray-900">{{ cat.label }}</p>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[720px] text-left text-sm">
            <thead>
              <tr class="border-b border-gray-200 text-xs text-gray-400">
                <th class="w-16 py-2 pr-3 font-medium">순서</th>
                <th class="py-2 pr-3 font-medium">항목명</th>
                <th class="w-32 py-2 pr-3 font-medium">가격(원)</th>
                <th class="w-24 py-2 pr-3 font-medium">단위</th>
                <th class="py-2 pr-3 font-medium">설명</th>
                <th class="w-20 py-2 pr-3 font-medium">노출</th>
                <th class="w-24 py-2 font-medium"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in byCategory(cat.key)" :key="item.id" class="border-b border-gray-100 last:border-0">
                <td class="py-2 pr-3">
                  <input v-model.number="item.sort_order" type="number" class="input-field !w-14 !py-1 !px-2 text-xs" />
                </td>
                <td class="py-2 pr-3">
                  <input v-model="item.name" type="text" class="input-field !py-1.5 text-sm" />
                  <span v-if="item.billing_key" class="mt-0.5 inline-block rounded bg-brand-50 px-1.5 py-0.5 text-[10px] font-semibold text-brand-600">
                    예약 결제 기준
                  </span>
                </td>
                <td class="py-2 pr-3">
                  <input v-model.number="item.price" type="number" min="0" step="1000" class="input-field !py-1.5 text-sm" />
                </td>
                <td class="py-2 pr-3">
                  <input v-model="item.unit" type="text" class="input-field !py-1.5 text-sm" placeholder="1박" />
                </td>
                <td class="py-2 pr-3">
                  <input v-model="item.note" type="text" class="input-field !py-1.5 text-sm" placeholder="산책 1회 포함" />
                </td>
                <td class="py-2 pr-3">
                  <label class="inline-flex cursor-pointer items-center">
                    <input v-model="item.is_active" type="checkbox" class="h-4 w-4 rounded border-gray-300 text-brand-500" />
                  </label>
                </td>
                <td class="py-2">
                  <button
                    type="button"
                    class="mr-2 text-xs font-medium text-brand-600 hover:underline disabled:opacity-40"
                    :disabled="savingId === item.id"
                    @click="save(item)"
                  >
                    {{ savingId === item.id ? '저장 중' : '저장' }}
                  </button>
                  <button
                    v-if="!item.billing_key"
                    type="button"
                    class="text-xs text-gray-400 hover:text-red-500"
                    @click="remove(item)"
                  >
                    삭제
                  </button>
                </td>
              </tr>
              <tr v-if="byCategory(cat.key).length === 0">
                <td colspan="7" class="py-4 text-center text-xs text-gray-400">항목이 없습니다.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- 새 항목 추가 -->
      <section class="card">
        <p class="mb-4 font-semibold text-gray-900">항목 추가</p>
        <div class="flex flex-wrap items-end gap-3">
          <div>
            <label class="label-field">분류</label>
            <select v-model="newItem.category" class="input-field !py-1.5 text-sm">
              <option v-for="c in PRICING_CATEGORIES" :key="c.key" :value="c.key">{{ c.label }}</option>
            </select>
          </div>
          <div>
            <label class="label-field">항목명</label>
            <input v-model="newItem.name" type="text" class="input-field !py-1.5 text-sm" placeholder="예: 미용" />
          </div>
          <div>
            <label class="label-field">가격(원)</label>
            <input v-model.number="newItem.price" type="number" min="0" step="1000" class="input-field !w-32 !py-1.5 text-sm" />
          </div>
          <div>
            <label class="label-field">단위</label>
            <input v-model="newItem.unit" type="text" class="input-field !w-24 !py-1.5 text-sm" placeholder="1회" />
          </div>
          <div>
            <label class="label-field">설명</label>
            <input v-model="newItem.note" type="text" class="input-field !py-1.5 text-sm" />
          </div>
          <button type="button" class="btn-primary !py-2" :disabled="adding" @click="add">
            {{ adding ? '추가 중...' : '추가' }}
          </button>
        </div>
      </section>
    </div>
  </div>
</template>
