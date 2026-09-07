<script setup lang="ts">
definePageMeta({ middleware: 'auth' })

const { fetchMyPasses, fetchPassProducts, fetchMyUsages } = usePasses()

const passes = ref<any[]>([])
const products = ref<any[]>([])
const usages = ref<any[]>([])
const loading = ref(true)
const showBuy = ref(false)

const load = async () => {
  loading.value = true
  try {
    const [p, prod, u] = await Promise.all([fetchMyPasses(), fetchPassProducts(), fetchMyUsages()])
    passes.value = p
    products.value = prod
    usages.value = u
  } finally {
    loading.value = false
  }
}
onMounted(load)

const fmtDate = (s: string) => new Date(s).toLocaleDateString('ko-KR')
const statusLabel: Record<string, string> = { pending: '결제 대기', active: '사용 가능', void: '만료/취소' }
</script>

<template>
  <div class="container-page py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">마이페이지</h1>
    <p class="mb-6 text-gray-500">데이케어 정기권을 확인하고 구매하세요.</p>

    <CommonMypageTabs />

    <div class="mb-4 flex items-center justify-between">
      <p class="font-semibold text-gray-900">보유 정기권</p>
      <button type="button" class="btn-primary !py-2 text-sm" @click="showBuy = !showBuy">+ 정기권 구매</button>
    </div>

    <!-- 구매 목록 -->
    <div v-if="showBuy" class="card mb-6 space-y-2">
      <p class="text-sm text-gray-500">종일 데이케어를 미리 결제하고 예약 시 1회씩 차감합니다.</p>
      <NuxtLink
        v-for="prod in products"
        :key="prod.id"
        :to="`/checkout/pass?item=${prod.id}`"
        class="flex items-center justify-between rounded-lg border border-gray-200 px-4 py-3 transition hover:border-brand-300"
      >
        <span>
          <span class="font-medium text-gray-800">{{ prod.name }}</span>
          <span v-if="prod.note" class="ml-2 text-xs text-gray-400">{{ prod.note }}</span>
        </span>
        <span class="font-bold text-brand-600">{{ prod.price.toLocaleString() }}원</span>
      </NuxtLink>
    </div>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="passes.length === 0" class="py-8 text-center text-sm text-gray-400">보유한 정기권이 없습니다.</p>

    <div v-else class="space-y-3">
      <div v-for="p in passes" :key="p.id" class="card">
        <div class="flex items-start justify-between">
          <div>
            <p class="font-semibold text-gray-900">{{ p.name }}</p>
            <p class="text-xs text-gray-400">
              {{ fmtDate(p.created_at) }} · {{ p.source === 'admin' ? '현장 결제' : '온라인 구매' }}
            </p>
          </div>
          <span
            class="rounded-full px-3 py-1 text-xs font-semibold"
            :class="p.status === 'active' ? 'bg-brand-50 text-brand-600' : 'bg-gray-100 text-gray-500'"
          >
            {{ statusLabel[p.status] ?? p.status }}
          </span>
        </div>
        <div class="mt-3 flex items-baseline gap-2 border-t border-gray-100 pt-3">
          <span class="text-2xl font-bold" :class="p.remaining > 0 ? 'text-brand-600' : 'text-gray-400'">{{ p.remaining }}</span>
          <span class="text-sm text-gray-500">/ {{ p.total_count }}회 남음</span>
        </div>
      </div>
    </div>

    <div v-if="usages.length" class="mt-8">
      <p class="mb-3 font-semibold text-gray-900">사용 내역</p>
      <div class="space-y-2">
        <div
          v-for="u in usages"
          :key="u.id"
          class="card flex items-center justify-between py-3 text-sm"
          :class="u.reverted_at ? 'opacity-50' : ''"
        >
          <span class="text-gray-700">{{ u.daycare_passes?.name }} · 1회 사용</span>
          <span class="text-xs text-gray-400">
            {{ fmtDate(u.used_at) }}<span v-if="u.reverted_at"> · 취소로 복원됨</span>
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
