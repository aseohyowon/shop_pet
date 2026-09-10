<script setup lang="ts">
// 뷰포트 진입 시 0 → target 카운트업
const props = withDefaults(
  defineProps<{ to: number; duration?: number; prefix?: string; suffix?: string; decimals?: number }>(),
  { duration: 1600, prefix: '', suffix: '', decimals: 0 }
)
const el = ref<HTMLElement | null>(null)
const display = ref(0)
let reducedMotion = false

const format = (n: number) =>
  props.prefix + n.toLocaleString('ko-KR', { maximumFractionDigits: props.decimals }) + props.suffix

let started = false
const run = () => {
  if (started) return
  started = true
  cleanup()
  const start = performance.now()
  const tick = (now: number) => {
    const p = Math.min(1, (now - start) / props.duration)
    display.value = props.to * (1 - Math.pow(1 - p, 3))
    if (p < 1) requestAnimationFrame(tick)
    else display.value = props.to
  }
  requestAnimationFrame(tick)
  // rAF 가 멈춘 환경(백그라운드 탭 등) 대비: duration 후 최종값 보장
  window.setTimeout(() => (display.value = props.to), props.duration + 600)
}
let io: IntersectionObserver | undefined
const check = () => {
  if (started || !el.value) return
  const r = el.value.getBoundingClientRect()
  if (r.top < window.innerHeight * 0.9 && r.bottom > 0) run()
}
function cleanup() {
  io?.disconnect()
  window.removeEventListener('scroll', check)
  window.clearTimeout(fallback)
}
let fallback = 0

onMounted(() => {
  reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (reducedMotion) {
    display.value = props.to
    return
  }
  io = new IntersectionObserver(([e]) => e.isIntersecting && run(), { threshold: 0 })
  if (el.value) io.observe(el.value)
  window.addEventListener('scroll', check, { passive: true })
  fallback = window.setTimeout(run, 5000)
  requestAnimationFrame(check)
  onBeforeUnmount(cleanup)
})
</script>

<template>
  <span ref="el">{{ format(display) }}</span>
</template>
