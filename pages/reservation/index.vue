<script setup lang="ts">
import type { Pet, ReservationType } from '~/types/database.types'

definePageMeta({ middleware: 'auth' })

const router = useRouter()
const { fetchMyPets, createPet } = usePets()
const { createReservation } = useReservations()
const { isWarm } = useSiteTheme()

const reservationType = ref<ReservationType>('hotel')
const dateRange = ref<{ start: string | null; end: string | null }>({ start: null, end: null })

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

const startTimeLabel = computed(() => (reservationType.value === 'hotel' ? '체크인 시간' : '등원 시간'))
const endTimeLabel = computed(() => (reservationType.value === 'hotel' ? '체크아웃 시간' : '하원 시간'))

const myPets = ref<Pet[]>([])
const selectedPetId = ref<string>('new')

const newPet = reactive({
  name: '',
  breed: '',
  age: null as number | null,
  weight: null as number | null,
  isVaccinated: null as boolean | null,
  notes: ''
})

const memo = ref('')
const submitting = ref(false)
const errorMessage = ref('')

onMounted(async () => {
  myPets.value = await fetchMyPets()
  if (myPets.value.length > 0) selectedPetId.value = myPets.value[0].id
})

const isNewPet = computed(() => selectedPetId.value === 'new')

const summaryPetLabel = computed(() => {
  if (isNewPet.value) return newPet.name ? `${newPet.name} (신규 등록)` : '입력 전'
  return myPets.value.find((p) => p.id === selectedPetId.value)?.name ?? '입력 전'
})

const handleSubmit = async () => {
  errorMessage.value = ''

  if (!dateRange.value.start || !dateRange.value.end) {
    errorMessage.value = '이용 날짜를 선택해주세요.'
    return
  }
  if (dateRange.value.start === dateRange.value.end && endTime.value <= startTime.value) {
    errorMessage.value = `${endTimeLabel.value}은 ${startTimeLabel.value} 이후로 선택해주세요.`
    return
  }
  if (isNewPet.value && !newPet.name) {
    errorMessage.value = '반려동물 이름을 입력해주세요.'
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
        isVaccinated: newPet.isVaccinated ?? false,
        notes: newPet.notes
      })
      petId = created.id
      myPets.value = [created, ...myPets.value]
    }

    const created = await createReservation({
      petId,
      type: reservationType.value,
      startDate: dateRange.value.start,
      endDate: dateRange.value.end,
      startTime: startTime.value,
      endTime: endTime.value,
      memo: memo.value
    })

    await router.push(`/checkout/reservation?id=${created.id}`)
  } catch (e: any) {
    errorMessage.value = e?.message ?? '예약에 실패했습니다. 잠시 후 다시 시도해주세요.'
  } finally {
    submitting.value = false
  }
}

const dateSummary = computed(() =>
  dateRange.value.start ? `${dateRange.value.start} ~ ${dateRange.value.end ?? dateRange.value.start}` : '선택 전'
)
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
              v-for="opt in [{ v: 'hotel', icon: 'bed', label: '🏨 호텔 숙박' }, { v: 'daycare', icon: 'wb_sunny', label: '☀️ 데이케어' }]"
              :key="opt.v"
              type="button"
              class="flex h-full flex-col items-center justify-center gap-3 rounded-xl border-2 p-6 shadow-sm transition-all hover:-translate-y-1"
              :class="reservationType === opt.v
                ? 'border-secondary bg-secondary-fixed/30 text-secondary'
                : 'border-surface-container-high bg-surface-container-lowest text-on-surface-variant hover:border-secondary/50'"
              @click="reservationType = opt.v as ReservationType"
            >
              <span class="material-symbols-outlined text-4xl">{{ opt.icon }}</span>
              <span class="font-label-md text-label-md font-bold">{{ opt.label }}</span>
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
            체크인 날짜를 먼저 선택하고, 체크아웃 날짜를 다시 클릭해주세요.
          </div>

          <div class="rounded-xl border border-outline-variant/50 bg-surface p-4">
            <ReservationAvailabilityCalendar v-model="dateRange" :type="reservationType" warm />
          </div>
          <div class="mt-3 flex gap-4 font-body-md text-sm text-on-surface-variant">
            <span>체크인: <strong class="text-primary">{{ dateRange.start ?? '-' }}</strong></span>
            <span>체크아웃: <strong class="text-primary">{{ dateRange.end ?? '-' }}</strong></span>
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
                <label class="label-warm">백신 접종 여부</label>
                <div class="flex gap-4 font-body-md text-on-surface">
                  <label class="flex cursor-pointer items-center gap-2">
                    <input v-model="newPet.isVaccinated" :value="true" type="radio" name="w-vaccinated" class="text-secondary" /> 접종 완료
                  </label>
                  <label class="flex cursor-pointer items-center gap-2">
                    <input v-model="newPet.isVaccinated" :value="false" type="radio" name="w-vaccinated" class="text-secondary" /> 미접종
                  </label>
                </div>
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
      </div>

      <!-- 예약 요약 -->
      <div class="lg:col-span-4">
        <div class="sticky top-28 card-warm p-6 shadow-[0_8px_32px_rgba(93,64,36,0.08)]">
          <h3 class="mb-6 border-b border-outline-variant/30 pb-4 font-headline-md text-headline-md text-primary">예약 요약</h3>
          <ul class="mb-8 space-y-4">
            <li class="flex items-start justify-between">
              <span class="font-label-md text-label-md text-on-surface-variant">서비스</span>
              <span class="text-right font-body-md font-semibold text-on-surface">{{ reservationType === 'hotel' ? '호텔 숙박' : '데이케어' }}</span>
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
              🏨 호텔 숙박
            </button>
            <button
              type="button"
              class="rounded-lg border px-4 py-3 text-sm font-semibold transition"
              :class="reservationType === 'daycare' ? 'border-brand-500 bg-brand-50 text-brand-600' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
              @click="reservationType = 'daycare'"
            >
              ☀️ 데이케어
            </button>
          </div>
        </div>

        <!-- 날짜 선택 -->
        <div class="card">
          <p class="label-field mb-3">이용 날짜</p>
          <ReservationAvailabilityCalendar v-model="dateRange" :type="reservationType" />
          <div class="mt-3 flex gap-4 text-sm text-gray-600">
            <span>체크인: <strong>{{ dateRange.start ?? '-' }}</strong></span>
            <span>체크아웃: <strong>{{ dateRange.end ?? '-' }}</strong></span>
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
              <label class="label-field">백신 접종 여부</label>
              <div class="flex gap-4 text-sm text-gray-700">
                <label class="inline-flex items-center gap-2">
                  <input v-model="newPet.isVaccinated" :value="true" type="radio" name="vaccinated" class="text-brand-500" /> 접종 완료
                </label>
                <label class="inline-flex items-center gap-2">
                  <input v-model="newPet.isVaccinated" :value="false" type="radio" name="vaccinated" class="text-brand-500" /> 미접종
                </label>
              </div>
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
      </div>

      <!-- 예약 요약 -->
      <div class="lg:col-span-1">
        <div class="card sticky top-24 space-y-3">
          <p class="font-semibold text-gray-900">예약 요약</p>
          <div class="space-y-1 text-sm text-gray-500">
            <p>서비스: {{ reservationType === 'hotel' ? '호텔 숙박' : '데이케어' }}</p>
            <p>날짜: {{ dateSummary }}</p>
            <p>시간: {{ startTime }} ~ {{ endTime }}</p>
            <p>반려동물: {{ summaryPetLabel }}</p>
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
</template>
