<script setup lang="ts">
import type { Inquiry, InquiryStatus } from '~/types/database.types'

definePageMeta({ middleware: ['auth', 'contact-enabled'] })

const { fetchMyInquiries } = useInquiries()

const inquiries = ref<Inquiry[]>([])
const loading = ref(true)

const statusLabel: Record<InquiryStatus, string> = { open: '접수됨', answered: '답변 완료', closed: '종료' }
const statusClass: Record<InquiryStatus, string> = {
  open: 'bg-amber-50 text-amber-600',
  answered: 'bg-green-50 text-green-600',
  closed: 'bg-gray-100 text-gray-500'
}
const fmt = (s: string) => new Date(s).toLocaleString('ko-KR')

onMounted(async () => {
  try {
    inquiries.value = await fetchMyInquiries()
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">마이페이지</h1>
    <p class="mb-6 text-gray-500">예약 내역과 주문 내역을 한 곳에서 확인하세요.</p>

    <CommonMypageTabs />

    <div class="mb-4 flex justify-end">
      <NuxtLink to="/contact" class="btn-primary !py-2 text-sm">+ 새 문의하기</NuxtLink>
    </div>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="inquiries.length === 0" class="py-8 text-center text-sm text-gray-400">
      문의 내역이 없습니다.
      <span class="mt-1 block text-xs">로그인 상태에서 남긴 문의만 여기에 표시됩니다.</span>
    </p>

    <div v-else class="space-y-4">
      <div v-for="q in inquiries" :key="q.id" class="card">
        <div class="mb-2 flex items-center justify-between">
          <span class="text-xs text-gray-400">{{ fmt(q.created_at) }}</span>
          <span class="rounded-full px-2.5 py-1 text-xs font-semibold" :class="statusClass[q.status]">
            {{ statusLabel[q.status] }}
          </span>
        </div>
        <p class="whitespace-pre-wrap text-sm text-gray-800">{{ q.message }}</p>

        <div v-if="q.answer" class="mt-3 rounded-lg bg-brand-50 p-3">
          <p class="mb-1 text-xs font-semibold text-brand-600">답변</p>
          <p class="whitespace-pre-wrap text-sm text-gray-700">{{ q.answer }}</p>
          <p v-if="q.answered_at" class="mt-1 text-[11px] text-gray-400">{{ fmt(q.answered_at) }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
