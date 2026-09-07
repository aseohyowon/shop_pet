<script setup lang="ts">
import type { ReservationType } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllReservations, updateReservationStatus } = useReservations()
const { fetchServiceSettings, updateServiceSetting } = useServiceSettings()
const { updateBasePrice } = usePricing()
const { fetchRefundTiers, replaceRefundTiers } = useRefunds()
const { fetchOverrides, setOverride, removeOverride } = useDailyCapacity()

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
    await Promise.all([
      updateServiceSetting(t, {
        default_capacity: Math.max(0, Math.round(pricing[t].default_capacity)),
        deposit_rate: Math.min(1, Math.max(0.01, pricing[t].deposit_rate))
      }),
      updateBasePrice(t === 'hotel' ? 'hotel_night' : 'daycare_day', pricing[t].price)
    ])
    pricingMsg.value = { ok: true, text: `${t === 'hotel' ? '호텔' : '데이케어'} 설정을 저장했습니다.` }
  } catch (e: any) {
    pricingMsg.value = { ok: false, text: e?.message ?? '저장에 실패했습니다.' }
  } finally {
    savingType.value = null
  }
}

onMounted(loadPricing)

// ── 환불 규정 (예약 취소) ─────────────────────────
const refundTiers = ref<{ days_before: number; refund_rate: number }[]>([])
const refundLoading = ref(true)
const refundSaving = ref(false)
const refundMsg = ref<{ ok: boolean; text: string } | null>(null)

const loadRefund = async () => {
  try {
    const t = await fetchRefundTiers()
    refundTiers.value = t.map((x) => ({ days_before: x.days_before, refund_rate: x.refund_rate }))
  } finally {
    refundLoading.value = false
  }
}
onMounted(loadRefund)

const addTier = () => refundTiers.value.push({ days_before: 0, refund_rate: 0 })
const removeTier = (i: number) => refundTiers.value.splice(i, 1)

const saveRefund = async () => {
  refundSaving.value = true
  refundMsg.value = null
  try {
    const cleaned = refundTiers.value
      .map((t) => ({
        days_before: Math.max(0, Math.round(t.days_before)),
        refund_rate: Math.min(100, Math.max(0, Math.round(t.refund_rate)))
      }))
      .sort((a, b) => b.days_before - a.days_before)
    // days_before 중복 제거
    const seen = new Set<number>()
    const unique = cleaned.filter((t) => (seen.has(t.days_before) ? false : (seen.add(t.days_before), true)))
    await replaceRefundTiers(unique)
    refundTiers.value = unique
    refundMsg.value = { ok: true, text: '환불 규정을 저장했습니다.' }
  } catch (e: any) {
    refundMsg.value = { ok: false, text: e?.message ?? '저장에 실패했습니다.' }
  } finally {
    refundSaving.value = false
  }
}

// ── 날짜별 정원 예외 (공휴일 마감/증원) ───────────
const overrides = ref<import('~/composables/useDailyCapacity').CapacityOverride[]>([])
const overrideLoading = ref(true)
const newOv = reactive<{ date: string; type: ReservationType; max_capacity: number }>({
  date: '',
  type: 'hotel',
  max_capacity: 0
})
const overrideSaving = ref(false)
const overrideMsg = ref<{ ok: boolean; text: string } | null>(null)

const loadOverrides = async () => {
  overrideLoading.value = true
  try {
    overrides.value = await fetchOverrides()
  } finally {
    overrideLoading.value = false
  }
}
onMounted(loadOverrides)

const addOverride = async () => {
  overrideMsg.value = null
  if (!newOv.date) {
    overrideMsg.value = { ok: false, text: '날짜를 선택해주세요.' }
    return
  }
  overrideSaving.value = true
  try {
    await setOverride(newOv.date, newOv.type, newOv.max_capacity)
    newOv.date = ''
    newOv.max_capacity = 0
    await loadOverrides()
    overrideMsg.value = { ok: true, text: '저장했습니다.' }
  } catch (e: any) {
    overrideMsg.value = { ok: false, text: e?.message ?? '저장에 실패했습니다.' }
  } finally {
    overrideSaving.value = false
  }
}

