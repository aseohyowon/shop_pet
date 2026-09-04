<script setup lang="ts">
import type { Profile, VaccineStatus } from '~/types/database.types'
import { VACCINE_NOS } from '~/utils/vaccines'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchCustomers, fetchCustomerDetail } = useCustomers()
const { setVaccineStatus } = usePets()

const customers = ref<Profile[]>([])
const loading = ref(true)
const keyword = ref('')

const expandedId = ref<string | null>(null)
const details = reactive<Record<string, Awaited<ReturnType<typeof fetchCustomerDetail>>>>({})
const detailLoading = ref<string | null>(null)

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const resvStatus: Record<string, string> = {
  pending: '승인 대기', confirmed: '확정', rejected: '거절', cancelled: '취소', completed: '완료'
}
const orderStatus: Record<string, string> = {
  pending: '결제 대기', paid: '결제완료', preparing: '배송준비', shipping: '배송중', completed: '배송완료', cancelled: '취소'
}
const fmtDate = (s: string) => new Date(s).toLocaleDateString('ko-KR')

const load = async () => {
  loading.value = true
  try {
    customers.value = await fetchCustomers(keyword.value)
  } finally {
    loading.value = false
  }
}
onMounted(load)

let timer: ReturnType<typeof setTimeout> | null = null
watch(keyword, () => {
  if (timer) clearTimeout(timer)
  timer = setTimeout(load, 300)
})

const toggle = async (id: string) => {
  if (expandedId.value === id) {
    expandedId.value = null
    return
  }
  expandedId.value = id
  if (!details[id]) {
    detailLoading.value = id
    try {
      details[id] = await fetchCustomerDetail(id)
    } finally {
      detailLoading.value = null
    }
  }
}

const orderSummary = (o: any) => {
  const items = o.order_items ?? []
  if (!items.length) return '-'
  const first = items[0].products?.name ?? '상품'
  return items.length > 1 ? `${first} 외 ${items.length - 1}건` : first
}

const vaccStatusOf = (pet: any, no: number): VaccineStatus | undefined => pet.vaccinations?.[String(no)]

// 관리자 확인/취소 — details 캐시를 갱신
const changeVaccine = async (customerId: string, petId: string, no: number, status: 'member' | 'admin' | 'none') => {
  await setVaccineStatus(petId, no, status)
  const d = details[customerId]
  const pet = d?.pets.find((p: any) => p.id === petId)
  if (pet) {
    pet.vaccinations = { ...(pet.vaccinations ?? {}) }
    if (status === 'none') delete pet.vaccinations[String(no)]
    else pet.vaccinations[String(no)] = status
  }
}
</script>

