<template>
  <div class="flex min-h-screen flex-col bg-gray-50">
    <header class="py-6 text-center">
      <NuxtLink to="/" class="inline-block">
        <img src="/images/logo-full.png" alt="댕이를 부탁해 — 애견호텔&데이케어" class="mx-auto h-28 w-auto object-contain sm:h-32" />
      </NuxtLink>
    </header>
    <main class="flex flex-1 items-center justify-center px-4 pb-16">
      <div class="w-full max-w-md">
        <slot />
      </div>
    </main>
  </div>
</template>
