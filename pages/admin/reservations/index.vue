<script setup lang="ts">
import type { ReservationType } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllReservations, updateReservationStatus } = useReservations()
const { fetchServiceSettings, updateServiceSetting } = useServiceSettings()

const reservations = ref<any[]>([])
const loading = ref(true)

// ── 요금 · 정원 설정 ─────────────────────────────
const pricing = reactive<Record<ReservationType, { price: number; default_capacity: number; deposit_rate: number }>>({
  hotel: { price: 0, default_capacity: 0, deposit_rate: 1 },
  daycare: { price: 0, default_capacity: 0, deposit_rate: 1 }
})
const pricingLoading = ref(true)
const pricingMsg = ref<{ ok: boolean; text: string } | null>(null)
const savingType = ref<ReservationType | null>(null)

const loadPricing = async () => {
  try {
    const s = await fetchServiceSettings()
    for (const t of ['hotel', 'daycare'] as ReservationType[]) {
      if (s[t]) {
        pricing[t].price = s[t].price
        pricing[t].default_capacity = s[t].default_capacity
        pricing[t].deposit_rate = Number(s[t].deposit_rate)
      }
    }
  } finally {
    pricingLoading.value = false
  }
}

const savePricing = async (t: ReservationType) => {
  savingType.value = t
  pricingMsg.value = null
  try {
    await updateServiceSetting(t, {
      price: Math.max(0, Math.round(pricing[t].price)),
      default_capacity: Math.max(0, Math.round(pricing[t].default_capacity)),
      deposit_rate: Math.min(1, Math.max(0.01, pricing[t].deposit_rate))
    })
    pricingMsg.value = { ok: true, text: `${t === 'hotel' ? '호텔' : '데이케어'} 설정을 저장했습니다.` }
  } catch (e: any) {
    pricingMsg.value = { ok: false, text: e?.message ?? '저장에 실패했습니다.' }
  } finally {
    savingType.value = null
  }
}

onMounted(loadPricing)

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
    <!-- 요금 · 정원 설정 -->
    <section class="card mb-6">
      <p class="mb-4 font-semibold text-gray-900">요금 · 정원 설정</p>
      <p v-if="pricingLoading" class="text-sm text-gray-400">불러오는 중...</p>
      <div v-else class="grid gap-6 sm:grid-cols-2">
        <div
          v-for="t in (['hotel', 'daycare'] as const)"
          :key="t"
          class="rounded-xl border border-gray-200 p-4"
        >
          <p class="mb-3 font-semibold text-gray-800">{{ t === 'hotel' ? '🏨 호텔 숙박' : '☀️ 데이케어' }}</p>
          <div class="space-y-3">
            <div>
              <label class="label-field">{{ t === 'hotel' ? '1박 요금 (원)' : '1일 요금 (원)' }}</label>
              <input v-model.number="pricing[t].price" type="number" min="0" step="1000" class="input-field" />
            </div>
            <div>
              <label class="label-field">하루 정원 (마리)</label>
              <input v-model.number="pricing[t].default_capacity" type="number" min="0" class="input-field" />
            </div>
            <div>
              <label class="label-field">결제 비율 (예약금)</label>
              <select v-model.number="pricing[t].deposit_rate" class="input-field">
                <option :value="1">전액 (100%)</option>
                <option :value="0.5">50%</option>
                <option :value="0.3">30%</option>
                <option :value="0.2">20%</option>
                <option :value="0.1">10%</option>
              </select>
            </div>
            <button type="button" class="btn-primary !py-2 w-full" :disabled="savingType === t" @click="savePricing(t)">
              {{ savingType === t ? '저장 중...' : '저장' }}
            </button>
          </div>
        </div>
      </div>
      <p
        v-if="pricingMsg"
        class="mt-3 text-sm"
        :class="pricingMsg.ok ? 'text-green-600' : 'text-red-500'"
      >
        {{ pricingMsg.text }}
      </p>
    </section>

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
      <table class="w-full min-w-[780px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">반려동물</th>
            <th class="py-3 pr-4 font-medium">보호자</th>
            <th class="py-3 pr-4 font-medium">서비스</th>
            <th class="py-3 pr-4 font-medium">기간</th>
            <th class="py-3 pr-4 font-medium">결제</th>
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
                class="rounded-full px-2 py-0.5 text-xs font-semibold"
                :class="r.deposit_paid ? 'bg-green-50 text-green-600' : 'bg-gray-100 text-gray-400'"
              >
                {{ r.deposit_paid ? '결제완료' : '미결제' }}
              </span>
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
