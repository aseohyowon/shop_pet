<script setup lang="ts">
import { BUSINESS_INFO } from '~/utils/businessInfo'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

const reduced = ref(false)

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

const headline = ['우리 아이를 위한', '가장 안전한 두 번째 집']

const root = ref<HTMLElement | null>(null)
const blobA = ref<HTMLElement | null>(null)
const blobB = ref<HTMLElement | null>(null)
const heroPattern = ref<HTMLElement | null>(null)
const bentoImg = ref<HTMLElement | null>(null)
const mapWrap = ref<HTMLElement | null>(null)

const heroEl = ref<HTMLElement | null>(null)
const heroIn = ref(false)
let ctx: gsap.Context | null = null

onMounted(() => {
  reduced.value = window.matchMedia('(prefers-reduced-motion: reduce)').matches

  // 히어로 등장은 CSS 트랜지션으로 (탭 비활성/저사양에서도 확실히 동작)
  requestAnimationFrame(() => (heroIn.value = true))
  setTimeout(() => (heroIn.value = true), 80)

  if (reduced.value) return
  gsap.registerPlugin(ScrollTrigger)

  ctx = gsap.context((self) => {
    const q = self.selector!

    // 히어로 배경 패턴 / 블롭 패럴럭스
    if (heroPattern.value) {
      gsap.to(heroPattern.value, {
        yPercent: 18,
        ease: 'none',
        scrollTrigger: { trigger: root.value, start: 'top top', end: 'bottom top', scrub: true }
      })
    }
    gsap.to(blobA.value, {
      y: 140,
      scrollTrigger: { trigger: root.value, start: 'top top', end: '60% top', scrub: 1 }
    })
    gsap.to(blobB.value, {
      y: -120,
      scrollTrigger: { trigger: root.value, start: 'top top', end: '60% top', scrub: 1 }
    })

    // 프리미엄 섹션 대형 이미지: 스크롤에 따라 확대 → 축소 (줌 스크럽)
    if (bentoImg.value) {
      gsap.fromTo(
        bentoImg.value,
        { scale: 1.35 },
        {
          scale: 1,
          ease: 'none',
          scrollTrigger: { trigger: bentoImg.value, start: 'top bottom', end: 'top 30%', scrub: true }
        }
      )
    }

    // 지도 섹션 살짝 떠오르며 회전
    if (mapWrap.value) {
      gsap.from(mapWrap.value, {
        y: 90,
        rotateX: 8,
        opacity: 0.4,
        scrollTrigger: { trigger: mapWrap.value, start: 'top 85%', end: 'top 45%', scrub: 1 }
      })
    }

    // 섹션 제목 마스크 라인 등장
    q('.reveal-line').forEach((el: HTMLElement) => {
      ScrollTrigger.create({
        trigger: el,
        start: 'top 92%',
        once: true,
        onEnter: () => el.classList.add('reveal-line--in')
      })
    })
  }, root.value!)

  setTimeout(() => ScrollTrigger.refresh(), 300)
  // 안전장치: 무슨 이유로든 안 나타나면 강제 표시
  setTimeout(() => {
    root.value?.querySelectorAll('.reveal-line').forEach((el) => el.classList.add('reveal-line--in'))
  }, 5000)
})

onBeforeUnmount(() => ctx?.revert())
</script>

