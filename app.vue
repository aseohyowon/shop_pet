<script setup lang="ts">
const { load } = useSiteTheme()
// SSR에서 1회만 테마 설정을 읽어온다. (결과 state는 payload로 클라이언트에 전달)
await callOnce('site-theme', load)
</script>

<template>
  <NuxtLayout>
    <NuxtPage />
  </NuxtLayout>
  <CommonIntroScreen />
</template>
