<script setup lang="ts">
const props = defineProps<{ reservations: any[] }>()

const typeLabel: Record<string, string> = { hotel: '호텔', daycare: '데이케어' }
const statusColor: Record<string, string> = {
  pending: 'bg-brand-50 text-brand-600',
  confirmed: 'bg-green-50 text-green-600',
  rejected: 'bg-gray-100 text-gray-400 line-through',
  cancelled: 'bg-gray-100 text-gray-400 line-through',
  completed: 'bg-gray-100 text-gray-500'
}

const toDateStr = (d: Date) => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

const today = new Date()
const viewDate = ref(new Date(today.getFullYear(), today.getMonth(), 1))
const weekdayLabels = ['일', '월', '화', '수', '목', '금', '토']

const monthLabel = computed(() => `${viewDate.value.getFullYear()}년 ${viewDate.value.getMonth() + 1}월`)

const calendarCells = computed(() => {
  const year = viewDate.value.getFullYear()
  const month = viewDate.value.getMonth()
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)
  const startOffset = firstDay.getDay()

  const cells: { date: Date | null; dateStr: string | null }[] = []
  for (let i = 0; i < startOffset; i++) cells.push({ date: null, dateStr: null })
  for (let d = 1; d <= lastDay.getDate(); d++) {
    const date = new Date(year, month, d)
    cells.push({ date, dateStr: toDateStr(date) })
  }
  return cells
})

const reservationsByDate = computed(() => {
  const map: Record<string, any[]> = {}
  for (const r of props.reservations) {
    let cur = new Date(r.start_date)
    const end = new Date(r.end_date)
    while (cur <= end) {
      const key = toDateStr(cur)
      ;(map[key] ??= []).push(r)
      cur = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1)
    }
  }
  return map
})

const changeMonth = (offset: number) => {
  viewDate.value = new Date(viewDate.value.getFullYear(), viewDate.value.getMonth() + offset, 1)
}
</script>

<template>
  <div>
    <div class="mb-3 flex items-center justify-between">
      <button type="button" class="rounded-lg px-2 py-1 text-gray-500 hover:bg-gray-100" @click="changeMonth(-1)">
        ← 이전
      </button>
      <p class="font-semibold text-gray-900">{{ monthLabel }}</p>
      <button type="button" class="rounded-lg px-2 py-1 text-gray-500 hover:bg-gray-100" @click="changeMonth(1)">
        다음 →
      </button>
    </div>

    <div class="grid grid-cols-7 gap-1 text-center text-xs font-medium text-gray-400">
      <span v-for="w in weekdayLabels" :key="w">{{ w }}</span>
    </div>

    <div class="mt-1 grid grid-cols-7 gap-1">
      <div
        v-for="(cell, idx) in calendarCells"
        :key="idx"
        class="min-h-24 rounded-lg border border-gray-100 p-1"
        :class="!cell.date ? 'invisible' : ''"
      >
        <p class="mb-1 text-right text-xs text-gray-400">{{ cell.date?.getDate() }}</p>
        <div class="space-y-0.5">
          <NuxtLink
            v-for="r in (cell.dateStr ? reservationsByDate[cell.dateStr] ?? [] : []).slice(0, 3)"
            :key="r.id"
            :to="`/admin/reservations/${r.id}`"
            class="block truncate rounded px-1 py-0.5 text-[10px] font-medium"
            :class="statusColor[r.status] ?? 'bg-gray-100 text-gray-500'"
          >
            {{ typeLabel[r.type] }}·{{ r.pets?.name }}
          </NuxtLink>
          <p
            v-if="cell.dateStr && (reservationsByDate[cell.dateStr]?.length ?? 0) > 3"
            class="px-1 text-[10px] text-gray-400"
          >
            +{{ (reservationsByDate[cell.dateStr]?.length ?? 0) - 3 }}건 더
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
