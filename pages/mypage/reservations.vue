<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchMyReservations } = useReservations()

const reservations = ref<any[]>([])
const loading = ref(true)

const statusLabel: Record<string, string> = {
  pending: '승인 대기',
  confirmed: '확정',
  rejected: '거절됨',
  cancelled: '취소됨',
  completed: '완료'
}

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const toHHMM = (t: string) => t?.slice(0, 5)

onMounted(async () => {
  try {
    reservations.value = await fetchMyReservations()
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

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="reservations.length === 0" class="py-8 text-center text-sm text-gray-400">
      예약 내역이 없습니다.
    </p>

    <div v-else class="space-y-3">
      <div v-for="r in reservations" :key="r.id" class="card flex items-center justify-between">
        <div>
          <p class="font-semibold text-gray-900">{{ typeLabel[r.type] }} · {{ r.pets?.name }}</p>
          <p class="text-sm text-gray-400">
            {{ r.start_date }} {{ toHHMM(r.start_time) }} ~ {{ r.end_date }} {{ toHHMM(r.end_time) }}
          </p>
        </div>
        <span class="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-600">
          {{ statusLabel[r.status] ?? r.status }}
        </span>
      </div>
    </div>
  </div>
</template>