<template>
  <div class="flex flex-col gap-stack-lg">
    <div>
      <h1 class="font-headline-lg-mobile md:font-headline-lg text-headline-lg-mobile md:text-headline-lg text-on-surface">
        회원 관리
      </h1>
      <p class="mt-1 font-body-md text-body-md text-on-surface-variant">
        회원을 클릭하면 반려동물 · 예약 · 주문 내역이 펼쳐집니다.
      </p>
    </div>

    <input
      v-model="keyword"
      type="search"
      class="w-full max-w-sm rounded-lg border border-outline-variant bg-surface px-4 py-2.5 font-body-md text-on-surface focus:border-secondary focus:outline-none focus:ring-2 focus:ring-secondary/20"
      placeholder="이름 / 이메일 / 연락처 검색"
    />

    <p v-if="loading" class="py-10 text-center font-body-md text-sm text-on-surface-variant">불러오는 중...</p>
    <p v-else-if="customers.length === 0" class="py-10 text-center font-body-md text-sm text-on-surface-variant">
      회원이 없습니다.
    </p>

    <div v-else class="flex flex-col gap-2">
      <div v-for="c in customers" :key="c.id" class="overflow-hidden rounded-xl border border-outline-variant/50 bg-surface-container-lowest">
        <!-- row -->
        <button
          type="button"
          class="flex w-full items-center gap-4 px-5 py-4 text-left transition-colors hover:bg-surface-container-low"
          @click="toggle(c.id)"
        >
          <span class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary-fixed font-headline-md text-primary">
            {{ (c.name || c.email)[0] }}
          </span>
          <div class="min-w-0 flex-grow">
            <p class="truncate font-label-md text-label-md text-on-surface">{{ c.name || '이름 미등록' }}</p>
            <p class="truncate font-body-md text-sm text-on-surface-variant">{{ c.email }} · {{ c.phone || '연락처 없음' }}</p>
          </div>
          <span class="shrink-0 font-label-sm text-label-sm text-on-surface-variant">{{ fmtDate(c.created_at) }}</span>
          <span class="material-symbols-outlined shrink-0 text-on-surface-variant transition-transform" :class="expandedId === c.id ? 'rotate-180' : ''">
            expand_more
          </span>
        </button>

        <!-- expanded -->
        <div v-if="expandedId === c.id" class="border-t border-outline-variant/40 bg-surface-container-low/40 px-5 py-5">
          <p v-if="detailLoading === c.id" class="py-4 text-center font-body-md text-sm text-on-surface-variant">불러오는 중...</p>

          <div v-else-if="details[c.id]" class="flex flex-col gap-6">
            <!-- 반려동물 + 접종 현황 -->
            <section>
              <h3 class="mb-3 font-label-md text-label-md text-primary">반려동물 ({{ details[c.id].pets.length }})</h3>
              <p v-if="details[c.id].pets.length === 0" class="font-body-md text-sm text-on-surface-variant">등록된 반려동물이 없습니다.</p>
              <div v-else class="flex flex-col gap-3">
                <div
                  v-for="pet in details[c.id].pets"
                  :key="pet.id"
                  class="rounded-xl border border-outline-variant/50 bg-surface-container-lowest p-4"
                >
                  <div class="mb-3 flex flex-wrap items-baseline gap-x-3 gap-y-1">
                    <span class="font-label-md text-label-md text-on-surface">{{ pet.name }}</span>
                    <span class="font-body-md text-sm text-on-surface-variant">
                      {{ pet.breed || '견종 미입력' }}<span v-if="pet.age"> · {{ pet.age }}살</span><span v-if="pet.weight"> · {{ pet.weight }}kg</span>
                    </span>
                    <span
                      v-if="pet.rules_agreed_at"
                      class="rounded-full bg-green-50 px-2 py-0.5 font-label-sm text-[11px] font-semibold text-green-700"
                    >
                      규정 동의
                    </span>
                  </div>

                  <p class="mb-2 font-label-sm text-label-sm text-on-surface-variant">예방접종 현황</p>
                  <div class="flex flex-col gap-1.5">
                    <div
                      v-for="no in VACCINE_NOS"
                      :key="no"
                      class="flex items-center gap-3 rounded-lg border border-outline-variant/40 px-3 py-2"
                    >
                      <span class="w-20 shrink-0 font-body-md text-sm text-on-surface">예방접종 {{ no }}차</span>
                      <span
                        class="rounded-full px-2.5 py-0.5 font-label-sm text-[11px] font-semibold"
                        :class="vaccStatusOf(pet, no) === 'admin'
                          ? 'bg-green-100 text-green-700'
                          : vaccStatusOf(pet, no) === 'member'
                            ? 'bg-amber-100 text-amber-700'
                            : 'bg-surface-container-high text-on-surface-variant'"
                      >
                        {{ vaccStatusOf(pet, no) === 'admin' ? `관리자확인 ${no}` : vaccStatusOf(pet, no) === 'member' ? `회원확인 ${no}` : '미접종' }}
                      </span>
                      <span class="flex-grow" />
                      <button
                        v-if="vaccStatusOf(pet, no) !== 'admin'"
                        type="button"
                        class="rounded-lg bg-primary px-3 py-1 font-label-sm text-label-sm text-on-primary transition-colors hover:bg-primary-container"
                        @click="changeVaccine(c.id, pet.id, no, 'admin')"
                      >
                        관리자 확인
                      </button>
                      <button
                        v-else
                        type="button"
                        class="rounded-lg border border-outline-variant px-3 py-1 font-label-sm text-label-sm text-on-surface-variant transition-colors hover:bg-surface-container-high"
                        @click="changeVaccine(c.id, pet.id, no, pet.vaccinations && pet.vaccinations[String(no)] === 'admin' ? 'member' : 'none')"
                      >
                        확인 취소
                      </button>
                    </div>
                  </div>

                  <p v-if="pet.notes" class="mt-3 font-body-md text-sm text-on-surface-variant">특이사항: {{ pet.notes }}</p>
                </div>
              </div>
            </section>

            <!-- 예약 내역 -->
            <section>
              <h3 class="mb-3 font-label-md text-label-md text-primary">예약 내역 ({{ details[c.id].reservations.length }})</h3>
              <p v-if="details[c.id].reservations.length === 0" class="font-body-md text-sm text-on-surface-variant">예약 내역이 없습니다.</p>
              <table v-else class="w-full text-left font-body-md text-sm">
                <tbody>
                  <tr v-for="r in details[c.id].reservations" :key="r.id" class="border-b border-outline-variant/30 last:border-0">
                    <td class="py-2 pr-4 text-on-surface">{{ typeLabel[r.type] }} · {{ r.pets?.name }}</td>
                    <td class="py-2 pr-4 text-on-surface-variant">{{ r.start_date }}<span v-if="r.end_date !== r.start_date"> ~ {{ r.end_date }}</span></td>
                    <td class="py-2 text-on-surface-variant">{{ resvStatus[r.status] ?? r.status }}</td>
                  </tr>
                </tbody>
              </table>
            </section>

            <!-- 주문 내역 -->
            <section>
              <h3 class="mb-3 font-label-md text-label-md text-primary">주문 내역 ({{ details[c.id].orders.length }})</h3>
              <p v-if="details[c.id].orders.length === 0" class="font-body-md text-sm text-on-surface-variant">주문 내역이 없습니다.</p>
              <table v-else class="w-full text-left font-body-md text-sm">
                <tbody>
                  <tr v-for="o in details[c.id].orders" :key="o.id" class="border-b border-outline-variant/30 last:border-0">
                    <td class="py-2 pr-4 text-on-surface">{{ orderSummary(o) }}</td>
                    <td class="py-2 pr-4 text-on-surface-variant">{{ fmtDate(o.created_at) }}</td>
                    <td class="py-2 pr-4 text-on-surface-variant">{{ o.total_amount.toLocaleString() }}원</td>
                    <td class="py-2">
                      <NuxtLink :to="`/admin/orders/${o.id}`" class="text-primary hover:underline">
                        {{ orderStatus[o.status] ?? o.status }}
                      </NuxtLink>
                    </td>
                  </tr>
                </tbody>
              </table>
            </section>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
