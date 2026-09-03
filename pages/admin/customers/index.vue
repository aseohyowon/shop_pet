<script setup lang="ts">
import type { Profile } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchCustomers } = useCustomers()

const customers = ref<Profile[]>([])
const loading = ref(true)
const keyword = ref('')

const load = async () => {
  loading.value = true
  try {
    customers.value = await fetchCustomers(keyword.value)
  } finally {
    loading.value = false
  }
}
onMounted(load)

let timer: ReturnType<typeof setTimeout> | null = null
watch(keyword, () => {
  if (timer) clearTimeout(timer)
  timer = setTimeout(load, 300)
})

const fmtDate = (s: string) => new Date(s).toLocaleDateString('ko-KR')
</script>

<template>
  <div>
    <h1 class="mb-1 text-2xl font-bold text-gray-900">회원 관리</h1>
    <p class="mb-6 text-sm text-gray-500">가입 고객을 조회합니다.</p>

    <input v-model="keyword" type="search" class="input-field mb-4 !w-72" placeholder="이름 / 이메일 / 연락처 검색" />

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="customers.length === 0" class="py-8 text-center text-sm text-gray-400">회원이 없습니다.</p>

    <div v-else class="card overflow-x-auto">
      <table class="w-full min-w-[640px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">이름</th>
            <th class="py-3 pr-4 font-medium">이메일</th>
            <th class="py-3 pr-4 font-medium">연락처</th>
            <th class="py-3 pr-4 font-medium">가입일</th>
            <th class="py-3 font-medium"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in customers" :key="c.id" class="border-b border-gray-100 last:border-0 hover:bg-gray-50">
            <td class="py-3 pr-4 font-medium text-gray-800">{{ c.name || '-' }}</td>
            <td class="py-3 pr-4 text-gray-600">{{ c.email }}</td>
            <td class="py-3 pr-4 text-gray-600">{{ c.phone || '-' }}</td>
            <td class="py-3 pr-4 text-gray-500">{{ fmtDate(c.created_at) }}</td>
            <td class="py-3">
              <NuxtLink :to="`/admin/customers/${c.id}`" class="text-brand-600 hover:underline">상세</NuxtLink>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