<template>
  <div ref="root">
    <!-- Hero -->
    <section
      ref="heroEl"
      class="hero relative min-h-[92vh] overflow-hidden px-margin-mobile pb-24 pt-stack-lg md:px-margin-desktop"
      :class="{ 'hero--in': heroIn }"
      style="background-color: #fff8f5"
    >
      <div
        ref="heroPattern"
        class="pointer-events-none absolute -inset-x-0 -top-[10%] h-[130%]"
        style="background-image: radial-gradient(#efdfd7 1px, transparent 1px); background-size: 22px 22px"
      />
      <div
        ref="blobA"
        class="pointer-events-none absolute left-6 top-24 h-40 w-40 rounded-full bg-secondary opacity-25 blur-3xl md:left-24 md:h-64 md:w-64"
      />
      <div
        ref="blobB"
        class="pointer-events-none absolute bottom-6 right-6 h-56 w-56 rounded-full bg-primary opacity-25 blur-3xl md:right-32 md:h-72 md:w-72"
      />

      <div class="relative z-10 mx-auto flex min-h-[70vh] max-w-container-max flex-col items-center justify-center text-center">
        <div class="hero-badge mb-7 inline-flex items-center gap-2 rounded-full border border-surface-container-highest bg-white/80 px-4 py-2 shadow-sm backdrop-blur cursor-grow">
          <span class="h-2 w-2 animate-pulse rounded-full bg-secondary" />
          <span class="font-label-sm text-label-sm uppercase tracking-[0.2em] text-on-surface-variant">Premium Pet Care</span>
        </div>

        <h1 class="mx-auto mb-7 max-w-4xl text-[clamp(2rem,6vw,4.2rem)] font-bold leading-[1.1] text-primary">
          <span v-for="(line, li) in headline" :key="li" class="block overflow-hidden py-[0.06em]">
            <span class="hero-word inline-block">{{ line }}</span>
          </span>
        </h1>

        <p class="hero-sub mx-auto mb-10 max-w-2xl font-body-lg text-body-lg text-on-surface-variant">
          모든 반려동물이 집처럼 편안한 공간에서 사랑과 안전, 전문적인 케어를 받을 자격이 있다고 믿습니다.
          댕이를 부탁해는 단순한 애견호텔이 아니라, 반려생활의 든든한 파트너입니다.
        </p>

        <div class="hero-cta flex flex-wrap justify-center gap-4">
          <NuxtLink to="/reservation" class="btn-warm cursor-grow">
            <span class="material-symbols-outlined">calendar_month</span>
            예약하기
          </NuxtLink>
          <NuxtLink to="/pricing" class="btn-warm-soft cursor-grow">
            <span class="material-symbols-outlined">payments</span>
            이용 요금 보기
          </NuxtLink>
        </div>
      </div>

      <div class="hero-scroll absolute bottom-8 left-1/2 z-10 flex -translate-x-1/2 flex-col items-center gap-2 text-on-surface-variant">
        <span class="font-label-sm text-[11px] uppercase tracking-widest">Scroll</span>
        <span class="h-10 w-px animate-scroll-hint bg-on-surface-variant/40" />
      </div>
    </section>

    <!-- Marquee -->
    <div class="border-y border-surface-container-highest bg-primary py-5 font-headline-md text-headline-md text-on-primary">
      <MotionMarquee
        :items="['댕이를 부탁해', '애견호텔', '데이케어', '프리미엄 케어', '24시간 상주', '냉난방 완비']"
        :speed="34"
        separator="✦"
      />
    </div>

    <!-- Premium Environment (Bento) -->
    <section class="bg-surface-container-lowest px-margin-mobile py-stack-lg md:px-margin-desktop">
      <div class="mx-auto max-w-container-max">
        <div class="mb-12 flex flex-col justify-between gap-4 md:flex-row md:items-end">
          <div>
            <h2 class="mb-3 overflow-hidden font-headline-lg text-headline-lg text-primary">
              <span class="reveal-line inline-block">프리미엄 환경</span>
            </h2>
            <MotionReveal :y="24" :delay="120">
              <p class="max-w-xl font-body-md text-on-surface-variant">
                모든 크기와 성향의 반려견이 스트레스 없이 편안하게 지낼 수 있도록 설계된 공간입니다.
              </p>
            </MotionReveal>
          </div>
        </div>

        <div class="grid auto-rows-[300px] grid-cols-1 gap-gutter md:grid-cols-3">
          <MotionReveal
            as="div"
            :y="60"
            class="group relative overflow-hidden rounded-[2rem] border border-surface-container-highest shadow-sm md:col-span-2 md:row-span-2"
          >
            <img
              ref="bentoImg"
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
          </MotionReveal>

          <MotionReveal
            as="div"
            :y="50"
            :delay="80"
            class="flex flex-col items-center justify-center rounded-xl border border-surface-container-highest bg-white p-6 text-center shadow-sm cursor-grow transition-transform hover:-translate-y-1"
          >
            <div class="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-surface-container text-primary">
              <span class="material-symbols-outlined icon-filled text-3xl">medical_services</span>
            </div>
            <h4 class="mb-2 font-headline-md text-xl text-primary">24시간 케어</h4>
            <p class="text-sm text-on-surface-variant">수의사 온콜 대기, 24시간 상주 케어 인력.</p>
          </MotionReveal>

          <MotionReveal
            v-for="(f, fi) in facilities"
            :key="f.title"
            as="div"
            :y="50"
            :delay="120 + fi * 90"
            class="group relative overflow-hidden rounded-xl border border-surface-container-highest shadow-sm cursor-grow"
          >
            <img class="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110" :alt="f.title" :src="f.img" />
            <div class="absolute inset-0 bg-black/30 transition-colors duration-300 group-hover:bg-black/10" />
            <div class="absolute bottom-4 left-4 right-4 text-white">
              <h4 class="text-lg font-bold drop-shadow-md">{{ f.title }}</h4>
            </div>
          </MotionReveal>
        </div>
      </div>
    </section>

    <!-- Stats -->
    <section class="bg-primary px-margin-mobile py-stack-lg text-on-primary md:px-margin-desktop">
      <div class="mx-auto grid max-w-container-max grid-cols-1 gap-gutter text-center sm:grid-cols-3">
        <MotionReveal :y="40" :delay="0">
          <p class="font-headline-xl text-[clamp(2.5rem,7vw,4rem)] font-bold leading-none">
            <MotionCountUp :to="24" />시간
          </p>
          <p class="mt-3 font-body-md text-on-primary/70">상주 케어 인력</p>
        </MotionReveal>
        <MotionReveal :y="40" :delay="120">
          <p class="font-headline-xl text-[clamp(2.5rem,7vw,4rem)] font-bold leading-none">
            <MotionCountUp :to="365" />일
          </p>
          <p class="mt-3 font-body-md text-on-primary/70">연중무휴 운영</p>
        </MotionReveal>
        <MotionReveal :y="40" :delay="240">
          <p class="font-headline-xl text-[clamp(2.5rem,7vw,4rem)] font-bold leading-none">
            <MotionCountUp :to="100" />%
          </p>
          <p class="mt-3 font-body-md text-on-primary/70">냉난방 완비 공간</p>
        </MotionReveal>
      </div>
    </section>

    <!-- Location & Contact -->
    <section class="bg-surface-container-lowest px-margin-mobile py-stack-lg md:px-margin-desktop">
      <div class="mx-auto max-w-container-max">
        <h2 class="mb-8 overflow-hidden pb-[0.1em] font-headline-lg text-headline-lg text-primary">
          <span class="reveal-line inline-block">오시는 길</span>
        </h2>
        <div
          ref="mapWrap"
          class="flex flex-col overflow-hidden rounded-2xl border border-surface-container-highest bg-white shadow-sm md:flex-row"
          style="perspective: 1000px"
        >
          <div class="flex bg-surface-container-low p-4 md:w-1/2">
            <CommonLocationMap :rounded="true" height="min-h-[300px] flex-1" class="w-full" />
          </div>
          <div class="p-8 md:w-1/2 md:p-12">
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
              <NuxtLink to="/reservation" class="btn-warm cursor-grow">지금 예약하기</NuxtLink>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* 히어로 등장 — CSS 트랜지션 (js-motion 일 때만 숨김 시작) */
