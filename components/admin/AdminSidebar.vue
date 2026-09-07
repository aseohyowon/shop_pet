<script setup lang="ts">
const navLinks = [
  { label: '대시보드', to: '/admin', icon: 'dashboard' },
  { label: '예약 관리', to: '/admin/reservations', icon: 'calendar_month' },
  { label: '가격 관리', to: '/admin/pricing', icon: 'payments' },
  { label: '상품 관리', to: '/admin/products', icon: 'inventory_2' },
  { label: '카테고리 관리', to: '/admin/categories', icon: 'sell' },
  { label: '주문 관리', to: '/admin/orders', icon: 'local_shipping' },
  { label: '회원 관리', to: '/admin/customers', icon: 'group' },
  { label: '1:1 문의', to: '/admin/inquiries', icon: 'chat_bubble' },
  { label: '사이트 설정', to: '/admin/settings', icon: 'palette' }
]
</script>

<template>
  <aside class="hidden w-64 shrink-0 border-r border-outline-variant/40 bg-surface md:block">
    <div
      class="flex h-16 items-center gap-2 border-b border-outline-variant/40 px-6 font-headline-md text-lg font-bold text-primary"
    >
      <span class="material-symbols-outlined icon-filled text-secondary">pets</span>
      <span>댕이를 부탁해 <span class="font-label-sm text-label-sm text-on-surface-variant">Admin</span></span>
    </div>
    <nav class="flex flex-col gap-1 p-3">
      <NuxtLink
        v-for="link in navLinks"
        :key="link.to"
        :to="link.to"
        class="flex items-center gap-3 rounded-lg px-3 py-2.5 font-body-md text-sm font-medium text-on-surface-variant transition-colors hover:bg-surface-container hover:text-primary"
        active-class="!bg-surface-container-high !font-bold !text-primary"
      >
        <span class="material-symbols-outlined text-[20px]" aria-hidden="true">{{ link.icon }}</span>
        {{ link.label }}
      </NuxtLink>
    </nav>
  </aside>
</template>
