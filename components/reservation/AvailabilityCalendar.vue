<script setup lang="ts">
import type { AvailabilityDay, ReservationType } from '~/types/database.types'

const props = withDefaults(
  defineProps<{
    type: ReservationType
    modelValue: { start: string | null; end: string | null }
    warm?: boolean
    single?: boolean // 하루만 선택 (데이케어)
  }>(),
  { warm: false, single: false }
)

const emit = defineEmits<{
  'update:modelValue': [{ start: string | null; end: string | null }]
}>()

const { getAvailability } = useReservations()

const toDateStr = (d: Date) => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

const today = new Date()
today.setHours(0, 0, 0, 0)
const todayStr = toDateStr(today)

const viewDate = ref(new Date(today.getFullYear(), today.getMonth(), 1))
const availability = ref<Record<string, AvailabilityDay>>({})
const loading = ref(false)

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

const loadAvailability = async () => {
  loading.value = true
  try {
    const year = viewDate.value.getFullYear()
    const month = viewDate.value.getMonth()
    const start = toDateStr(new Date(year, month, 1))
    const end = toDateStr(new Date(year, month + 1, 0))
    const days = await getAvailability(props.type, start, end)
    availability.value = Object.fromEntries(days.map((d) => [d.date, d]))
  } finally {
    loading.value = false
  }
}

watch([() => props.type, viewDate], loadAvailability, { immediate: true })

const changeMonth = (offset: number) => {
  viewDate.value = new Date(viewDate.value.getFullYear(), viewDate.value.getMonth() + offset, 1)
}

const isPast = (dateStr: string) => dateStr < todayStr
const isFull = (dateStr: string) => {
  const info = availability.value[dateStr]
  return info ? info.remaining <= 0 : false
}
const isDisabled = (dateStr: string) => isPast(dateStr) || isFull(dateStr)

const isSelected = (dateStr: string) => {
  const { start, end } = props.modelValue
  if (!start) return false
  if (!end) return dateStr === start
  return dateStr >= start && dateStr <= end
}

const isRangeEdge = (dateStr: string) => dateStr === props.modelValue.start || dateStr === props.modelValue.end

// 테마별 색상 클래스
const ui = computed(() =>
  props.warm
    ? {
        nav: 'rounded-lg px-2 py-1 text-on-surface-variant hover:bg-surface-container-high',
        month: 'font-label-md text-primary',
        weekday: 'text-on-surface-variant/70',
        selected: 'border-primary bg-primary text-on-primary',
        idle: 'border-outline-variant/60 text-on-surface hover:bg-surface-container-high',
        disabled: '!border-surface-container !bg-surface-container/50 !text-on-surface-variant/30 cursor-not-allowed',
        hint: 'text-outline'
      }
    : {
        nav: 'rounded-lg px-2 py-1 text-gray-500 hover:bg-gray-100',
        month: 'font-semibold text-gray-900',
        weekday: 'text-gray-400',
        selected: 'border-brand-500 bg-brand-500 text-white',
        idle: 'border-gray-200 text-gray-700 hover:bg-gray-50',
        disabled: '!border-gray-100 !bg-gray-50 !text-gray-300 cursor-not-allowed',
        hint: 'text-gray-400'
      }
)

const handleClick = (dateStr: string | null) => {
  if (!dateStr || isDisabled(dateStr)) return

  if (props.single) {
    emit('update:modelValue', { start: dateStr, end: dateStr })
    return
  }

  const { start, end } = props.modelValue
  if (!start || end) {
    emit('update:modelValue', { start: dateStr, end: null })
  } else if (dateStr < start) {
    emit('update:modelValue', { start: dateStr, end: null })
  } else {
    emit('update:modelValue', { start, end: dateStr })
  }
}
</script>

<template>
  <div>
    <div class="mb-3 flex items-center justify-between">
      <button type="button" :class="ui.nav" @click="changeMonth(-1)">← 이전</button>
      <p :class="ui.month">{{ monthLabel }}</p>
      <button type="button" :class="ui.nav" @click="changeMonth(1)">다음 →</button>
    </div>

    <div class="grid grid-cols-7 gap-1 text-center text-xs font-medium" :class="ui.weekday">
      <span v-for="w in weekdayLabels" :key="w">{{ w }}</span>
    </div>

    <div class="mt-1 grid grid-cols-7 gap-1">
      <button
        v-for="(cell, idx) in calendarCells"
        :key="idx"
        type="button"
        class="flex aspect-square flex-col items-center justify-center rounded-lg border text-sm transition"
        :disabled="!cell.dateStr || isDisabled(cell.dateStr)"
        :class="[
          !cell.date ? 'invisible' : '',
          cell.dateStr && isSelected(cell.dateStr) ? ui.selected : ui.idle,
          cell.dateStr && isRangeEdge(cell.dateStr) ? 'font-bold' : '',
          cell.dateStr && isDisabled(cell.dateStr) ? ui.disabled : ''
        ]"
        @click="handleClick(cell.dateStr)"
      >
        <span>{{ cell.date?.getDate() }}</span>
        <span
          v-if="cell.dateStr && !isPast(cell.dateStr) && availability[cell.dateStr]"
          class="text-[10px] leading-tight"
          :class="isSelected(cell.dateStr) ? 'text-white/80' : isFull(cell.dateStr) ? 'text-red-400' : 'opacity-60'"
        >
          {{ isFull(cell.dateStr) ? '마감' : `여유 ${availability[cell.dateStr].remaining}` }}
        </span>
      </button>
    </div>

    <p v-if="loading" class="mt-2 text-center text-xs" :class="ui.hint">예약 현황 불러오는 중...</p>
    <p class="mt-3 text-xs" :class="ui.hint">
      {{ single ? '이용하실 날짜 하루를 선택해주세요.' : '체크인 날짜를 먼저 선택하고, 체크아웃 날짜를 다시 클릭해주세요.' }}
    </p>
  </div>
</template>
