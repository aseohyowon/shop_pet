<script setup lang="ts">
import type { Pet, ReservationType } from '~/types/database.types'
import { RESERVATION_AGREEMENTS, type Agreement } from '~/utils/reservationAgreements'

definePageMeta({ middleware: 'auth' })

const router = useRouter()
const { fetchMyPets, createPet } = usePets()
const { createReservation } = useReservations()
const { fetchServiceSettings, nights } = useServiceSettings()
const { isWarm } = useSiteTheme()

const { data: serviceSettings } = useAsyncData('service-settings', fetchServiceSettings, { default: () => ({}) as any })

const reservationType = ref<ReservationType>('hotel')
const dateRange = ref<{ start: string | null; end: string | null }>({ start: null, end: null })

const isDaycare = computed(() => reservationType.value === 'daycare')

// 데이케어(원데이)는 하루만: 서비스 전환 시 범위를 당일로 축소
watch(reservationType, () => {
  if (isDaycare.value && dateRange.value.start) {
    dateRange.value = { start: dateRange.value.start, end: dateRange.value.start }
  }
})

// 운영 시간(09:00~21:00) 내 30분 단위 옵션
const timeOptions = computed(() => {
  const options: string[] = []
  for (let minutes = 9 * 60; minutes <= 21 * 60; minutes += 30) {
    const h = String(Math.floor(minutes / 60)).padStart(2, '0')
    const m = String(minutes % 60).padStart(2, '0')
    options.push(`${h}:${m}`)
  }
  return options
})

const startTime = ref('09:00')
const endTime = ref('21:00')

const startTimeLabel = computed(() => (isDaycare.value ? '등원 시간' : '체크인 시간'))
const endTimeLabel = computed(() => (isDaycare.value ? '하원 시간' : '체크아웃 시간'))

const myPets = ref<Pet[]>([])
const selectedPetId = ref<string>('new')

const newPet = reactive({
  name: '',
  breed: '',
  age: null as number | null,
  weight: null as number | null,
  registrationNo: '',
  vaccinations: [] as number[],
  rulesAgreed: false,
  notes: ''
})

// 접종 현황 / 규정 동의 모달
const showVaccineModal = ref(false)
const vaccineDraft = reactive<Record<number, boolean>>({ 1: false, 2: false, 3: false, 4: false, 5: false })
const rulesDraft = ref(false)

const openVaccineModal = () => {
  for (const n of [1, 2, 3, 4, 5]) vaccineDraft[n] = newPet.vaccinations.includes(n)
  rulesDraft.value = newPet.rulesAgreed
  showVaccineModal.value = true
}
const confirmVaccine = () => {
  if (!rulesDraft.value) return
  newPet.vaccinations = [1, 2, 3, 4, 5].filter((n) => vaccineDraft[n])
  newPet.rulesAgreed = true
  showVaccineModal.value = false
}
const vaccineSummaryText = computed(() =>
  newPet.rulesAgreed ? `예방접종 ${newPet.vaccinations.length}/5 · 규정 동의 완료` : '작성 필요 (필수)'
)

const memo = ref('')
const submitting = ref(false)
const errorMessage = ref('')

// 예약 시 약관 동의 (이용약관 / 개인정보 수집·이용 / 제3자 제공)
const agreements = reactive<Record<Agreement['id'], boolean>>({ terms: false, privacy: false, thirdparty: false })
const allAgreed = computed(() => RESERVATION_AGREEMENTS.every((a) => agreements[a.id]))
const toggleAllAgreements = (v: boolean) => {
  for (const a of RESERVATION_AGREEMENTS) agreements[a.id] = v
}
const activeAgreement = ref<Agreement | null>(null)

onMounted(async () => {
  myPets.value = await fetchMyPets()
  if (myPets.value.length > 0) selectedPetId.value = myPets.value[0].id
})

const isNewPet = computed(() => selectedPetId.value === 'new')

const summaryPetLabel = computed(() => {
  if (isNewPet.value) return newPet.name ? `${newPet.name} (신규 등록)` : '입력 전'
  return myPets.value.find((p) => p.id === selectedPetId.value)?.name ?? '입력 전'
})

