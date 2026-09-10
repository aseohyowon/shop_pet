<script setup lang="ts">
// 스크롤 진입 시 부드럽게 나타나는 래퍼.
// IntersectionObserver + scroll 폴백 + 타임아웃 폴백 (콘텐츠가 절대 숨은 채 남지 않도록)
const props = withDefaults(
  defineProps<{
    as?: string
    y?: number
    x?: number
    scale?: number
    delay?: number
    duration?: number
  }>(),
  { as: 'div', y: 44, x: 0, scale: 1, delay: 0, duration: 820 }
)

const el = ref<HTMLElement | null>(null)
const shown = ref(false)

onMounted(() => {
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (reduce || !el.value) {
    shown.value = true
    return
  }

  const reveal = () => {
    shown.value = true
    cleanup()
  }
  const check = () => {
    if (shown.value || !el.value) return
    const r = el.value.getBoundingClientRect()
    if (r.top < window.innerHeight * 0.92 && r.bottom > 0) reveal()
  }

  const io = new IntersectionObserver(
    ([entry]) => {
      if (entry.isIntersecting) reveal()
    },
    { threshold: 0, rootMargin: '0px 0px -8% 0px' }
  )
  io.observe(el.value)
  window.addEventListener('scroll', check, { passive: true })
  window.addEventListener('resize', check)
  // 안전장치: 그래도 안 나타나면 5초 뒤 표시
  const t = window.setTimeout(reveal, 5000)
  // 최초 위치 체크
  requestAnimationFrame(check)
  setTimeout(check, 100)

  function cleanup() {
    io.disconnect()
    window.removeEventListener('scroll', check)
    window.removeEventListener('resize', check)
    window.clearTimeout(t)
  }
  onBeforeUnmount(cleanup)
})

const style = computed(() => ({
  '--rv-y': `${props.y}px`,
  '--rv-x': `${props.x}px`,
  '--rv-scale': props.scale,
  '--rv-dur': `${props.duration}ms`,
  '--rv-delay': `${props.delay}ms`
}))
</script>

<template>
  <component :is="props.as" ref="el" class="reveal" :class="{ 'reveal--in': shown }" :style="style">
    <slot />
  </component>
</template>

<style scoped>
.reveal {
  opacity: 0;
  transform: translate3d(var(--rv-x, 0), var(--rv-y, 44px), 0) scale(var(--rv-scale, 1));
  transition:
    opacity var(--rv-dur, 820ms) cubic-bezier(0.16, 1, 0.3, 1) var(--rv-delay, 0ms),
    transform var(--rv-dur, 820ms) cubic-bezier(0.16, 1, 0.3, 1) var(--rv-delay, 0ms);
  will-change: opacity, transform;
}
.reveal--in {
  opacity: 1;
  transform: translate3d(0, 0, 0) scale(1);
}
@media (prefers-reduced-motion: reduce) {
  .reveal {
    opacity: 1;
    transform: none;
    transition: none;
  }
}
</style>
