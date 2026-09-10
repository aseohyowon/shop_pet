<script setup lang="ts">
// 첫 방문(세션당 1회, 홈에서만) 인트로 애니메이션.
// "홈페이지 바로가기" 클릭 또는 수 초 후 자동으로 사라진다. (CSS 트랜지션 기반)
const SESSION_KEY = 'daengyi-intro-seen'

const show = ref(false)
const entered = ref(false)
const leaving = ref(false)
const { $lenis } = useNuxtApp() as any
let autoTimer: number | undefined
let cleanupTimer: number | undefined

const done = () => {
  show.value = false
  document.documentElement.classList.remove('intro-lock')
  $lenis?.()?.start?.()
  window.dispatchEvent(new CustomEvent('intro:done'))
}

const finish = () => {
  if (leaving.value) return
  leaving.value = true
  try {
    sessionStorage.setItem(SESSION_KEY, '1')
  } catch {}
  window.clearTimeout(autoTimer)
  // CSS 트랜지션(0.8s) 후 제거 — 타이머 fallback 으로 확실히 종료
  cleanupTimer = window.setTimeout(done, 850)
}

onMounted(() => {
  const isHome = window.location.pathname === '/'
  let seen = false
  try {
    seen = sessionStorage.getItem(SESSION_KEY) === '1'
  } catch {}
  if (!isHome || seen) return

  show.value = true
  document.documentElement.classList.add('intro-lock')
  $lenis?.()?.stop?.()

  requestAnimationFrame(() => requestAnimationFrame(() => (entered.value = true)))
  setTimeout(() => (entered.value = true), 60) // rAF 스로틀 대비

  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  autoTimer = window.setTimeout(finish, reduce ? 500 : 4400)
})

onBeforeUnmount(() => {
  window.clearTimeout(autoTimer)
  window.clearTimeout(cleanupTimer)
})
</script>

<template>
  <div v-if="show">
    <div
      class="intro fixed inset-0 z-[10000] flex flex-col items-center justify-center bg-[#fff8f5] px-6 text-center"
      :class="{ 'intro--in': entered, 'intro--out': leaving }"
    >
        <div
          class="pointer-events-none absolute inset-0 opacity-60"
          style="background-image: radial-gradient(#efdfd7 1px, transparent 1px); background-size: 22px 22px"
        />
        <div class="intro-blob absolute left-8 top-24 h-40 w-40 rounded-full bg-secondary opacity-20 blur-3xl" />
        <div class="intro-blob absolute bottom-16 right-8 h-52 w-52 rounded-full bg-primary opacity-20 blur-3xl" />

        <div class="relative z-10 flex flex-col items-center">
          <img
            src="/images/logo-full.png"
            alt="댕이를 부탁해"
            class="intro-logo mb-8 h-36 w-auto object-contain sm:h-48"
          />
          <h1 class="mb-2 font-headline-lg text-[clamp(1.5rem,5vw,2.5rem)] font-bold leading-tight text-primary">
            <span class="intro-line block overflow-hidden"><span class="intro-word inline-block">우리 아이를 위한</span></span>
            <span class="intro-line block overflow-hidden"><span class="intro-word inline-block">가장 안전한 두 번째 집</span></span>
          </h1>

          <div class="intro-bar mt-8 h-[3px] w-56 overflow-hidden rounded-full bg-surface-container-highest">
            <div class="intro-bar__fill h-full rounded-full bg-primary" />
          </div>

          <button
            type="button"
            class="intro-cta mt-9 inline-flex items-center gap-2 rounded-full bg-primary px-7 py-3 font-label-md text-on-primary shadow-lg transition-transform hover:-translate-y-0.5"
            @click="finish"
          >
            홈페이지 바로가기
            <span class="material-symbols-outlined text-[20px]">arrow_forward</span>
          </button>
        </div>

      <button
        type="button"
        class="absolute bottom-8 right-8 z-10 font-label-sm text-label-sm uppercase tracking-widest text-on-surface-variant hover:text-primary"
        @click="finish"
      >
        Skip
      </button>
    </div>
  </div>
</template>

<style scoped>
.intro {
  transition: transform 0.8s cubic-bezier(0.7, 0, 0.2, 1), opacity 0.4s ease;
}
.intro--out {
  transform: translateY(-101%);
}

.intro-logo {
  opacity: 0;
  transform: scale(0.7);
  transition: opacity 0.8s cubic-bezier(0.16, 1, 0.3, 1), transform 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}
.intro-word {
  transform: translateY(115%);
  transition: transform 0.8s cubic-bezier(0.16, 1, 0.3, 1);
}
.intro-line:nth-child(2) .intro-word {
  transition-delay: 0.1s;
}
.intro-cta {
  opacity: 0;
  transform: translateY(14px);
  transition: opacity 0.6s ease 0.6s, transform 0.6s ease 0.6s;
}
.intro-bar__fill {
  width: 0%;
}

.intro--in .intro-logo {
  opacity: 1;
  transform: scale(1);
}
.intro--in .intro-word {
  transform: none;
}
.intro--in .intro-cta {
  opacity: 1;
  transform: none;
}
.intro--in .intro-bar__fill {
  width: 100%;
  transition: width 3.6s cubic-bezier(0.4, 0, 0.2, 1) 0.3s;
}
.intro-blob {
  animation: intro-float 6s ease-in-out infinite alternate;
}
@keyframes intro-float {
  to {
    transform: translate(20px, -16px) scale(1.1);
  }
}
@media (prefers-reduced-motion: reduce) {
  .intro-logo,
  .intro-word,
  .intro-cta {
    opacity: 1;
    transform: none;
    transition: none;
  }
  .intro-bar__fill {
    width: 100%;
  }
  .intro-blob {
    animation: none;
  }
}
</style>
