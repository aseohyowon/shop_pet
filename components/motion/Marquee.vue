<script setup lang="ts">
// 무한 흐르는 텍스트 띠
const props = withDefaults(
  defineProps<{ items?: string[]; speed?: number; reverse?: boolean; separator?: string }>(),
  { items: () => [], speed: 40, reverse: false, separator: '·' }
)
const reduced = ref(false)
onMounted(() => {
  reduced.value = window.matchMedia('(prefers-reduced-motion: reduce)').matches
})
const list = computed(() => (props.items.length ? props.items : ['댕이를 부탁해', '애견호텔', '데이케어', '프리미엄 케어']))
</script>

<template>
  <div class="marquee" :class="{ 'marquee--rev': reverse, 'marquee--still': reduced }">
    <div class="marquee__track" :style="{ '--speed': `${speed}s` }">
      <span v-for="n in 2" :key="n" class="marquee__group" aria-hidden="true">
        <template v-for="(t, i) in list" :key="`${n}-${i}`">
          <span class="marquee__item">{{ t }}</span>
          <span class="marquee__sep">{{ separator }}</span>
        </template>
      </span>
    </div>
  </div>
</template>

<style scoped>
.marquee {
  overflow: hidden;
  white-space: nowrap;
  width: 100%;
}
.marquee__track {
  display: inline-flex;
  animation: marquee var(--speed, 40s) linear infinite;
}
.marquee--rev .marquee__track {
  animation-direction: reverse;
}
.marquee--still .marquee__track {
  animation: none;
}
.marquee__group {
  display: inline-flex;
  align-items: center;
}
.marquee__item {
  padding: 0 0.4em;
}
.marquee__sep {
  opacity: 0.4;
}
@keyframes marquee {
  to {
    transform: translateX(-50%);
  }
}
</style>
