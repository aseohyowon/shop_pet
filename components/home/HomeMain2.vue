<script setup lang="ts">
import { BUSINESS_INFO } from '~/utils/businessInfo'

const serviceCards = [
  {
    icon: 'bed',
    title: '프리미엄 호텔',
    desc: '스트레스 없는 아늑한 개인 공간. 24시간 실시간 모니터링으로 안심하고 맡기세요.',
    cta: '자세히 보기',
    to: '/reservation',
    iconWrap: 'bg-surface-container text-primary'
  },
  {
    icon: 'playing_cards',
    title: '맞춤형 데이케어',
    desc: '전문 훈련사와 함께하는 사회성 훈련 및 신나는 놀이 프로그램. 에너지를 듬뿍 발산해요.',
    cta: '프로그램 보기',
    to: '/reservation',
    iconWrap: 'bg-primary-fixed text-primary-container'
  },
  {
    icon: 'storefront',
    title: '유기농 샵',
    desc: '수제 간식부터 프리미엄 사료, 안전한 장난감까지. 엄선된 제품만 판매합니다.',
    cta: '쇼핑하기',
    to: '/shop',
    iconWrap: 'bg-secondary-container/30 text-secondary'
  }
]
</script>

<template>
  <div>
    <!-- Hero -->
    <section class="relative w-full overflow-hidden bg-surface-container py-16 md:py-24">
      <div class="relative z-10 mx-auto grid max-w-container-max grid-cols-1 items-center gap-12 px-margin-mobile md:grid-cols-2 md:px-margin-desktop">
        <div class="flex max-w-xl flex-col gap-6">
          <h1 class="font-headline-xl text-headline-lg-mobile text-primary md:text-headline-xl">
            사랑하는 우리 아이,<br class="hidden md:block" />
            믿고 맡길 수 있는<br class="hidden md:block" />
            <span class="text-secondary">댕이를 부탁해</span>
          </h1>
          <p class="font-body-lg text-body-lg text-on-surface-variant">
            따뜻하고 안전한 프리미엄 펫케어 서비스. 우리 아이에게 행복한 하루를 선물하세요.
            전문 펫시터와 최상의 환경이 기다립니다.
          </p>
          <div class="mt-4 flex flex-wrap gap-4">
            <NuxtLink to="/reservation" class="btn-warm">
              <span class="material-symbols-outlined">calendar_month</span>
              예약하기
            </NuxtLink>
            <NuxtLink to="/shop" class="btn-warm-soft">
              <span class="material-symbols-outlined">storefront</span>
              쇼핑몰 둘러보기
            </NuxtLink>
          </div>
        </div>

        <div class="relative h-[400px] w-full overflow-hidden rounded-2xl border-4 border-surface-container-lowest shadow-lg md:h-[500px]">
          <div
            class="h-full w-full bg-cover bg-center"
            style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAxROTU8bev9sTlUtDsvD5mbZp8G5Aw9U8Did8tZUGTfQnE83V1gPtKSMCnH2c8hQULsSHS2oIrckueLr26ziR1PnUaH7PExQ6Ed7MIqd6IbQSWlSFGQ8UVlMV_3Fp5WQm8QkzizuZqfhpGHKLtwMxterfmQ0aGX8TRs_aSIVpVSPv76qNSlj2NEPyjNc6nFNmFkgOkSH9VSGSLM69JrIYFNdBDT8lSxfteLBrmoofxcf9xQW-IW7ja-Q')"
          ></div>
          <div class="absolute bottom-6 left-6 flex items-center gap-4 rounded-xl bg-surface-container-lowest p-4 shadow-md">
            <div class="h-12 w-12 overflow-hidden rounded-full border-2 border-primary">
              <img
                class="h-full w-full object-cover"
                alt="이달의 우수회원 코코"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuDNp_XBWiOU6ImWhK4bYc59zaZAtTFo2ljArN9bHfFomZ0gmaPUtmj6_1ky1u0bCWfAvdHWvKyFTLwN7umuQ-84Sqkum-50O60rB6UfVdVzF4M7Z5LMCcehxqt99n2cUiPd_lr5zflivcGkTBurEEKHdwveszRiCrLKlPwDYei2T7vd_1wadC4kpLzvDoPA1dE6v4s_p8F4vDQQa31Du-okxpR_yW53cSpuFTlLBuuMTaTf4x4p7f0EmA"
              />
            </div>
            <div>
              <p class="font-label-md text-label-md text-primary">이달의 우수회원 '코코'</p>
              <p class="flex items-center gap-1 font-label-sm text-label-sm text-on-surface-variant">
                <span class="material-symbols-outlined icon-filled text-sm text-secondary">favorite</span>
                30회 이용
              </p>
            </div>
          </div>
        </div>
      </div>
      <div class="absolute right-0 top-0 -mr-32 -mt-32 h-96 w-96 rounded-full bg-primary-fixed opacity-50 mix-blend-multiply blur-3xl"></div>
      <div class="absolute bottom-0 left-0 -mb-32 -ml-32 h-96 w-96 rounded-full bg-secondary-container opacity-30 mix-blend-multiply blur-3xl"></div>
    </section>

    <!-- Service Overview -->
    <section class="mx-auto max-w-container-max px-margin-mobile py-16 md:px-margin-desktop md:py-24">
      <div class="mb-12 text-center">
        <h2 class="mb-4 font-headline-md text-headline-lg-mobile text-primary md:text-headline-md">우리가 제공하는 특별한 서비스</h2>
        <p class="mx-auto max-w-2xl font-body-md text-on-surface-variant">아이들의 성향과 필요에 맞춘 세심한 케어를 약속합니다.</p>
      </div>
      <div class="grid grid-cols-1 gap-gutter md:grid-cols-3">
        <div
          v-for="s in serviceCards"
          :key="s.title"
          class="flex flex-col items-start gap-4 rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-6 shadow-sm transition-all hover:-translate-y-1 hover:shadow-lg"
        >
          <div class="flex h-14 w-14 items-center justify-center rounded-xl" :class="s.iconWrap">
            <span class="material-symbols-outlined icon-filled text-3xl">{{ s.icon }}</span>
          </div>
          <h3 class="font-headline-md text-xl text-primary">{{ s.title }}</h3>
          <p class="flex-grow font-body-md text-on-surface-variant">{{ s.desc }}</p>
          <NuxtLink :to="s.to" class="mt-2 flex items-center gap-1 font-label-md text-secondary hover:underline">
            {{ s.cta }} <span class="material-symbols-outlined text-sm">arrow_forward</span>
          </NuxtLink>
        </div>
      </div>
    </section>

    <!-- 오시는 길 -->
    <section class="mx-auto max-w-container-max px-margin-mobile pb-16 md:px-margin-desktop md:pb-24">
      <div class="grid grid-cols-1 gap-gutter overflow-hidden rounded-2xl border border-surface-container-highest bg-surface-container-lowest p-6 shadow-sm md:grid-cols-2 md:p-8">
        <div class="flex flex-col justify-center">
          <h2 class="mb-4 font-headline-md text-headline-lg-mobile text-primary md:text-headline-md">오시는 길</h2>
          <p class="mb-1 font-body-md text-on-surface">{{ BUSINESS_INFO.name }}</p>
          <p class="mb-1 font-body-md text-on-surface-variant">{{ BUSINESS_INFO.address }}</p>
          <p class="font-body-md text-on-surface-variant">운영 시간 {{ BUSINESS_INFO.hours }}</p>
          <p v-if="BUSINESS_INFO.phone" class="font-body-md text-on-surface-variant">대표전화 {{ BUSINESS_INFO.phone }}</p>
          <NuxtLink to="/reservation" class="btn-warm mt-6 self-start">지금 예약하기</NuxtLink>
        </div>
        <CommonLocationMap height="h-64 md:h-72" />
      </div>
    </section>
  </div>
</template>
