<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const route = useRoute()
const router = useRouter()
const { fetchReservationById, updateReservationStatus } = useReservations()

const reservation = ref<any | null>(null)
const loading = ref(true)

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const statusLabel: Record<string, string> = {
  pending: '승인 대기',
  confirmed: '확정',
  rejected: '거절됨',
  cancelled: '취소됨',
  completed: '완료'
}
const toHHMM = (t: string) => t?.slice(0, 5)

const vaccStatusLabel = (no: number): string => {
  const s = reservation.value?.pets?.vaccinations?.[String(no)]
  return s === 'admin' ? `관리자확인 ${no}` : s === 'member' ? `회원확인 ${no}` : '미접종'
}

onMounted(async () => {
  try {
    reservation.value = await fetchReservationById(route.params.id as string)
  } finally {
    loading.value = false
  }
})

const handleAction = async (status: 'confirmed' | 'rejected') => {
  await updateReservationStatus(route.params.id as string, status)
  await router.push('/admin/reservations')
}
</script>

<template>
  <div>
    <NuxtLink to="/admin/reservations" class="mb-4 inline-block text-sm text-gray-500 hover:text-gray-700">
      ← 예약 목록으로
    </NuxtLink>
    <h1 class="mb-6 text-2xl font-bold text-gray-900">예약 상세</h1>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>

    <template v-else-if="reservation">
      <div class="grid gap-6 lg:grid-cols-2">
        <div class="card space-y-2">
          <p class="mb-2 font-semibold text-gray-900">예약 정보</p>
          <p class="text-sm text-gray-600">서비스: {{ typeLabel[reservation.type] }}</p>
          <p class="text-sm text-gray-600">
            기간: {{ reservation.start_date }} {{ toHHMM(reservation.start_time) }} ~
            {{ reservation.end_date }} {{ toHHMM(reservation.end_time) }}
          </p>
          <p class="text-sm text-gray-600">상태: {{ statusLabel[reservation.status] ?? reservation.status }}</p>
          <p class="text-sm text-gray-600">요청사항: {{ reservation.memo || '-' }}</p>
          <p class="mb-2 mt-4 font-semibold text-gray-900">보호자 정보</p>
          <p class="text-sm text-gray-600">이름: {{ reservation.profiles?.name }}</p>
          <p class="text-sm text-gray-600">연락처: {{ reservation.profiles?.phone }}</p>
          <p class="text-sm text-gray-600">이메일: {{ reservation.profiles?.email }}</p>
        </div>

        <div class="card space-y-2">
          <p class="mb-2 font-semibold text-gray-900">반려동물 정보</p>
          <p class="text-sm text-gray-600">이름: {{ reservation.pets?.name }}</p>
          <p class="text-sm text-gray-600">견종: {{ reservation.pets?.breed || '-' }}</p>
          <p class="text-sm text-gray-600">나이: {{ reservation.pets?.age ?? '-' }}세</p>
          <p class="text-sm text-gray-600">체중: {{ reservation.pets?.weight ?? '-' }}kg</p>
          <div class="pt-1">
            <p class="mb-1.5 text-sm text-gray-600">예방접종 현황</p>
            <div class="flex flex-wrap gap-1.5">
              <span
                v-for="no in [1, 2, 3, 4, 5]"
                :key="no"
                class="rounded-full px-2 py-0.5 text-xs font-semibold"
                :class="reservation.pets?.vaccinations?.[String(no)] === 'admin'
                  ? 'bg-green-100 text-green-700'
                  : reservation.pets?.vaccinations?.[String(no)] === 'member'
                    ? 'bg-amber-100 text-amber-700'
                    : 'bg-gray-100 text-gray-400'"
              >
                {{ vaccStatusLabel(no) }}
              </span>
            </div>
            <p class="mt-1.5 text-xs text-gray-400">
              규정 동의: {{ reservation.pets?.rules_agreed_at ? '완료' : '미확인' }}
            </p>
          </div>
          <p class="text-sm text-gray-600">특이사항: {{ reservation.pets?.notes || '-' }}</p>
        </div>
      </div>

      <div v-if="reservation.status === 'pending'" class="mt-6 flex gap-3">
        <button type="button" class="btn-primary" @click="handleAction('confirmed')">예약 승인</button>
        <button type="button" class="btn-secondary" @click="handleAction('rejected')">예약 거절</button>
      </div>
    </template>
  </div>
</template>
