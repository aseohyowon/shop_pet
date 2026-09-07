<script setup lang="ts">
import { BUSINESS_INFO, mapEmbedSrc, kakaoMapLink, naverMapLink } from '~/utils/businessInfo'

withDefaults(defineProps<{ rounded?: boolean; height?: string }>(), {
  rounded: true,
  height: 'h-full min-h-[260px]'
})
</script>

<template>
  <div class="flex flex-col">
    <div class="relative w-full flex-1 overflow-hidden bg-gray-100" :class="[rounded ? 'rounded-xl' : '', height]">
      <iframe
        :src="mapEmbedSrc()"
        class="absolute inset-0 h-full w-full border-0"
        loading="lazy"
        referrerpolicy="no-referrer-when-downgrade"
        :title="`${BUSINESS_INFO.name} 위치`"
      />
    </div>
    <div class="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500">
      <span class="text-gray-600">{{ BUSINESS_INFO.address }}</span>
      <a :href="kakaoMapLink()" target="_blank" rel="noopener" class="font-medium text-brand-600 hover:underline">
        카카오맵
      </a>
      <a :href="naverMapLink()" target="_blank" rel="noopener" class="font-medium text-brand-600 hover:underline">
        네이버지도
      </a>
    </div>
  </div>
</template>