:global(.js-motion) .hero-badge,
:global(.js-motion) .hero-sub,
:global(.js-motion) .hero-cta,
:global(.js-motion) .hero-scroll {
  opacity: 0;
  transform: translateY(26px);
  transition: opacity 0.9s cubic-bezier(0.16, 1, 0.3, 1), transform 0.9s cubic-bezier(0.16, 1, 0.3, 1);
}
:global(.js-motion) .hero-word {
  display: inline-block;
  transform: translateY(115%);
  transition: transform 1s cubic-bezier(0.16, 1, 0.3, 1);
}
.hero--in .hero-badge {
  opacity: 1;
  transform: none;
  transition-delay: 0.05s;
}
.hero--in .hero-word {
  transform: none;
}
.hero h1 > span:nth-child(1) .hero-word {
  transition-delay: 0.14s;
}
.hero h1 > span:nth-child(2) .hero-word {
  transition-delay: 0.26s;
}
.hero--in .hero-sub {
  opacity: 1;
  transform: none;
  transition-delay: 0.5s;
}
.hero--in .hero-cta {
  opacity: 1;
  transform: none;
  transition-delay: 0.62s;
}
.hero--in .hero-scroll {
  opacity: 1;
  transform: none;
  transition-delay: 0.9s;
}
@media (prefers-reduced-motion: reduce) {
  :global(.js-motion) .hero-badge,
  :global(.js-motion) .hero-sub,
  :global(.js-motion) .hero-cta,
  :global(.js-motion) .hero-scroll,
  :global(.js-motion) .hero-word {
    opacity: 1;
    transform: none;
    transition: none;
  }
}

/* 섹션 제목 마스크 라인 */
.reveal-line {
  display: inline-block;
}
:global(.js-motion) .reveal-line {
  transform: translateY(115%);
  transition: transform 0.9s cubic-bezier(0.16, 1, 0.3, 1);
}
.reveal-line--in {
  transform: none !important;
}
@media (prefers-reduced-motion: reduce) {
  :global(.js-motion) .reveal-line {
    transform: none;
    transition: none;
  }
}

@keyframes scroll-hint {
  0%,
  100% {
    transform: scaleY(0.3);
    transform-origin: top;
    opacity: 0.3;
  }
  50% {
    transform: scaleY(1);
    transform-origin: top;
    opacity: 1;
  }
}
.animate-scroll-hint {
  animation: scroll-hint 2s ease-in-out infinite;
}
</style>
