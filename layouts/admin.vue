<script setup lang="ts">
const router = useRouter()
const { profile, signOut } = useAuth()

const handleLogout = async () => {
  await signOut()
  await router.push('/admin/login')
}
</script>

<template>
  <div class="flex min-h-screen bg-surface-container-low font-body-md text-on-surface">
    <AdminSidebar />
    <div class="flex min-w-0 flex-1 flex-col">
      <header
        class="flex h-16 items-center justify-between border-b border-outline-variant/40 bg-surface px-4 shadow-sm shadow-primary/5 md:px-8"
      >
        <p class="font-label-md text-label-md text-on-surface-variant">관리자 페이지</p>
        <div class="flex items-center gap-3 text-sm text-on-surface-variant">
          <span class="font-label-sm text-label-sm">{{ profile?.name ?? '관리자' }}님</span>
          <button
            type="button"
            class="rounded-full border border-outline-variant/50 bg-primary-fixed/20 px-3.5 py-1.5 font-label-sm text-label-sm text-primary transition-colors hover:bg-primary-fixed/40"
            @click="handleLogout"
          >
            로그아웃
          </button>
        </div>
      </header>
      <main class="mx-auto w-full max-w-container-max flex-1 p-4 md:p-8">
        <slot />
      </main>
    </div>
  </div>
</template>
