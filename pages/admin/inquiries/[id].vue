<script setup lang="ts">
import type { Inquiry, InquiryStatus } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const route = useRoute()
const { fetchInquiryById, answerInquiry, updateInquiryStatus } = useInquiries()

const inquiry = ref<Inquiry | null>(null)
const loading = ref(true)
const answer = ref('')
const saving = ref(false)
const errorMessage = ref('')

const statusLabel: Record<InquiryStatus, string> = { open: '접수', answered: '답변 완료', closed: '종료' }
const fmt = (s: string) => new Date(s).toLocaleString('ko-KR')

const load = async () => {
  loading.value = true
  try {
    inquiry.value = await fetchInquiryById(route.params.id as string)
    answer.value = inquiry.value.answer ?? ''
  } finally {
    loading.value = false
  }
}
onMounted(load)

const submitAnswer = async () => {
  if (!inquiry.value || !answer.value.trim()) return
  saving.value = true
  errorMessage.value = ''
  try {
    await answerInquiry(inquiry.value.id, answer.value)
    await load()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '저장에 실패했습니다.'
  } finally {
    saving.value = false
  }
}

const setStatus = async (s: InquiryStatus) => {
  if (!inquiry.value) return
  await updateInquiryStatus(inquiry.value.id, s)
  await load()
}
</script>

<template>
  <div class="max-w-2xl">
    <NuxtLink to="/admin/inquiries" class="mb-4 inline-block text-sm text-gray-500 hover:text-gray-700">← 문의 목록으로</NuxtLink>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="!inquiry" class="py-8 text-center text-sm text-gray-400">문의를 찾을 수 없습니다.</p>

    <div v-else class="space-y-6">
      <div class="card">
        <div class="mb-3 flex items-center justify-between">
          <h1 class="text-lg font-bold text-gray-900">{{ inquiry.name }}님의 문의</h1>
          <span class="text-xs text-gray-400">{{ statusLabel[inquiry.status] }}</span>
        </div>
        <dl class="mb-4 grid grid-cols-2 gap-x-6 gap-y-1 text-sm">
          <div><dt class="text-gray-400">연락처</dt><dd class="text-gray-800">{{ inquiry.phone || '-' }}</dd></div>
          <div><dt class="text-gray-400">이메일</dt><dd class="text-gray-800">{{ inquiry.email || '-' }}</dd></div>
          <div class="col-span-2"><dt class="text-gray-400">접수일</dt><dd class="text-gray-800">{{ fmt(inquiry.created_at) }}</dd></div>
        </dl>
        <div class="whitespace-pre-wrap rounded-lg bg-gray-50 p-4 text-sm text-gray-700">{{ inquiry.message }}</div>
      </div>

      <div class="card">
        <label class="label-field" for="answer">답변</label>
        <textarea id="answer" v-model="answer" rows="5" class="input-field" placeholder="고객에게 전달할 답변을 입력하세요" />
        <p v-if="inquiry.answered_at" class="mt-1 text-xs text-gray-400">최종 답변: {{ fmt(inquiry.answered_at) }}</p>
        <p v-if="errorMessage" class="mt-2 text-sm text-red-500">{{ errorMessage }}</p>
        <div class="mt-3 flex gap-2">
          <button type="button" class="btn-primary" :disabled="saving" @click="submitAnswer">
            {{ saving ? '저장 중...' : '답변 저장' }}
          </button>
          <button v-if="inquiry.status !== 'closed'" type="button" class="btn-secondary" @click="setStatus('closed')">문의 종료</button>
          <button v-else type="button" class="btn-secondary" @click="setStatus('open')">다시 열기</button>
        </div>
      </div>
    </div>
  </div>
</template>