const dateSummary = computed(() => {
  const { start, end } = dateRange.value
  if (!start) return '선택 전'
  if (!end || end === start) return start
  return `${start} ~ ${end}`
})

// 예상 금액 (호텔: 박 수 × 1박 요금, 데이케어: 1일 요금)
const priceUnits = computed(() => {
  const { start, end } = dateRange.value
  if (!start) return 0
  if (isDaycare.value) return 1
  return nights(start, end ?? start)
})
const estimatedPrice = computed(() => {
  const s = serviceSettings.value?.[reservationType.value]
  if (!s || !dateRange.value.start) return null
  return Math.round(s.price * priceUnits.value * Number(s.deposit_rate ?? 1))
})
const priceBreakdown = computed(() => {
  const s = serviceSettings.value?.[reservationType.value]
  if (!s || !dateRange.value.start) return ''
  const unit = isDaycare.value ? '1일' : `${priceUnits.value}박`
  const rate = Number(s.deposit_rate ?? 1)
  const base = `${s.price.toLocaleString()}원 × ${unit}`
  return rate < 1 ? `${base} · 예약금 ${Math.round(rate * 100)}%` : base
})

const handleSubmit = async () => {
  errorMessage.value = ''

  if (!dateRange.value.start) {
    errorMessage.value = '이용 날짜를 선택해주세요.'
    return
  }
  if (!isDaycare.value && !dateRange.value.end) {
    errorMessage.value = '체크아웃 날짜를 선택해주세요.'
    return
  }
  const endDate = isDaycare.value ? dateRange.value.start : dateRange.value.end!
  if (dateRange.value.start === endDate && endTime.value <= startTime.value) {
    errorMessage.value = `${endTimeLabel.value}은 ${startTimeLabel.value} 이후로 선택해주세요.`
    return
  }
  if (isNewPet.value && !newPet.name) {
    errorMessage.value = '반려동물 이름을 입력해주세요.'
    return
  }
  if (isNewPet.value && !newPet.rulesAgreed) {
    errorMessage.value = '접종 현황 및 이용 규정 동의를 완료해주세요.'
    return
  }
  if (!allAgreed.value) {
    errorMessage.value = '이용약관 및 개인정보 관련 항목에 모두 동의해주세요.'
    return
  }

  submitting.value = true
  try {
    let petId = selectedPetId.value
    if (isNewPet.value) {
      const created = await createPet({
        name: newPet.name,
        breed: newPet.breed,
        age: newPet.age,
        weight: newPet.weight,
        vaccinations: newPet.vaccinations,
        rulesAgreed: newPet.rulesAgreed,
        registrationNo: newPet.registrationNo,
        notes: newPet.notes
      })
      petId = created.id
      myPets.value = [created, ...myPets.value]
    }

    const created = await createReservation({
      petId,
      type: reservationType.value,
      startDate: dateRange.value.start,
      endDate,
      startTime: startTime.value,
      endTime: endTime.value,
      memo: memo.value,
      termsAgreed: allAgreed.value
    })

    await router.push(`/checkout/reservation?id=${created.id}`)
  } catch (e: any) {
    errorMessage.value = e?.message ?? '예약에 실패했습니다. 잠시 후 다시 시도해주세요.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <!-- ══════════ Warm 테마 ══════════ -->
  <div v-if="isWarm" class="container-warm py-12">
    <div class="mb-12">
      <h1 class="mb-4 font-headline-xl text-[36px] text-primary md:text-headline-xl">예약하기</h1>
      <p class="font-body-lg text-body-lg text-on-surface-variant">
        이용하실 서비스를 선택하고 날짜와 반려동물 정보를 입력해주세요.
      </p>
    </div>

    <div class="grid grid-cols-1 gap-gutter lg:grid-cols-12">
      <div class="space-y-12 lg:col-span-8">
        <!-- 서비스 선택 -->
        <section class="card-warm p-8">
          <h2 class="mb-6 flex items-center gap-3 font-headline-md text-headline-md text-primary">
            <span class="material-symbols-outlined rounded-full bg-secondary-container p-2 text-secondary">hotel</span>
            서비스 선택
          </h2>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <button
              v-for="opt in [{ v: 'hotel', icon: 'bed', label: '🏨 호텔 숙박', desc: '1박 이상' }, { v: 'daycare', icon: 'wb_sunny', label: '☀️ 데이케어', desc: '당일 (원데이)' }]"
              :key="opt.v"
              type="button"
              class="flex h-full flex-col items-center justify-center gap-1 rounded-xl border-2 p-6 shadow-sm transition-all hover:-translate-y-1"
              :class="reservationType === opt.v
                ? 'border-secondary bg-secondary-fixed/30 text-secondary'
                : 'border-surface-container-high bg-surface-container-lowest text-on-surface-variant hover:border-secondary/50'"
              @click="reservationType = opt.v as ReservationType"
            >
              <span class="material-symbols-outlined text-4xl">{{ opt.icon }}</span>
              <span class="mt-2 font-label-md text-label-md font-bold">{{ opt.label }}</span>
              <span class="font-label-sm text-label-sm opacity-70">{{ opt.desc }}</span>
            </button>
          </div>
        </section>

        <!-- 일정 선택 -->
        <section class="card-warm p-8">
          <h2 class="mb-6 flex items-center gap-3 font-headline-md text-headline-md text-primary">
            <span class="material-symbols-outlined rounded-full bg-secondary-container p-2 text-secondary">calendar_month</span>
            일정 선택
          </h2>
          <div class="mb-6 flex items-center gap-2 rounded-lg bg-surface-container-low p-4 font-body-md text-body-md text-on-surface-variant">
            <span class="material-symbols-outlined text-sm text-secondary">info</span>
            {{ isDaycare ? '이용하실 날짜 하루를 선택해주세요.' : '체크인 날짜를 먼저 선택하고, 체크아웃 날짜를 다시 클릭해주세요.' }}
          </div>

          <div class="rounded-xl border border-outline-variant/50 bg-surface p-4">
            <ReservationAvailabilityCalendar v-model="dateRange" :type="reservationType" :single="isDaycare" warm />
          </div>
          <div class="mt-3 flex gap-4 font-body-md text-sm text-on-surface-variant">
            <span v-if="isDaycare">이용일: <strong class="text-primary">{{ dateRange.start ?? '-' }}</strong></span>
            <template v-else>
              <span>체크인: <strong class="text-primary">{{ dateRange.start ?? '-' }}</strong></span>
              <span>체크아웃: <strong class="text-primary">{{ dateRange.end ?? '-' }}</strong></span>
            </template>
          </div>

          <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div class="space-y-2">
              <label class="label-warm" for="w-start-time">{{ startTimeLabel }}</label>
              <select id="w-start-time" v-model="startTime" class="input-warm h-12">
                <option v-for="t in timeOptions" :key="t" :value="t">{{ t }}</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="label-warm" for="w-end-time">{{ endTimeLabel }}</label>
              <select id="w-end-time" v-model="endTime" class="input-warm h-12">
                <option v-for="t in timeOptions" :key="t" :value="t">{{ t }}</option>
              </select>
            </div>
          </div>
          <p class="mt-3 flex items-center gap-1 font-label-sm text-label-sm text-outline">
            <span class="material-symbols-outlined text-[16px]">schedule</span>
            운영 시간은 09:00 ~ 21:00 입니다.
          </p>
        </section>

        <!-- 반려동물 정보 -->
        <section class="card-warm p-8">
          <div class="mb-6 flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
            <h2 class="flex items-center gap-3 font-headline-md text-headline-md text-primary">
              <span class="material-symbols-outlined rounded-full bg-secondary-container p-2 text-secondary">pets</span>
              반려동물 정보
            </h2>
          </div>

          <div class="space-y-6">
            <div v-if="myPets.length > 0" class="space-y-2">
              <label class="label-warm" for="w-pet-select">등록된 반려동물 선택</label>
              <select id="w-pet-select" v-model="selectedPetId" class="input-warm h-12">
                <option v-for="p in myPets" :key="p.id" :value="p.id">{{ p.name }} ({{ p.breed || '견종 미입력' }})</option>
                <option value="new">+ 새 반려동물 등록</option>
              </select>
            </div>

            <div v-if="isNewPet" class="space-y-4 rounded-xl border border-outline-variant/50 p-6">
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div class="space-y-2">
                  <label class="label-warm" for="w-pet-name">이름</label>
                  <input id="w-pet-name" v-model="newPet.name" type="text" class="input-warm h-12" placeholder="이름 입력" />
                </div>
                <div class="space-y-2">
                  <label class="label-warm" for="w-pet-breed">견종</label>
                  <input id="w-pet-breed" v-model="newPet.breed" type="text" class="input-warm h-12" placeholder="견종 입력" />
                </div>
                <div class="space-y-2">
                  <label class="label-warm" for="w-pet-age">나이</label>
                  <input id="w-pet-age" v-model.number="newPet.age" type="number" min="0" class="input-warm h-12" placeholder="나이 입력" />
                </div>
                <div class="space-y-2">
                  <label class="label-warm" for="w-pet-weight">체중 (kg)</label>
                  <input id="w-pet-weight" v-model.number="newPet.weight" type="number" min="0" step="0.1" class="input-warm h-12" placeholder="체중 입력" />
                </div>
              </div>
              <div class="space-y-2 pt-2">
                <label class="label-warm" for="w-pet-regno">동물등록번호</label>
                <input id="w-pet-regno" v-model="newPet.registrationNo" type="text" class="input-warm h-12" placeholder="동물등록번호 (선택, 15자리)" />
              </div>
              <div class="space-y-2 pt-2">
                <label class="label-warm">접종 현황 및 규정 동의</label>
                <button
                  type="button"
                  class="flex w-full items-center justify-between rounded-lg border px-4 py-3 text-left font-body-md transition-colors"
                  :class="newPet.rulesAgreed
                    ? 'border-green-300 bg-green-50 text-green-700'
                    : 'border-secondary/40 bg-secondary-fixed/20 text-secondary'"
                  @click="openVaccineModal"
                >
                  <span>{{ vaccineSummaryText }}</span>
                  <span class="material-symbols-outlined text-[20px]">{{ newPet.rulesAgreed ? 'check_circle' : 'chevron_right' }}</span>
                </button>
              </div>
              <div class="space-y-2 pt-2">
                <label class="label-warm" for="w-pet-notes">특이사항 및 요청사항</label>
                <textarea id="w-pet-notes" v-model="newPet.notes" rows="3" class="input-warm resize-none" placeholder="알러지, 복용 중인 약, 주의해야 할 행동 등 특이사항이나 요청사항을 적어주세요." />
              </div>
            </div>

            <div class="space-y-2">
              <label class="label-warm" for="w-memo">요청사항</label>
              <textarea id="w-memo" v-model="memo" rows="2" class="input-warm resize-none" placeholder="전달하고 싶은 내용이 있다면 입력해주세요" />
            </div>
          </div>
        </section>

        <!-- 약관 동의 -->
        <section class="card-warm p-8">
          <h2 class="mb-6 flex items-center gap-3 font-headline-md text-headline-md text-primary">
            <span class="material-symbols-outlined rounded-full bg-secondary-container p-2 text-secondary">verified_user</span>
            약관 동의
          </h2>
          <label class="mb-3 flex cursor-pointer items-center gap-3 rounded-lg bg-secondary-fixed/20 px-4 py-3">
            <input
              type="checkbox"
              class="h-5 w-5 rounded border-outline text-secondary"
              :checked="allAgreed"
              @change="toggleAllAgreements(($event.target as HTMLInputElement).checked)"
            />
            <span class="font-label-md text-label-md font-bold text-primary">아래 항목에 모두 동의합니다.</span>
          </label>
          <div class="space-y-1">
            <div v-for="a in RESERVATION_AGREEMENTS" :key="a.id" class="flex items-center justify-between gap-3 px-4 py-2">
              <label class="flex cursor-pointer items-center gap-3 font-body-md text-body-md text-on-surface-variant">
                <input v-model="agreements[a.id]" type="checkbox" class="h-5 w-5 rounded border-outline text-secondary" />
                <span>{{ a.label }}</span>
              </label>
              <button type="button" class="shrink-0 font-label-sm text-label-sm text-secondary underline" @click="activeAgreement = a">
                전문 보기
              </button>
            </div>
          </div>
        </section>
      </div>

      <!-- 예약 요약 -->
      <div class="lg:col-span-4">
        <div class="sticky top-28 card-warm p-6 shadow-[0_8px_32px_rgba(93,64,36,0.08)]">
          <h3 class="mb-6 border-b border-outline-variant/30 pb-4 font-headline-md text-headline-md text-primary">예약 요약</h3>
          <ul class="mb-8 space-y-4">
            <li class="flex items-start justify-between">
              <span class="font-label-md text-label-md text-on-surface-variant">서비스</span>
              <span class="text-right font-body-md font-semibold text-on-surface">{{ isDaycare ? '데이케어 (당일)' : '호텔 숙박' }}</span>
            </li>
            <li class="flex items-start justify-between">
              <span class="font-label-md text-label-md text-on-surface-variant">날짜</span>
              <span class="text-right font-body-md font-semibold" :class="dateRange.start ? 'text-on-surface' : 'text-outline'">{{ dateSummary }}</span>
            </li>
            <li class="flex items-start justify-between">
              <span class="font-label-md text-label-md text-on-surface-variant">시간</span>
              <span class="text-right font-body-md font-semibold text-on-surface">{{ startTime }} ~ {{ endTime }}</span>
            </li>
            <li class="flex items-start justify-between">
              <span class="font-label-md text-label-md text-on-surface-variant">반려동물</span>
              <span class="text-right font-body-md font-semibold" :class="summaryPetLabel === '입력 전' ? 'text-outline' : 'text-on-surface'">{{ summaryPetLabel }}</span>
            </li>
            <li class="flex items-start justify-between border-t border-outline-variant/30 pt-4">
              <span class="font-label-md text-label-md text-on-surface-variant">예상 금액</span>
              <span class="text-right">
                <span class="block font-headline-md text-headline-md text-primary">
                  {{ estimatedPrice != null ? `${estimatedPrice.toLocaleString()}원` : '날짜 선택 시 표시' }}
                </span>
                <span v-if="priceBreakdown" class="block font-label-sm text-label-sm text-on-surface-variant">{{ priceBreakdown }}</span>
              </span>
            </li>
          </ul>

          <p v-if="errorMessage" class="mb-3 font-body-md text-sm text-error">{{ errorMessage }}</p>

          <div class="space-y-3">
            <button
              type="button"
              class="flex h-14 w-full items-center justify-center gap-2 rounded-xl bg-primary-container font-headline-md text-[18px] text-on-primary shadow-md transition-all hover:-translate-y-1 hover:bg-primary disabled:cursor-not-allowed disabled:opacity-60"
              :disabled="submitting"
              @click="handleSubmit"
            >
              {{ submitting ? '신청 중...' : '예약 신청하기' }}
            </button>
            <NuxtLink to="/mypage/reservations" class="block py-2 text-center font-label-md text-label-md text-secondary hover:text-secondary/80">
              내 예약 내역 보기 →
            </NuxtLink>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ 기본 테마 ══════════ -->
  <div v-else class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">예약하기</h1>
    <p class="mb-8 text-gray-500">이용하실 서비스를 선택하고 날짜와 반려동물 정보를 입력해주세요.</p>

    <div class="grid gap-8 lg:grid-cols-3">
      <div class="space-y-6 lg:col-span-2">
        <!-- 서비스 선택 -->
        <div class="card">
          <p class="label-field mb-3">서비스 종류</p>
          <div class="grid grid-cols-2 gap-3">
            <button
              type="button"
              class="rounded-lg border px-4 py-3 text-sm font-semibold transition"
              :class="reservationType === 'hotel' ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
              @click="reservationType = 'hotel'"
            >
              🏨 호텔 숙박<span class="ml-1 text-xs font-normal text-gray-400">1박 이상</span>
            </button>
            <button
              type="button"
              class="rounded-lg border px-4 py-3 text-sm font-semibold transition"
              :class="reservationType === 'daycare' ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
              @click="reservationType = 'daycare'"
            >
              ☀️ 데이케어<span class="ml-1 text-xs font-normal text-gray-400">당일</span>
            </button>
          </div>
        </div>

        <!-- 날짜 선택 -->
        <div class="card">
          <p class="label-field mb-3">이용 날짜</p>
          <ReservationAvailabilityCalendar v-model="dateRange" :type="reservationType" :single="isDaycare" />
          <div class="mt-3 flex gap-4 text-sm text-gray-600">
            <span v-if="isDaycare">이용일: <strong>{{ dateRange.start ?? '-' }}</strong></span>
            <template v-else>
              <span>체크인: <strong>{{ dateRange.start ?? '-' }}</strong></span>
              <span>체크아웃: <strong>{{ dateRange.end ?? '-' }}</strong></span>
            </template>
          </div>

          <div class="mt-4 grid grid-cols-2 gap-4 border-t border-gray-100 pt-4">
            <div>
              <label class="label-field" for="start-time">{{ startTimeLabel }}</label>
              <select id="start-time" v-model="startTime" class="input-field">
                <option v-for="t in timeOptions" :key="t" :value="t">{{ t }}</option>
              </select>
            </div>
            <div>
              <label class="label-field" for="end-time">{{ endTimeLabel }}</label>
              <select id="end-time" v-model="endTime" class="input-field">
                <option v-for="t in timeOptions" :key="t" :value="t">{{ t }}</option>
              </select>
            </div>
          </div>
          <p class="mt-2 text-xs text-gray-400">운영 시간은 09:00 ~ 21:00 입니다.</p>
        </div>

        <!-- 반려동물 정보 -->
        <div class="card">
          <p class="label-field mb-3">반려동물 정보</p>

          <div v-if="myPets.length > 0" class="mb-4">
            <label class="label-field" for="pet-select">반려동물 선택</label>
            <select id="pet-select" v-model="selectedPetId" class="input-field">
              <option v-for="p in myPets" :key="p.id" :value="p.id">{{ p.name }} ({{ p.breed || '견종 미입력' }})</option>
              <option value="new">+ 새 반려동물 등록</option>
            </select>
          </div>

          <div v-if="isNewPet" class="grid gap-4 sm:grid-cols-2">
            <div>
              <label class="label-field" for="pet-name">이름</label>
              <input id="pet-name" v-model="newPet.name" type="text" class="input-field" placeholder="초코" />
            </div>
            <div>
              <label class="label-field" for="pet-breed">견종</label>
              <input id="pet-breed" v-model="newPet.breed" type="text" class="input-field" placeholder="말티즈" />
            </div>
            <div>
              <label class="label-field" for="pet-age">나이</label>
              <input id="pet-age" v-model.number="newPet.age" type="number" min="0" class="input-field" placeholder="3" />
            </div>
            <div>
              <label class="label-field" for="pet-weight">체중 (kg)</label>
              <input id="pet-weight" v-model.number="newPet.weight" type="number" min="0" step="0.1" class="input-field" placeholder="4.5" />
            </div>
            <div class="sm:col-span-2">
              <label class="label-field" for="pet-regno">동물등록번호</label>
              <input id="pet-regno" v-model="newPet.registrationNo" type="text" class="input-field" placeholder="동물등록번호 (선택, 15자리)" />
            </div>
            <div class="sm:col-span-2">
              <label class="label-field">접종 현황 및 규정 동의</label>
              <button
                type="button"
                class="flex w-full items-center justify-between rounded-lg border px-4 py-3 text-left text-sm font-medium transition"
                :class="newPet.rulesAgreed
                  ? 'border-green-300 bg-green-50 text-green-700'
                  : 'border-brand-300 bg-brand-50 text-brand-600'"
                @click="openVaccineModal"
              >
                <span>{{ vaccineSummaryText }}</span>
                <span aria-hidden="true">{{ newPet.rulesAgreed ? '✓' : '›' }}</span>
              </button>
            </div>
            <div class="sm:col-span-2">
              <label class="label-field" for="pet-notes">특이사항</label>
              <textarea id="pet-notes" v-model="newPet.notes" rows="3" class="input-field" placeholder="알레르기, 성격, 주의사항 등을 입력해주세요" />
            </div>
          </div>

          <div class="mt-4">
            <label class="label-field" for="memo">요청사항</label>
            <textarea id="memo" v-model="memo" rows="2" class="input-field" placeholder="전달하고 싶은 내용이 있다면 입력해주세요" />
          </div>
        </div>

        <!-- 약관 동의 -->
        <div class="card">
          <p class="label-field mb-3">약관 동의</p>
          <label class="mb-2 flex cursor-pointer items-center gap-2.5 rounded-lg bg-brand-50 px-3 py-2.5">
            <input
              type="checkbox"
              class="h-4 w-4 rounded border-gray-300 text-brand-500"
              :checked="allAgreed"
              @change="toggleAllAgreements(($event.target as HTMLInputElement).checked)"
            />
            <span class="text-sm font-semibold text-gray-900">아래 항목에 모두 동의합니다.</span>
          </label>
          <div class="divide-y divide-gray-100">
            <div v-for="a in RESERVATION_AGREEMENTS" :key="a.id" class="flex items-center justify-between gap-3 py-2">
              <label class="flex cursor-pointer items-center gap-2.5 text-sm text-gray-600">
                <input v-model="agreements[a.id]" type="checkbox" class="h-4 w-4 rounded border-gray-300 text-brand-500" />
                <span>{{ a.label }}</span>
              </label>
              <button type="button" class="shrink-0 text-xs text-brand-600 underline" @click="activeAgreement = a">
                전문 보기
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 예약 요약 -->
      <div class="lg:col-span-1">
        <div class="card sticky top-24 space-y-3">
          <p class="font-semibold text-gray-900">예약 요약</p>
          <div class="space-y-1 text-sm text-gray-500">
            <p>서비스: {{ isDaycare ? '데이케어 (당일)' : '호텔 숙박' }}</p>
            <p>날짜: {{ dateSummary }}</p>
            <p>시간: {{ startTime }} ~ {{ endTime }}</p>
            <p>반려동물: {{ summaryPetLabel }}</p>
          </div>
          <div class="flex items-baseline justify-between border-t border-gray-100 pt-3">
            <span class="text-sm text-gray-500">예상 금액</span>
            <span class="text-right">
              <span class="block font-bold text-brand-600">
                {{ estimatedPrice != null ? `${estimatedPrice.toLocaleString()}원` : '날짜 선택 시' }}
              </span>
              <span v-if="priceBreakdown" class="block text-xs text-gray-400">{{ priceBreakdown }}</span>
            </span>
          </div>

          <p v-if="errorMessage" class="text-sm text-red-500">{{ errorMessage }}</p>

          <button type="button" class="btn-primary w-full" :disabled="submitting" @click="handleSubmit">
            {{ submitting ? '신청 중...' : '예약 신청하기' }}
          </button>
          <NuxtLink to="/mypage/reservations" class="block text-center text-xs text-gray-400 hover:text-brand-600">
            내 예약 내역 보기 →
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>

  <!-- ══════════ 접종 현황 / 규정 동의 모달 ══════════ -->
  <Teleport to="body">
    <div
      v-if="showVaccineModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      @click.self="showVaccineModal = false"
    >
      <div class="flex max-h-[88vh] w-full max-w-lg flex-col overflow-hidden rounded-2xl bg-white shadow-xl">
        <div class="border-b border-gray-100 px-6 py-4">
          <h3 class="text-lg font-bold text-gray-900">접종 현황 및 이용 규정 동의</h3>
          <p class="mt-0.5 text-sm text-gray-500">완료한 예방접종에 체크하고, 이용 규정을 확인한 뒤 동의해주세요.</p>
        </div>

        <div class="flex-1 space-y-5 overflow-y-auto px-6 py-5">
          <!-- 예방접종 -->
          <div>
            <p class="mb-2 text-sm font-semibold text-gray-900">예방접종 현황</p>
            <div class="space-y-2">
              <label
                v-for="n in 5"
                :key="n"
                class="flex cursor-pointer items-center gap-3 rounded-lg border border-gray-200 px-3 py-2.5 hover:bg-gray-50"
              >
                <input
                  type="checkbox"
                  :checked="vaccineDraft[n]"
                  class="h-5 w-5 rounded border-gray-300 text-brand-500 focus:ring-brand-500"
                  @change="vaccineDraft[n] = ($event.target as HTMLInputElement).checked"
                />
                <span class="text-sm text-gray-800">예방접종 {{ n }}차</span>
              </label>
            </div>
          </div>

          <!-- 이용 규정 -->
          <div>
            <p class="mb-2 text-sm font-semibold text-gray-900">예약 서비스 이용 규정</p>
            <div class="max-h-64 space-y-3 overflow-y-auto rounded-lg border border-gray-200 bg-gray-50 p-4 text-xs leading-relaxed text-gray-600">
              <p v-for="rule in RESERVATION_RULES" :key="rule.no">
                <span class="font-semibold text-gray-800">{{ rule.no }}. {{ rule.title }}</span><br />
                {{ rule.body }}
              </p>
              <p class="border-t border-gray-200 pt-2 text-gray-400">
                전체 약관은
                <NuxtLink to="/terms" target="_blank" class="text-brand-600 underline">이용약관</NuxtLink> ·
                <NuxtLink to="/privacy" target="_blank" class="text-brand-600 underline">개인정보처리방침</NuxtLink>에서 확인하실 수 있습니다.
              </p>
            </div>
          </div>
        </div>

        <div class="border-t border-gray-100 px-6 py-4">
          <label class="mb-3 flex cursor-pointer items-start gap-3 rounded-lg bg-brand-50 p-3">
            <input v-model="rulesDraft" type="checkbox" class="mt-0.5 h-5 w-5 rounded border-gray-300 text-brand-500 focus:ring-brand-500" />
            <span class="text-sm text-gray-800">
              위 예약 서비스 이용 규정 및 약관을 모두 확인했으며 이에 <strong>동의합니다.</strong>
              <span class="font-semibold text-red-500">(필수)</span>
            </span>
          </label>
          <div class="flex gap-2">
            <button type="button" class="btn-secondary flex-1" @click="showVaccineModal = false">취소</button>
            <button type="button" class="btn-primary flex-1" :disabled="!rulesDraft" @click="confirmVaccine">확인</button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>

  <!-- ══════════ 약관 전문 모달 ══════════ -->
  <Teleport to="body">
    <div
      v-if="activeAgreement"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      @click.self="activeAgreement = null"
    >
      <div class="flex max-h-[88vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl bg-white shadow-xl">
        <div class="flex items-start justify-between border-b border-gray-100 px-6 py-4">
          <h3 class="text-lg font-bold text-gray-900">{{ activeAgreement.title }}</h3>
          <button type="button" class="text-gray-400 hover:text-gray-600" @click="activeAgreement = null">✕</button>
        </div>
        <div class="flex-1 overflow-y-auto px-6 py-5">
          <p class="whitespace-pre-line text-[13px] leading-relaxed text-gray-700">{{ activeAgreement.body }}</p>
        </div>
        <div class="border-t border-gray-100 px-6 py-4">
          <button
            type="button"
            class="btn-primary w-full"
            @click="agreements[activeAgreement.id] = true; activeAgreement = null"
          >
            확인하고 동의
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
