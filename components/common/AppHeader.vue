<script setup lang="ts">
const isMenuOpen = ref(false)
const router = useRouter()
const { user, profile, signOut } = useAuth()
const { contactEnabled } = useSiteTheme()

const navLinks = computed(() => [
  { label: '홈', to: '/' },
  { label: '예약', to: '/reservation' },
  { label: '요금', to: '/pricing' },
  { label: '쇼핑몰', to: '/shop' },
  { label: '마이페이지', to: '/mypage' },
  ...(contactEnabled.value ? [{ label: '문의', to: '/contact' }] : [])
])

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
  <header class="sticky top-0 z-40 border-b border-gray-200 bg-white/90 backdrop-blur">
    <div class="container-page flex h-16 items-center justify-between">
      <NuxtLink to="/" class="flex items-center gap-2 text-lg font-bold text-brand-600">
        <img src="/images/logo-icon.png" alt="댕이를 부탁해" class="h-10 w-10 object-contain" />
        <span>댕이를 부탁해</span>
      </NuxtLink>

      <!-- Desktop nav -->
      <nav class="hidden items-center gap-8 md:flex">
        <NuxtLink
          v-for="link in navLinks"
          :key="link.to"
          :to="link.to"
          class="text-sm font-medium text-gray-600 transition hover:text-brand-600"
          active-class="text-brand-600"
        >
          {{ link.label }}
        </NuxtLink>
      </nav>

      <div class="hidden items-center gap-3 md:flex">
        <NuxtLink to="/cart" class="text-sm font-medium text-gray-600 hover:text-brand-600">
          장바구니
        </NuxtLink>

        <template v-if="user">
          <span class="text-sm text-gray-500">{{ profile?.name ?? user.email }}님</span>
          <button type="button" class="btn-secondary !px-3 !py-1.5 text-sm" @click="handleLogout">
            로그아웃
          </button>
        </template>
        <template v-else>
          <NuxtLink to="/login" class="btn-secondary !px-3 !py-1.5 text-sm">
            로그인
          </NuxtLink>
          <NuxtLink to="/signup" class="btn-primary !px-3 !py-1.5 text-sm">
            회원가입
          </NuxtLink>
        </template>
      </div>

      <!-- Mobile menu button -->
      <button
        type="button"
        class="inline-flex items-center justify-center rounded-lg p-2 text-gray-600 hover:bg-gray-100 md:hidden"
        aria-label="메뉴 열기"
        @click="isMenuOpen = !isMenuOpen"
      >
        <svg v-if="!isMenuOpen" class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
        <svg v-else class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <!-- Mobile nav -->
    <nav v-if="isMenuOpen" class="border-t border-gray-200 bg-white md:hidden">
      <div class="container-page flex flex-col gap-1 py-3">
        <NuxtLink
          v-for="link in navLinks"
          :key="link.to"
          :to="link.to"
          class="rounded-lg px-3 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
          active-class="bg-brand-50 text-brand-600"
          @click="closeMenu"
        >
          {{ link.label }}
        </NuxtLink>
        <NuxtLink to="/cart" class="rounded-lg px-3 py-2.5 text-sm font-medium text-gray-700 hover:bg-gray-50" @click="closeMenu">
          장바구니
        </NuxtLink>

        <template v-if="user">
          <p class="px-3 pt-2 text-sm text-gray-500">{{ profile?.name ?? user.email }}님</p>
          <button type="button" class="btn-secondary mx-3 mt-1 text-sm" @click="handleLogout">로그아웃</button>
        </template>
        <div v-else class="mt-2 flex gap-2 px-3">
          <NuxtLink to="/login" class="btn-secondary flex-1 text-sm" @click="closeMenu">로그인</NuxtLink>
          <NuxtLink to="/signup" class="btn-primary flex-1 text-sm" @click="closeMenu">회원가입</NuxtLink>
        </div>
      </div>
    </nav>
  </header>
</template>
