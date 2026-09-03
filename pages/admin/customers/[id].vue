<script setup lang="ts">
definePageMeta({ layout: 'admin', middleware: 'admin' })

const route = useRoute()
const { fetchCustomerDetail } = useCustomers()

const data = ref<Awaited<ReturnType<typeof fetchCustomerDetail>> | null>(null)
const loading = ref(true)

const typeLabel: Record<string, string> = { hotel: '호텔 숙박', daycare: '데이케어' }
const resvStatus: Record<string, string> = {
  pending: '승인 대기', confirmed: '확정', rejected: '거절', cancelled: '취소', completed: '완료'
}
const orderStatus: Record<string, string> = {
  pending: '결제 대기', paid: '결제완료', preparing: '배송준비', shipping: '배송중', completed: '배송완료', cancelled: '취소'
}
const fmtDate = (s: string) => new Date(s).toLocaleDateString('ko-KR')

onMounted(async () => {
  try {
    data.value = await fetchCustomerDetail(route.params.id as string)
  } finally {
    loading.value = false
  }
})

const orderSummary = (o: any) => {
  const items = o.order_items ?? []
  if (!items.length) return '-'
  const first = items[0].products?.name ?? '상품'
  return items.length > 1 ? `${first} 외 ${items.length - 1}건` : first
}
</script>

<template>
  <div class="max-w-4xl">
    <NuxtLink to="/admin/customers" class="mb-4 inline-block text-sm text-gray-500 hover:text-gray-700">← 회원 목록으로</NuxtLink>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="!data?.profile" class="py-8 text-center text-sm text-gray-400">회원을 찾을 수 없습니다.</p>

    <div v-else class="space-y-6">
      <div class="card">
        <h1 class="mb-4 text-xl font-bold text-gray-900">{{ data.profile.name || '이름 미등록' }}</h1>
        <dl class="grid grid-cols-2 gap-x-6 gap-y-2 text-sm sm:grid-cols-3">
          <div><dt class="text-gray-400">이메일</dt><dd class="text-gray-800">{{ data.profile.email }}</dd></div>
          <div><dt class="text-gray-400">연락처</dt><dd class="text-gray-800">{{ data.profile.phone || '-' }}</dd></div>
          <div><dt class="text-gray-400">가입일</dt><dd class="text-gray-800">{{ fmtDate(data.profile.created_at) }}</dd></div>
        </dl>
      </div>

      <div class="card">
        <p class="mb-3 font-semibold text-gray-900">반려동물 ({{ data.pets.length }})</p>
        <p v-if="data.pets.length === 0" class="text-sm text-gray-400">등록된 반려동물이 없습니다.</p>
        <ul v-else class="space-y-1 text-sm text-gray-700">
          <li v-for="pet in data.pets" :key="pet.id">
            {{ pet.name }} · {{ pet.breed || '견종 미입력' }}<span v-if="pet.age"> · {{ pet.age }}살</span>
          </li>
        </ul>
      </div>

      <div class="card">
        <p class="mb-3 font-semibold text-gray-900">예약 내역 ({{ data.reservations.length }})</p>
        <p v-if="data.reservations.length === 0" class="text-sm text-gray-400">예약 내역이 없습니다.</p>
        <table v-else class="w-full text-left text-sm">
          <tbody>
            <tr v-for="r in data.reservations" :key="r.id" class="border-b border-gray-100 last:border-0">
              <td class="py-2 pr-4 text-gray-800">{{ typeLabel[r.type] }} · {{ r.pets?.name }}</td>
              <td class="py-2 pr-4 text-gray-500">{{ r.start_date }} ~ {{ r.end_date }}</td>
              <td class="py-2 text-gray-600">{{ resvStatus[r.status] ?? r.status }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="card">
        <p class="mb-3 font-semibold text-gray-900">주문 내역 ({{ data.orders.length }})</p>
        <p v-if="data.orders.length === 0" class="text-sm text-gray-400">주문 내역이 없습니다.</p>
        <table v-else class="w-full text-left text-sm">
          <tbody>
            <tr v-for="o in data.orders" :key="o.id" class="border-b border-gray-100 last:border-0">
              <td class="py-2 pr-4 text-gray-800">{{ orderSummary(o) }}</td>
              <td class="py-2 pr-4 text-gray-500">{{ fmtDate(o.created_at) }}</td>
              <td class="py-2 pr-4 text-gray-600">{{ o.total_amount.toLocaleString() }}원</td>
              <td class="py-2">
                <NuxtLink :to="`/admin/orders/${o.id}`" class="text-brand-600 hover:underline">
                  {{ orderStatus[o.status] ?? o.status }}
                </NuxtLink>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
