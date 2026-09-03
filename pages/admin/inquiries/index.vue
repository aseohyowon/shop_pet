<script setup lang="ts">
import type { Inquiry, InquiryStatus } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllInquiries } = useInquiries()

const inquiries = ref<Inquiry[]>([])
const loading = ref(true)
const statusFilter = ref<'all' | InquiryStatus>('all')
const errorMessage = ref('')

const statusLabel: Record<InquiryStatus, string> = { open: '접수', answered: '답변 완료', closed: '종료' }
const statusClass: Record<InquiryStatus, string> = {
  open: 'bg-amber-50 text-amber-600',
  answered: 'bg-green-50 text-green-600',
  closed: 'bg-gray-100 text-gray-500'
}
const fmt = (s: string) => new Date(s).toLocaleString('ko-KR')

const load = async () => {
  loading.value = true
  try {
    inquiries.value = await fetchAllInquiries(statusFilter.value === 'all' ? undefined : statusFilter.value)
  } catch (e: any) {
    errorMessage.value = e?.message ?? '문의를 불러오지 못했습니다. (0011 마이그레이션 확인)'
  } finally {
    loading.value = false
  }
}
onMounted(load)
watch(statusFilter, load)
</script>

<template>
  <div>
    <h1 class="mb-1 text-2xl font-bold text-gray-900">1:1 문의</h1>
    <p class="mb-6 text-sm text-gray-500">고객 문의를 확인하고 답변합니다.</p>

    <div class="mb-4 flex gap-2">
      <button
        v-for="f in (['all', 'open', 'answered', 'closed'] as const)"
        :key="f"
        type="button"
        class="rounded-full border px-3 py-1.5 text-sm font-medium transition"
        :class="statusFilter === f ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
        @click="statusFilter = f"
      >
        {{ f === 'all' ? '전체' : statusLabel[f] }}
      </button>
    </div>

    <p v-if="errorMessage" class="mb-4 text-sm text-red-500">{{ errorMessage }}</p>
    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="inquiries.length === 0" class="py-8 text-center text-sm text-gray-400">문의가 없습니다.</p>

    <div v-else class="card overflow-x-auto">
      <table class="w-full min-w-[640px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">접수일</th>
            <th class="py-3 pr-4 font-medium">이름</th>
            <th class="py-3 pr-4 font-medium">내용</th>
            <th class="py-3 pr-4 font-medium">상태</th>
            <th class="py-3 font-medium"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="q in inquiries" :key="q.id" class="border-b border-gray-100 last:border-0 hover:bg-gray-50">
            <td class="py-3 pr-4 text-gray-500">{{ fmt(q.created_at) }}</td>
            <td class="py-3 pr-4 font-medium text-gray-800">{{ q.name }}</td>
            <td class="max-w-xs truncate py-3 pr-4 text-gray-600">{{ q.message }}</td>
            <td class="py-3 pr-4">
              <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass[q.status]">
                {{ statusLabel[q.status] }}
              </span>
            </td>
            <td class="py-3">
              <NuxtLink :to="`/admin/inquiries/${q.id}`" class="text-brand-600 hover:underline">보기</NuxtLink>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
