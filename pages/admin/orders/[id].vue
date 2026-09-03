<script setup lang="ts">
import type { OrderStatus } from '~/types/database.types'

definePageMeta({ layout: 'admin', middleware: 'admin' })

const route = useRoute()
const { fetchOrderByIdForAdmin, updateOrderStatus, updateOrderTracking } = useOrders()

const order = ref<any | null>(null)
const loading = ref(true)
const errorMessage = ref('')

const courier = ref('')
const trackingNo = ref('')
const savingTracking = ref(false)

const statusOptions: { value: OrderStatus; label: string }[] = [
  { value: 'pending', label: '결제 대기' },
  { value: 'paid', label: '결제완료' },
  { value: 'preparing', label: '배송준비' },
  { value: 'shipping', label: '배송중' },
  { value: 'completed', label: '배송완료' },
  { value: 'cancelled', label: '취소' }
]

const fmt = (s: string) => new Date(s).toLocaleString('ko-KR')

const load = async () => {
  loading.value = true
  try {
    order.value = await fetchOrderByIdForAdmin(route.params.id as string)
    courier.value = order.value.tracking_courier ?? ''
    trackingNo.value = order.value.tracking_number ?? ''
  } catch (e: any) {
    errorMessage.value = e?.message ?? '주문을 불러오지 못했습니다.'
  } finally {
    loading.value = false
  }
}
onMounted(load)

const changeStatus = async (status: OrderStatus) => {
  await updateOrderStatus(order.value.id, status)
  order.value.status = status
}

const saveTracking = async () => {
  savingTracking.value = true
  errorMessage.value = ''
  try {
    await updateOrderTracking(order.value.id, {
      courier: courier.value,
      number: trackingNo.value,
      markShipping: order.value.status === 'paid' || order.value.status === 'preparing'
    })
    await load()
  } catch (e: any) {
    errorMessage.value = e?.message ?? '송장 저장에 실패했습니다.'
  } finally {
    savingTracking.value = false
  }
}
</script>

<template>
  <div class="max-w-3xl">
    <NuxtLink to="/admin/orders" class="mb-4 inline-block text-sm text-gray-500 hover:text-gray-700">← 주문 목록으로</NuxtLink>

    <p v-if="loading" class="py-8 text-center text-sm text-gray-400">불러오는 중...</p>
    <p v-else-if="!order" class="py-8 text-center text-sm text-gray-400">주문을 찾을 수 없습니다.</p>

    <div v-else class="space-y-6">
      <div class="card">
        <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
          <div>
            <h1 class="text-lg font-bold text-gray-900">주문 #{{ order.id.slice(0, 8) }}</h1>
            <p class="text-xs text-gray-400">{{ fmt(order.created_at) }}</p>
          </div>
          <select
            class="input-field !w-36 !py-1.5 text-sm"
            :value="order.status"
            @change="changeStatus(($event.target as HTMLSelectElement).value as OrderStatus)"
          >
            <option v-for="s in statusOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
          </select>
        </div>

        <dl class="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
          <div><dt class="text-gray-400">주문자</dt><dd class="text-gray-800">{{ order.profiles?.name || '-' }}</dd></div>
          <div><dt class="text-gray-400">가입 연락처</dt><dd class="text-gray-800">{{ order.profiles?.phone || '-' }}</dd></div>
          <div class="col-span-2"><dt class="text-gray-400">이메일</dt><dd class="text-gray-800">{{ order.profiles?.email || '-' }}</dd></div>
        </dl>
      </div>

      <div class="card">
        <p class="mb-3 font-semibold text-gray-900">배송지</p>
        <dl v-if="order.shipping_address" class="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
          <div><dt class="text-gray-400">수령인</dt><dd class="text-gray-800">{{ order.recipient_name || '-' }}</dd></div>
          <div><dt class="text-gray-400">연락처</dt><dd class="text-gray-800">{{ order.recipient_phone || '-' }}</dd></div>
          <div class="col-span-2"><dt class="text-gray-400">주소</dt><dd class="text-gray-800">{{ order.shipping_address }}</dd></div>
          <div v-if="order.shipping_memo" class="col-span-2"><dt class="text-gray-400">배송 메모</dt><dd class="text-gray-800">{{ order.shipping_memo }}</dd></div>
        </dl>
        <p v-else class="text-sm text-gray-400">배송지 정보가 없습니다.</p>
      </div>

      <div class="card">
        <p class="mb-3 font-semibold text-gray-900">주문 상품</p>
        <table class="w-full text-left text-sm">
          <tbody>
            <tr v-for="it in order.order_items" :key="it.id" class="border-b border-gray-100 last:border-0">
              <td class="py-2 pr-4 text-gray-800">{{ it.products?.name ?? '상품' }}</td>
              <td class="py-2 pr-4 text-gray-500">× {{ it.quantity }}</td>
              <td class="py-2 text-right text-gray-600">{{ (it.price_at_order * it.quantity).toLocaleString() }}원</td>
            </tr>
          </tbody>
          <tfoot>
            <tr class="font-bold text-gray-900">
              <td class="py-3" colspan="2">합계</td>
              <td class="py-3 text-right">{{ order.total_amount.toLocaleString() }}원</td>
            </tr>
          </tfoot>
        </table>
      </div>

      <div class="card">
        <p class="mb-3 font-semibold text-gray-900">송장 등록</p>
        <div class="flex flex-wrap items-end gap-3">
          <div class="w-44">
            <label class="label-field" for="courier">택배사</label>
            <select id="courier" v-model="courier" class="input-field">
              <option value="">선택</option>
              <option v-for="c in COURIERS" :key="c.code" :value="c.code">{{ c.label }}</option>
            </select>
          </div>
          <div class="flex-1">
            <label class="label-field" for="tracking">운송장 번호</label>
            <input id="tracking" v-model="trackingNo" type="text" class="input-field" placeholder="123456789012" />
          </div>
          <button type="button" class="btn-primary !py-2.5" :disabled="savingTracking" @click="saveTracking">
            {{ savingTracking ? '저장 중...' : '저장' }}
          </button>
        </div>
        <p class="mt-2 text-xs text-gray-400">저장 시 결제완료/배송준비 상태면 자동으로 '배송중'으로 변경됩니다. 고객은 마이페이지에서 배송조회 링크로 추적할 수 있습니다.</p>
        <a
          v-if="order.tracking_number"
          :href="trackingUrl(order.tracking_courier, order.tracking_number)"
          target="_blank"
          rel="noopener"
          class="mt-2 inline-block text-sm text-brand-600 hover:underline"
        >
          현재 송장 배송조회 열기 →
        </a>
        <p v-if="errorMessage" class="mt-2 text-sm text-red-500">{{ errorMessage }}</p>
      </div>
    </div>
  </div>
</template>
