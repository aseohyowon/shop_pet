<script setup lang="ts">
import { BUSINESS_INFO } from '~/utils/businessInfo'

const facilities = [
  {
    title: '럭셔리 스위트',
    img: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDCNGDkbZ2ZM3spv8Tc0d3W5YLJAttWJtPkO7wYm8wm90nYHhk_yLHd_KeD77Fo36Zc2dCSJw-P8TcbXmNVnw3_pafCql7dWSkBEwLnQ1DRiL4OK_BS8DFwtRRqsSmnEJQ0Kegc8jevOCpGtDyQMfx9Ih-dGnxBHZV5Fa9hP9PE34AkUk4LVbvsDOhtM4WLgNC2lsHKzd6RuW5a-H0kpUCEl51V0hVEv8kLEWPJEyrtZGnTYlxGuKOB7w'
  },
  {
    title: '야외 놀이터',
    img: 'https://lh3.googleusercontent.com/aida-public/AB6AXuALjYZsNXZzNF3lX9d8CLPCmeruspXgKwrIJw7SHFXZXlfv7M5zrn5Xwp4wE1qE2-atXrP1E3cSZSbzfJa5WifkfGY3MYz7q8sFzBVYSgGameaB54_T0_c_HfdShIxUfGmw7Yn4AorLIExArWGzJ3OMwJdezBEs8_QeLVeFILrCn23tX_NJYmX6Dymv5i1R_vGNRIjtE3B7De0qOeDu0TXX9k_91NzOp5Sm2DzCcdneo7Z3FIVP8YIC2Q'
  }
]
</script>

