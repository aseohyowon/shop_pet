<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllReservations, updateReservationStatus } = useReservations()

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

const view = ref<'list' | 'calendar'>('list')

const load = async () => {
  loading.value = true
  try {
    reservations.value = await fetchAllReservations()
  } finally {
    loading.value = false
  }
}

onMounted(load)

const handleAction = async (id: string, status: 'confirmed' | 'rejected') => {
  await updateReservationStatus(id, status)
  await load()
}
</script>

<template>
  <div>
    <div class="mb-6 flex items-center justify-between">
      <h1 class="text-2xl font-bold text-gray-900">예약 관리</h1>
      <div class="flex gap-2 text-sm">
        <button
          type="button"
          class="!py-2"
          :class="view === 'calendar' ? 'btn-primary' : 'btn-secondary'"
          @click="view = 'calendar'"
        >
          캘린더 뷰
        </button>
        <button
          type="button"
          class="!py-2"
          :class="view === 'list' ? 'btn-primary' : 'btn-secondary'"
          @click="view = 'list'"
        >
          목록 뷰
        </button>
      </div>
    </div>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="reservations.length === 0" class="py-8 text-center text-sm text-gray-400">예약이 없습니다.</p>

    <div v-else-if="view === 'calendar'" class="card">
      <AdminReservationCalendar :reservations="reservations" />
    </div>

    <div v-else class="card overflow-x-auto">
      <table class="w-full min-w-[700px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">반려동물</th>
            <th class="py-3 pr-4 font-medium">보호자</th>
            <th class="py-3 pr-4 font-medium">서비스</th>
            <th class="py-3 pr-4 font-medium">기간</th>
            <th class="py-3 pr-4 font-medium">상태</th>
            <th class="py-3 font-medium">액션</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in reservations" :key="r.id" class="border-b border-gray-100 last:border-0">
            <td class="py-3 pr-4">
              <NuxtLink :to="`/admin/reservations/${r.id}`" class="font-medium text-brand-600 hover:underline">
                {{ r.pets?.name }}
              </NuxtLink>
            </td>
            <td class="py-3 pr-4 text-gray-600">{{ r.profiles?.name }}</td>
            <td class="py-3 pr-4 text-gray-600">{{ typeLabel[r.type] }}</td>
            <td class="py-3 pr-4 text-gray-600">
              {{ r.start_date }} {{ toHHMM(r.start_time) }} ~ {{ r.end_date }} {{ toHHMM(r.end_time) }}
            </td>
            <td class="py-3 pr-4">
              <span
                class="rounded-full px-2.5 py-1 text-xs font-semibold"
                :class="r.status === 'confirmed' ? 'bg-green-50 text-green-600' : r.status === 'pending' ? 'bg-brand-50 text-brand-600' : 'bg-gray-100 text-gray-500'"
              >
                {{ statusLabel[r.status] ?? r.status }}
              </span>
            </td>
            <td class="py-3">
              <template v-if="r.status === 'pending'">
                <button type="button" class="mr-2 text-green-600 hover:underline" @click="handleAction(r.id, 'confirmed')">승인</button>
                <button type="button" class="text-red-500 hover:underline" @click="handleAction(r.id, 'rejected')">거절</button>
              </template>
              <span v-else class="text-gray-300">-</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
