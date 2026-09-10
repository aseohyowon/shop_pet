<script setup lang="ts">
const bar = ref<HTMLElement | null>(null)
let raf = 0

onMounted(() => {
  const update = () => {
    const h = document.documentElement.scrollHeight - window.innerHeight
    const p = h > 0 ? Math.min(1, window.scrollY / h) : 0
    if (bar.value) bar.value.style.transform = `scaleX(${p})`
    raf = 0
  }
  const onScroll = () => {
    if (!raf) raf = requestAnimationFrame(update)
  }
  window.addEventListener('scroll', onScroll, { passive: true })
  window.addEventListener('resize', onScroll)
  update()
  onBeforeUnmount(() => {
    window.removeEventListener('scroll', onScroll)
    window.removeEventListener('resize', onScroll)
    if (raf) cancelAnimationFrame(raf)
  })
})
</script>

<template>
  <div ref="bar" class="scroll-progress w-full" style="transform: scaleX(0)" aria-hidden="true" />
</template>
