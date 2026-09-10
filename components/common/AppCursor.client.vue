<script setup lang="ts">
// 데스크톱 전용 커스텀 커서 (점 + 링). 터치/reduced-motion 에서는 렌더 안 함.
const enabled = ref(false)
const dot = ref<HTMLElement | null>(null)
const ring = ref<HTMLElement | null>(null)
const hovering = ref(false)
const down = ref(false)

let raf = 0
const mouse = { x: 0, y: 0 }
const ringPos = { x: 0, y: 0 }

onMounted(() => {
  const fine = window.matchMedia('(pointer: fine)').matches
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  if (!fine || reduce) return
  enabled.value = true
  document.documentElement.classList.add('has-cursor')

  const onMove = (e: MouseEvent) => {
    mouse.x = e.clientX
    mouse.y = e.clientY
    if (dot.value) dot.value.style.transform = `translate3d(${e.clientX}px, ${e.clientY}px, 0)`
    const t = e.target as HTMLElement
    hovering.value = !!t.closest('a, button, [role="button"], input, select, textarea, label, .cursor-grow')
  }
  const onDown = () => (down.value = true)
  const onUp = () => (down.value = false)
  const onLeave = () => (enabled.value = false)
  const onEnter = () => (enabled.value = true)

  window.addEventListener('mousemove', onMove, { passive: true })
  window.addEventListener('mousedown', onDown)
  window.addEventListener('mouseup', onUp)
  document.addEventListener('mouseleave', onLeave)
  document.addEventListener('mouseenter', onEnter)

  const loop = () => {
    ringPos.x += (mouse.x - ringPos.x) * 0.16
    ringPos.y += (mouse.y - ringPos.y) * 0.16
    if (ring.value) ring.value.style.transform = `translate3d(${ringPos.x}px, ${ringPos.y}px, 0)`
    raf = requestAnimationFrame(loop)
  }
  raf = requestAnimationFrame(loop)

  onBeforeUnmount(() => {
    cancelAnimationFrame(raf)
    window.removeEventListener('mousemove', onMove)
    window.removeEventListener('mousedown', onDown)
    window.removeEventListener('mouseup', onUp)
    document.removeEventListener('mouseleave', onLeave)
    document.removeEventListener('mouseenter', onEnter)
    document.documentElement.classList.remove('has-cursor')
  })
})
</script>

<template>
  <ClientOnly>
    <div v-if="enabled" class="cursor-layer" aria-hidden="true">
      <div ref="ring" class="cursor-ring" :class="{ 'is-hover': hovering, 'is-down': down }" />
      <div ref="dot" class="cursor-dot" :class="{ 'is-hover': hovering }" />
    </div>
  </ClientOnly>
</template>
