<script setup lang="ts">
import { BUSINESS_INFO } from '~/utils/businessInfo'

const year = new Date().getFullYear()
const { contactEnabled } = useSiteTheme()
</script>

<template>
  <footer class="mt-stack-lg w-full bg-surface-container-high font-body-md text-body-md text-on-surface-variant">
    <div class="container-warm grid grid-cols-1 gap-gutter py-stack-lg md:grid-cols-4">
      <div class="flex flex-col gap-4">
        <span class="flex items-center gap-2 font-headline-md text-headline-md text-primary">
          <img src="/images/logo-icon.png" alt="댕이를 부탁해" class="h-8 w-8 object-contain" />
          {{ BUSINESS_INFO.name }}
        </span>
        <p class="text-sm">반려동물과 보호자 모두가 안심할 수 있는 프리미엄 펫 케어 서비스.</p>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="mb-2 font-label-md text-primary">바로가기</h4>
        <NuxtLink to="/reservation" class="transition-colors hover:text-secondary">예약하기</NuxtLink>
        <NuxtLink to="/pricing" class="transition-colors hover:text-secondary">이용 요금</NuxtLink>
        <NuxtLink to="/shop" class="transition-colors hover:text-secondary">쇼핑몰</NuxtLink>
        <NuxtLink to="/terms" class="transition-colors hover:text-secondary">이용약관</NuxtLink>
        <NuxtLink to="/privacy" class="transition-colors hover:text-secondary">개인정보처리방침</NuxtLink>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="mb-2 font-label-md text-primary">오시는 길</h4>
        <p class="text-sm">{{ BUSINESS_INFO.address }}</p>
        <p class="text-sm">{{ BUSINESS_INFO.hours }}</p>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="mb-2 font-label-md text-primary">고객센터</h4>
        <p v-if="BUSINESS_INFO.phone" class="text-sm">대표전화 {{ BUSINESS_INFO.phone }}</p>
        <p v-if="BUSINESS_INFO.email" class="text-sm">{{ BUSINESS_INFO.email }}</p>
        <NuxtLink v-if="contactEnabled" to="/contact" class="text-sm font-medium text-primary transition-colors hover:text-secondary">1:1 문의하기</NuxtLink>
      </div>
    </div>
    <div class="border-t border-surface-dim py-4 text-center">
      <p class="mb-1 text-sm">
        {{ BUSINESS_INFO.name }} · 대표 {{ BUSINESS_INFO.owner }}
        <template v-if="BUSINESS_INFO.bizRegNo"> · 사업자등록번호 {{ BUSINESS_INFO.bizRegNo }}</template>
        <template v-if="BUSINESS_INFO.onlineSalesNo"> · 통신판매업신고 {{ BUSINESS_INFO.onlineSalesNo }}</template>
      </p>
      <p class="text-sm">© {{ year }} {{ BUSINESS_INFO.name }}. All rights reserved.</p>
    </div>
  </footer>
</template>
