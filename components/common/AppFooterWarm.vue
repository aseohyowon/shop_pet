<script setup lang="ts">
const year = new Date().getFullYear()
</script>

<template>
  <footer class="mt-stack-lg w-full bg-surface-container-high font-body-md text-body-md text-on-surface-variant">
    <div class="container-warm grid grid-cols-1 gap-gutter py-stack-lg md:grid-cols-4">
      <div class="flex flex-col gap-4">
        <span class="flex items-center gap-2 font-headline-md text-headline-md text-primary">
          <img src="/images/logo-icon.png" alt="댕이를 부탁해" class="h-8 w-8 object-contain" />
          댕이를 부탁해
        </span>
        <p class="text-sm">반려동물과 보호자 모두가 안심할 수 있는 프리미엄 펫 케어 서비스.</p>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="mb-2 font-label-md text-primary">바로가기</h4>
        <NuxtLink to="/reservation" class="transition-colors hover:text-secondary">예약하기</NuxtLink>
        <NuxtLink to="/shop" class="transition-colors hover:text-secondary">쇼핑몰</NuxtLink>
        <NuxtLink to="/terms" class="transition-colors hover:text-secondary">이용약관</NuxtLink>
        <NuxtLink to="/privacy" class="transition-colors hover:text-secondary">개인정보처리방침</NuxtLink>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="mb-2 font-label-md text-primary">오시는 길</h4>
        <p class="text-sm">서울특별시 ○○구 ○○로 123</p>
        <p class="text-sm">매일 09:00 - 19:00 (연중무휴)</p>
      </div>

      <div class="flex flex-col gap-2">
        <h4 class="mb-2 font-label-md text-primary">고객센터</h4>
        <p class="text-sm">대표전화 02-000-0000</p>
        <p class="text-sm">hello@daengyi.example</p>
        <NuxtLink to="/contact" class="text-sm font-medium text-primary transition-colors hover:text-secondary">1:1 문의하기</NuxtLink>
      </div>
    </div>
    <div class="border-t border-surface-dim py-4 text-center">
      <p class="text-sm">© {{ year }} 댕이를 부탁해. All rights reserved.</p>
    </div>
  </footer>
</template>
