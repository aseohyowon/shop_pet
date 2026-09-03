<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'auth' })

const route = useRoute()

const message = computed(() => (route.query.message as string) || '결제가 취소되었거나 실패했습니다.')
</script>

<template>
  <div class="card text-center">
    <p class="text-2xl">⚠️</p>
    <p class="mt-3 font-semibold text-gray-900">결제에 실패했습니다</p>
    <p class="mt-1 text-sm text-gray-500">{{ message }}</p>
    <div class="mt-6 flex justify-center gap-3">
      <NuxtLink to="/" class="btn-secondary">홈으로</NuxtLink>
      <NuxtLink to="/cart" class="btn-primary">장바구니로</NuxtLink>
    </div>
  </div>
</template>
