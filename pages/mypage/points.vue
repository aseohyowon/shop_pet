<script setup lang="ts">
import type { PointTransaction } from '~/types/database.types'
import { POINT_REASON_LABEL } from '~/composables/usePoints'

definePageMeta({ middleware: 'auth' })

const { fetchMyBalance, fetchMyHistory } = usePoints()

const balance = ref(0)
const history = ref<PointTransaction[]>([])
const loading = ref(true)

const load = async () => {
  loading.value = true
  try {
    const [b, h] = await Promise.all([fetchMyBalance(), fetchMyHistory()])
    balance.value = b
    history.value = h
  } finally {
    loading.value = false
  }
}
onMounted(load)

const fmtDate = (s: string) => new Date(s).toLocaleDateString('ko-KR')
</script>

<template>
  <div class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">마이페이지</h1>
    <p class="mb-6 text-gray-500">적립금(포인트) 잔액과 사용 내역을 확인하세요.</p>

    <CommonMypageTabs />

    <div class="card mb-6 flex items-center justify-between">
      <div>
        <p class="text-sm text-gray-500">보유 포인트</p>
        <p class="mt-1 text-3xl font-bold text-brand-600">{{ balance.toLocaleString() }}<span class="text-lg">P</span></p>
      </div>
      <p class="text-xs text-gray-400">1P = 1원 · 결제 시 사용 가능</p>
    </div>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="history.length === 0" class="py-8 text-center text-sm text-gray-400">포인트 내역이 없습니다.</p>

    <div v-else class="space-y-2">
      <div v-for="tx in history" :key="tx.id" class="card flex items-center justify-between gap-3 py-3">
        <div class="min-w-0">
          <p class="text-sm font-medium text-gray-800">
            {{ tx.memo || POINT_REASON_LABEL[tx.reason] }}
          </p>
          <p class="text-xs text-gray-400">{{ fmtDate(tx.created_at) }}</p>
        </div>
        <div class="shrink-0 text-right">
          <p class="text-sm font-bold" :class="tx.amount > 0 ? 'text-brand-600' : 'text-gray-700'">
            {{ tx.amount > 0 ? '+' : '' }}{{ tx.amount.toLocaleString() }}P
          </p>
          <p class="text-xs text-gray-400">잔액 {{ tx.balance_after.toLocaleString() }}P</p>
        </div>
      </div>
    </div>
  </div>
</template>
