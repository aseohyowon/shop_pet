<script setup lang="ts">
const { resolvedHome } = useSiteTheme()
</script>

<template>
  <HomeMain1 v-if="resolvedHome === 'main1'" />
  <HomeMain2 v-else-if="resolvedHome === 'main2'" />
  <HomeClassic v-else />
</template>
