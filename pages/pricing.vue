<script setup lang="ts">
useHead({ title: '이용 요금 — 댕이를 부탁해' })

const { fetchActiveGrouped } = usePricing()
const { isWarm } = useSiteTheme()

const { data: groups } = await useAsyncData('pricing-page', fetchActiveGrouped, { default: () => [] })

const won = (n: number) => `${n.toLocaleString()}원`
</script>

<template>
  <!-- ══════════ Warm 테마 ══════════ -->
  <div v-if="isWarm" class="container-warm py-12">
    <div class="mb-10">
      <h1 class="mb-3 font-headline-xl text-[36px] text-primary md:text-headline-xl">이용 요금</h1>
      <p class="font-body-lg text-body-lg text-on-surface-variant">
        데이케어 · 호텔 · 스파 이용 요금 안내입니다. 스파는 이용 여부와 관계없이 별도 요금입니다.
      </p>
    </div>

    <div class="grid gap-gutter md:grid-cols-2">
      <section v-for="g in groups" :key="g.key" class="card-warm p-7">
        <h2 class="mb-5 flex items-center gap-3 font-headline-md text-headline-md text-primary">
          <span class="material-symbols-outlined rounded-full bg-secondary-container p-2 text-secondary">{{ g.icon }}</span>
          {{ g.label }}
        </h2>
        <ul class="divide-y divide-outline-variant/40">
          <li v-for="item in g.items" :key="item.id" class="flex items-start justify-between gap-4 py-3">
            <div>
              <p class="font-label-md text-label-md text-on-surface">{{ item.name }}</p>
              <p v-if="item.note" class="mt-0.5 font-label-sm text-label-sm text-on-surface-variant">{{ item.note }}</p>
            </div>
            <div class="shrink-0 text-right">
              <p class="font-headline-md text-lg text-primary">{{ won(item.price) }}</p>
              <p v-if="item.unit" class="font-label-sm text-label-sm text-on-surface-variant">/ {{ item.unit }}</p>
              <NuxtLink
                v-if="g.key === 'daycare_pass'"
                :to="`/checkout/pass?item=${item.id}`"
                class="mt-1 inline-block rounded-lg bg-secondary px-3 py-1 font-label-sm text-label-sm text-on-secondary"
              >
                구매하기
              </NuxtLink>
            </div>
          </li>
        </ul>
      </section>
    </div>

    <p class="mt-8 font-label-sm text-label-sm text-outline">
      · 종일 데이케어는 09:00~18:00 기준이며 산책 1회가 포함됩니다.<br />
      · 호텔은 1박 기준 산책 1회 포함, 추가 산책은 1회당 요금이 부과됩니다.<br />
      · 표시 요금은 안내용이며 실제 결제 금액은 예약 화면에서 확인하실 수 있습니다.
    </p>

    <div class="mt-8">
      <NuxtLink to="/reservation" class="inline-flex h-12 items-center rounded-xl bg-primary-container px-6 font-headline-md text-[16px] text-on-primary shadow-md hover:bg-primary">
        예약하러 가기 →
      </NuxtLink>
    </div>
  </div>

  <!-- ══════════ 기본 테마 ══════════ -->
  <div v-else class="container-page max-w-4xl py-12">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">이용 요금</h1>
    <p class="mb-8 text-gray-500">데이케어 · 호텔 · 스파 이용 요금 안내입니다.</p>

    <div class="grid gap-6 sm:grid-cols-2">
      <div v-for="g in groups" :key="g.key" class="card">
        <p class="mb-3 font-semibold text-gray-900">{{ g.label }}</p>
        <ul class="divide-y divide-gray-100">
          <li v-for="item in g.items" :key="item.id" class="flex items-start justify-between gap-3 py-2.5">
            <div>
              <p class="text-sm font-medium text-gray-800">{{ item.name }}</p>
              <p v-if="item.note" class="text-xs text-gray-400">{{ item.note }}</p>
            </div>
            <div class="shrink-0 text-right">
              <p class="text-sm font-bold text-brand-600">{{ won(item.price) }}</p>
              <p v-if="item.unit" class="text-xs text-gray-400">/ {{ item.unit }}</p>
              <NuxtLink
                v-if="g.key === 'daycare_pass'"
                :to="`/checkout/pass?item=${item.id}`"
                class="mt-1 inline-block rounded-md bg-brand-500 px-2.5 py-1 text-xs font-semibold text-white"
              >
                구매하기
              </NuxtLink>
            </div>
          </li>
        </ul>
      </div>
    </div>

    <p class="mt-6 text-xs leading-relaxed text-gray-400">
      · 종일 데이케어는 09:00~18:00 기준이며 산책 1회가 포함됩니다.<br />
      · 호텔은 1박 기준 산책 1회 포함, 추가 산책은 1회당 요금이 부과됩니다.<br />
      · 표시 요금은 안내용이며 실제 결제 금액은 예약 화면에서 확인하실 수 있습니다.
    </p>

    <NuxtLink to="/reservation" class="btn-primary mt-6 inline-block">예약하러 가기 →</NuxtLink>
  </div>
</template>
