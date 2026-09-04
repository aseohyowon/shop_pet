<script setup lang="ts">
import type { OrderStatus } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const { fetchAllOrdersForAdmin, updateOrderStatus } = useOrders()

const statusOptions: { value: OrderStatus; label: string }[] = [
  { value: 'pending', label: '결제 대기' },
  { value: 'paid', label: '결제완료' },
  { value: 'preparing', label: '배송준비' },
  { value: 'shipping', label: '배송중' },
  { value: 'completed', label: '배송완료' },
  { value: 'cancelled', label: '취소' }
]

const orders = ref<any[]>([])
const loading = ref(true)

const itemsSummary = (order: any) => {
  const items = order.order_items ?? []
  if (items.length === 0) return '-'
  const first = items[0].products?.name ?? '상품'
  return items.length > 1 ? `${first} 외 ${items.length - 1}건` : first
}

const load = async () => {
  loading.value = true
  try {
    orders.value = await fetchAllOrdersForAdmin()
  } finally {
    loading.value = false
  }
}

onMounted(load)

const handleStatusChange = async (id: string, status: OrderStatus) => {
  await updateOrderStatus(id, status)
}
</script>

<template>
  <div>
    <h1 class="mb-6 text-2xl font-bold text-gray-900">주문 관리</h1>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="orders.length === 0" class="py-8 text-center text-sm text-gray-400">주문이 없습니다.</p>

    <div v-else class="card overflow-x-auto">
      <table class="w-full min-w-[680px] text-left text-sm">
        <thead>
          <tr class="border-b border-gray-200 text-gray-500">
            <th class="py-3 pr-4 font-medium">주문자</th>
            <th class="py-3 pr-4 font-medium">주문 내역</th>
            <th class="py-3 pr-4 font-medium">금액</th>
            <th class="py-3 pr-4 font-medium">배송</th>
            <th class="py-3 pr-4 font-medium">상태</th>
            <th class="py-3 font-medium"></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="o in orders" :key="o.id" class="border-b border-gray-100 last:border-0">
            <td class="py-3 pr-4 font-medium text-gray-800">{{ o.profiles?.name }}</td>
            <td class="py-3 pr-4 text-gray-600">
              {{ itemsSummary(o) }}
              <span
                v-if="o.stock_issue"
                class="ml-1 rounded bg-red-50 px-1.5 py-0.5 text-[11px] font-semibold text-red-600"
                :title="o.stock_issue"
              >재고 부족</span>
            </td>
            <td class="py-3 pr-4 text-gray-600">{{ o.total_amount.toLocaleString() }}원</td>
            <td class="py-3 pr-4 text-xs">
              <span v-if="o.tracking_number" class="text-green-600">송장 등록</span>
              <span v-else-if="o.shipping_address" class="text-amber-600">배송지 O</span>
              <span v-else class="text-gray-300">-</span>
            </td>
            <td class="py-3">
              <select
                class="input-field !py-1.5 text-xs"
                :value="o.status"
                @change="handleStatusChange(o.id, ($event.target as HTMLSelectElement).value as OrderStatus)"
              >
                <option v-for="s in statusOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
              </select>
            </td>
            <td class="py-3">
              <NuxtLink :to="`/admin/orders/${o.id}`" class="text-brand-600 hover:underline">상세</NuxtLink>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