<template>
  <div>
    <!-- Hero -->
    <section
      class="relative overflow-hidden px-margin-mobile pb-24 pt-stack-lg md:px-margin-desktop"
      style="background-color: #fff8f5; background-image: radial-gradient(#efdfd7 1px, transparent 1px); background-size: 20px 20px;"
    >
      <div class="relative z-10 mx-auto max-w-container-max text-center">
        <div class="mb-6 inline-flex items-center gap-2 rounded-full border border-surface-container-highest bg-white px-4 py-2 shadow-sm">
          <span class="h-2 w-2 animate-pulse rounded-full bg-secondary"></span>
          <span class="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">우리 이야기</span>
        </div>
        <h1 class="mx-auto mb-6 max-w-3xl font-headline-lg-mobile text-headline-lg-mobile leading-tight text-primary md:font-headline-xl md:text-headline-xl">
          우리 아이를 위한<br class="hidden md:block" />
          가장 안전한 두 번째 집
        </h1>
        <p class="mx-auto mb-10 max-w-2xl font-body-lg text-body-lg text-on-surface-variant">
          모든 반려동물이 집처럼 편안한 공간에서 사랑과 안전, 전문적인 케어를 받을 자격이 있다고 믿습니다.
          댕이를 부탁해는 단순한 애견호텔이 아니라, 반려생활의 든든한 파트너입니다.
        </p>
        <div class="flex flex-wrap justify-center gap-4">
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
      <div class="absolute left-10 top-20 h-32 w-32 rounded-full bg-secondary opacity-20 blur-3xl md:left-20"></div>
      <div class="absolute bottom-10 right-10 h-48 w-48 rounded-full bg-primary opacity-20 blur-3xl md:right-32"></div>
    </section>

    <!-- Premium Environment (Bento) -->
    <section class="bg-surface-container-lowest px-margin-mobile py-stack-lg md:px-margin-desktop">
      <div class="mx-auto max-w-container-max">
        <div class="mb-10 flex flex-col justify-between gap-4 md:flex-row md:items-end">
          <div>
            <h2 class="mb-2 font-headline-lg text-headline-lg text-primary">프리미엄 환경</h2>
            <p class="max-w-xl font-body-md text-on-surface-variant">
              모든 크기와 성향의 반려견이 스트레스 없이 편안하게 지낼 수 있도록 설계된 공간입니다.
            </p>
          </div>
        </div>

        <div class="grid auto-rows-[300px] grid-cols-1 gap-gutter md:grid-cols-3">
          <!-- Large feature -->
          <div class="group relative overflow-hidden rounded-[2rem] border border-surface-container-highest shadow-sm md:col-span-2 md:row-span-2">
            <img
              class="h-full w-full object-cover transition-transform duration-700 group-hover:scale-105"
              alt="자연광이 가득한 실내 놀이방에서 뛰노는 반려견들"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuAKg4MTE7G5x2f5lIp6yMWMOYzvJpjFODc6dggrlvpwpNXC_jQ3hR46gqjtZ9dMXpmLUwmZLS3vnCd6e4sHyYhIU3e5YY8j-pT3Vti9v-41F_TUzrDhGo3DLe-SCJQ_oeQQrARo5HF0gwUC9HJI5m8iu9djo9fHixhdJe1ZhXEcmvQPem5-6uO8RYymJyfb-RPl8muFVjaLXzO6MYVFFn3d9sax7cAN4S8SnehkZvISroOtEQc6qrULeQ"
            />
            <div class="absolute inset-0 flex flex-col justify-end bg-gradient-to-t from-primary/80 to-transparent p-8">
              <span class="mb-3 w-fit rounded-full bg-white/20 px-3 py-1 font-label-sm text-white backdrop-blur-md">실내 놀이 공간</span>
              <h3 class="mb-2 font-headline-md text-headline-md text-white">냉난방 완비 실내 놀이방</h3>
              <p class="font-body-md text-white/80">
                넓은 실내 공간은 연중 쾌적한 온도를 유지해 날씨와 상관없이 편안한 놀이가 가능합니다.
              </p>
            </div>
          </div>

          <!-- 24/7 care -->
          <div class="flex flex-col items-center justify-center rounded-xl border border-surface-container-highest bg-white p-6 text-center shadow-sm">
            <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-surface-container text-primary">
              <span class="material-symbols-outlined icon-filled text-3xl">medical_services</span>
            </div>
            <h4 class="mb-2 font-headline-md text-xl text-primary">24시간 케어</h4>
            <p class="text-sm text-on-surface-variant">수의사 온콜 대기, 24시간 상주 케어 인력.</p>
          </div>

          <div
            v-for="f in facilities"
            :key="f.title"
            class="group relative overflow-hidden rounded-xl border border-surface-container-highest shadow-sm"
          >
            <img class="h-full w-full object-cover" :alt="f.title" :src="f.img" />
            <div class="absolute inset-0 bg-black/30 transition-colors duration-300 group-hover:bg-black/10"></div>
            <div class="absolute bottom-4 left-4 right-4 text-white">
              <h4 class="text-lg font-bold drop-shadow-md">{{ f.title }}</h4>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Location & Contact -->
    <section class="bg-surface-container-lowest px-margin-mobile py-stack-lg md:px-margin-desktop">
      <div class="mx-auto flex max-w-container-max flex-col overflow-hidden rounded-2xl border border-surface-container-highest bg-white shadow-sm md:flex-row">
        <div class="flex bg-surface-container-low p-4 md:w-1/2">
          <CommonLocationMap :rounded="true" height="min-h-[300px] flex-1" class="w-full" />
        </div>
        <div class="p-8 md:w-1/2 md:p-12">
          <h2 class="mb-6 font-headline-lg text-headline-lg text-primary">오시는 길</h2>
          <ul class="space-y-6">
            <li class="flex items-start gap-4">
              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface-container-high text-primary">
                <span class="material-symbols-outlined">location_on</span>
              </div>
              <div>
                <h4 class="mb-1 font-label-md text-primary">주소</h4>
                <p class="font-body-md text-on-surface-variant">{{ BUSINESS_INFO.address }}<br />{{ BUSINESS_INFO.name }}</p>
              </div>
            </li>
            <li v-if="BUSINESS_INFO.phone" class="flex items-start gap-4">
              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface-container-high text-primary">
                <span class="material-symbols-outlined">call</span>
              </div>
              <div>
                <h4 class="mb-1 font-label-md text-primary">전화</h4>
                <p class="font-body-md text-on-surface-variant">{{ BUSINESS_INFO.phone }}</p>
              </div>
            </li>
            <li class="flex items-start gap-4">
              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface-container-high text-primary">
                <span class="material-symbols-outlined">schedule</span>
              </div>
              <div>
                <h4 class="mb-1 font-label-md text-primary">운영 시간</h4>
                <p class="font-body-md text-on-surface-variant">{{ BUSINESS_INFO.hours }}</p>
              </div>
            </li>
          </ul>
          <div class="mt-8 border-t border-surface-container-highest pt-8">
            <NuxtLink to="/reservation" class="btn-warm">지금 예약하기</NuxtLink>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
