<script setup lang="ts">
const { isWarm } = useSiteTheme()
</script>

<template>
  <div
    class="flex min-h-screen flex-col"
    :class="isWarm ? 'bg-background font-body-md text-on-background' : ''"
  >
    <CommonAppHeaderWarm v-if="isWarm" />
    <CommonAppHeader v-else />

    <main class="flex-1">
      <slot />
    </main>

    <CommonAppFooterWarm v-if="isWarm" />
    <CommonAppFooter v-else />
  </div>
</template>
