<script setup lang="ts">
const isMenuOpen = ref(false)
const router = useRouter()
const { user, profile, signOut } = useAuth()
const { fetchCart } = useCart()

const navLinks = [
  { label: '홈', to: '/' },
  { label: '예약', to: '/reservation' },
  { label: '쇼핑몰', to: '/shop' },
  { label: '마이페이지', to: '/mypage' },
  { label: '문의', to: '/contact' }
]

const cartCount = ref(0)
const loadCartCount = async () => {
  if (!user.value) {
    cartCount.value = 0
    return
  }
  try {
    const items = await fetchCart()
    cartCount.value = items.reduce((sum: number, it: any) => sum + (it.quantity ?? 0), 0)
  } catch {
    cartCount.value = 0
  }
}
watch(user, loadCartCount, { immediate: true })

const closeMenu = () => {
  isMenuOpen.value = false
}

const handleLogout = async () => {
  closeMenu()
  await signOut()
  await router.push('/')
}
</script>

<template>
  <header class="sticky top-0 z-40 w-full bg-background shadow-sm shadow-primary/5">
    <div class="container-warm flex h-20 items-center justify-between">
      <NuxtLink to="/" class="flex items-center gap-2 font-headline-md text-headline-md text-primary">
        <img src="/images/logo-icon.png" alt="댕이를 부탁해" class="h-10 w-10 object-contain" />
        <span class="hidden sm:block">댕이를 부탁해</span>
      </NuxtLink>

      <!-- Desktop nav -->
      <nav class="hidden items-center gap-8 md:flex">
        <NuxtLink
          v-for="link in navLinks"
          :key="link.to"
          :to="link.to"
          class="rounded-lg px-3 py-2 font-body-md text-on-surface-variant transition-colors hover:bg-surface-container-lowest hover:text-primary"
          active-class="!text-primary font-bold"
        >
          {{ link.label }}
        </NuxtLink>
      </nav>

      <div class="hidden items-center gap-3 md:flex">
        <NuxtLink
          to="/cart"
          class="relative flex h-10 w-10 items-center justify-center rounded-full bg-surface-container-high text-on-surface-variant transition-colors hover:text-primary"
          aria-label="장바구니"
        >
          <span class="material-symbols-outlined">shopping_cart</span>
          <span
            v-if="cartCount > 0"
            class="absolute -right-1 -top-1 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-secondary px-1 font-label-sm text-[11px] text-on-secondary"
          >
            {{ cartCount }}
          </span>
        </NuxtLink>

        <template v-if="user">
          <span class="font-label-sm text-label-sm text-on-surface-variant">{{ profile?.name ?? user.email }}님</span>
          <button
            type="button"
            class="rounded-full bg-primary-fixed/30 px-4 py-2 font-label-md text-label-md text-primary transition-colors hover:bg-primary-fixed/50"
            @click="handleLogout"
          >
            로그아웃
          </button>
        </template>
        <template v-else>
          <NuxtLink
            to="/login"
            class="rounded-full px-4 py-2 font-label-md text-label-md text-primary transition-colors hover:bg-surface-container"
          >
            로그인
          </NuxtLink>
          <NuxtLink
            to="/signup"
            class="rounded-full bg-primary px-6 py-3 font-label-md text-label-md text-on-primary shadow-sm transition-colors hover:bg-primary-container"
          >
            회원가입
          </NuxtLink>
        </template>
      </div>

      <!-- Mobile menu button -->
      <button
        type="button"
        class="flex h-12 w-12 items-center justify-center rounded-xl bg-surface-container-low text-primary md:hidden"
        aria-label="메뉴 열기"
        @click="isMenuOpen = !isMenuOpen"
      >
        <span class="material-symbols-outlined">{{ isMenuOpen ? 'close' : 'menu' }}</span>
      </button>
    </div>

    <!-- Mobile nav -->
    <nav v-if="isMenuOpen" class="border-t border-surface-container-high bg-background md:hidden">
      <div class="container-warm flex flex-col gap-1 py-3">
        <NuxtLink
          v-for="link in navLinks"
          :key="link.to"
          :to="link.to"
          class="rounded-lg px-3 py-2.5 font-body-md text-on-surface-variant hover:bg-surface-container-low"
          active-class="bg-surface-container-low !text-primary font-bold"
          @click="closeMenu"
        >
          {{ link.label }}
        </NuxtLink>
        <NuxtLink
          to="/cart"
          class="rounded-lg px-3 py-2.5 font-body-md text-on-surface-variant hover:bg-surface-container-low"
          @click="closeMenu"
        >
          장바구니<span v-if="cartCount > 0"> ({{ cartCount }})</span>
        </NuxtLink>

        <template v-if="user">
          <p class="px-3 pt-2 font-label-sm text-label-sm text-on-surface-variant">{{ profile?.name ?? user.email }}님</p>
          <button type="button" class="btn-warm mx-3 mt-1" @click="handleLogout">로그아웃</button>
        </template>
        <div v-else class="mt-2 flex gap-2 px-3">
          <NuxtLink to="/login" class="btn-warm-soft flex-1" @click="closeMenu">로그인</NuxtLink>
          <NuxtLink to="/signup" class="btn-warm flex-1" @click="closeMenu">회원가입</NuxtLink>
        </div>
      </div>
    </nav>
  </header>
</template>
