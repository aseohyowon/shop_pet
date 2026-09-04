<script setup lang="ts">
const route = useRoute()
const { contactEnabled } = useSiteTheme()

const tabs = computed(() => [
  { label: '통합 조회', to: '/mypage' },
  { label: '예약 내역', to: '/mypage/reservations' },
  { label: '주문 내역', to: '/mypage/orders' },
  ...(contactEnabled.value ? [{ label: '문의 내역', to: '/mypage/inquiries' }] : [])
])
</script>

<template>
  <nav class="mb-8 flex gap-2 border-b border-gray-200">
    <NuxtLink
      v-for="tab in tabs"
      :key="tab.to"
      :to="tab.to"
      class="border-b-2 px-4 py-3 text-sm font-medium"
      :class="route.path === tab.to ? 'border-brand-500 text-brand-600' : 'border-transparent text-gray-500 hover:text-gray-700'"
    >
      {{ tab.label }}
    </NuxtLink>
  </nav>
</template>