const deleteOverride = async (id: string) => {
  await removeOverride(id)
  await loadOverrides()
}

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
      <p class="mb-1 font-semibold text-gray-900">요금 · 정원 설정</p>
      <p class="mb-4 text-sm text-gray-500">
        여기서 바꾸는 요금은 <strong>온라인 예약 결제 기준가</strong>(종일 데이케어 / 호텔 1박)입니다.
        시간제·정기권·스파 등 전체 요금표는 <NuxtLink to="/admin/pricing" class="text-brand-600 underline">가격 관리</NuxtLink>에서 수정하세요.
      </p>
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

    <!-- 환불 규정 (예약 취소) -->
    <section class="card mb-6">
      <p class="mb-1 font-semibold text-gray-900">환불 규정 (예약 취소)</p>
      <p class="mb-4 text-sm text-gray-500">
        고객이 예약을 취소할 때 <strong>이용일까지 남은 일수</strong>에 따라 환불 비율이 적용됩니다.
        (위에서부터 조건을 확인하며, 해당되는 첫 줄의 비율을 적용)
      </p>
      <p v-if="refundLoading" class="text-sm text-gray-400">불러오는 중...</p>
      <div v-else class="space-y-2">
        <div v-for="(t, i) in refundTiers" :key="i" class="flex flex-wrap items-center gap-2 text-sm">
          <span class="text-gray-500">이용</span>
          <input v-model.number="t.days_before" type="number" min="0" class="input-field !w-20 !py-1.5" />
          <span class="text-gray-500">일 전까지 취소 →</span>
          <input v-model.number="t.refund_rate" type="number" min="0" max="100" class="input-field !w-20 !py-1.5" />
          <span class="text-gray-500">% 환불</span>
          <button type="button" class="ml-1 text-xs text-gray-400 hover:text-red-500" @click="removeTier(i)">삭제</button>
        </div>
        <button type="button" class="mt-1 text-sm font-medium text-brand-600 hover:underline" @click="addTier">+ 조건 추가</button>
        <p class="mt-1 text-xs text-gray-400">
          예: "이용 7일 전까지 → 100%", "이용 3일 전까지 → 50%", "이용 1일 전까지 → 0%".
          어느 조건에도 안 맞으면(당일 등) 환불 없음.
        </p>
        <div class="pt-2">
          <button type="button" class="btn-primary !py-2" :disabled="refundSaving" @click="saveRefund">
            {{ refundSaving ? '저장 중...' : '환불 규정 저장' }}
          </button>
        </div>
        <p v-if="refundMsg" class="text-sm" :class="refundMsg.ok ? 'text-green-600' : 'text-red-500'">{{ refundMsg.text }}</p>
      </div>
    </section>

    <!-- 날짜별 정원 (공휴일 마감/증원) -->
    <section class="card mb-6">
      <p class="mb-1 font-semibold text-gray-900">날짜별 정원 (공휴일 등)</p>
      <p class="mb-4 text-sm text-gray-500">
        특정 날짜만 정원을 다르게 지정합니다. <strong>0</strong>으로 두면 그날은 예약을 받지 않습니다(마감).
        지정하지 않은 날은 위의 기본 정원이 적용됩니다.
      </p>

      <div class="flex flex-wrap items-end gap-2">
        <div>
          <label class="label-field">날짜</label>
          <input v-model="newOv.date" type="date" class="input-field !py-1.5" />
        </div>
        <div>
          <label class="label-field">서비스</label>
          <select v-model="newOv.type" class="input-field !py-1.5">
            <option value="hotel">호텔 숙박</option>
            <option value="daycare">데이케어</option>
          </select>
        </div>
        <div>
          <label class="label-field">정원 (마리)</label>
          <input v-model.number="newOv.max_capacity" type="number" min="0" class="input-field !w-24 !py-1.5" />
        </div>
        <button type="button" class="btn-primary !py-2" :disabled="overrideSaving" @click="addOverride">
          {{ overrideSaving ? '저장 중...' : '추가' }}
        </button>
      </div>
      <p v-if="overrideMsg" class="mt-2 text-sm" :class="overrideMsg.ok ? 'text-green-600' : 'text-red-500'">
        {{ overrideMsg.text }}
      </p>

      <div class="mt-4">
        <p v-if="overrideLoading" class="text-sm text-gray-400">불러오는 중...</p>
        <p v-else-if="overrides.length === 0" class="text-sm text-gray-400">지정된 날짜가 없습니다.</p>
        <ul v-else class="divide-y divide-gray-100 text-sm">
          <li v-for="o in overrides" :key="o.id" class="flex items-center justify-between py-2">
            <span class="text-gray-700">
              {{ o.date }} · {{ typeLabel[o.type] }} · 정원
              <strong :class="o.max_capacity === 0 ? 'text-red-500' : 'text-gray-900'">
                {{ o.max_capacity === 0 ? '마감' : `${o.max_capacity}마리` }}
              </strong>
            </span>
            <button type="button" class="text-xs text-gray-400 hover:text-red-500" @click="deleteOverride(o.id)">삭제</button>
          </li>
        </ul>
      </div>
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
            <td class="py-3 pr-4 text-gray-600">
              {{ typeLabel[r.type] }}<span v-if="r.type === 'daycare'" class="text-xs text-gray-400"> · {{ r.daycare_hourly ? '시간제' : '종일' }}</span>
            </td>
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
              <NuxtLink
                v-else-if="r.status === 'confirmed' || r.status === 'completed'"
                :to="`/admin/reservations/${r.id}`"
                class="text-red-500 hover:underline"
              >
                취소{{ r.deposit_paid ? ' · 환불' : '' }}
              </NuxtLink>
              <span v-else class="text-gray-300">-</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
