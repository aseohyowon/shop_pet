<script setup lang="ts">
// 카카오 등 OAuth 로그인 후 돌아오는 콜백 페이지.
// Supabase 클라이언트가 URL의 인증 정보를 자동으로 처리해 세션을 만들고,
// 그 결과로 useSupabaseUser()가 채워지는 것을 기다렸다가 원래 가려던 페이지로 이동한다.
definePageMeta({ layout: 'auth' })

const route = useRoute()
const router = useRouter()
const user = useSupabaseUser()

const errorMessage = ref('')
let timeoutId: ReturnType<typeof setTimeout>

watch(
  user,
  (u) => {
    if (u) {
      clearTimeout(timeoutId)
      const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/mypage'
      router.replace(redirect)
    }
  },
  { immediate: true }
)

onMounted(() => {
  timeoutId = setTimeout(() => {
    if (!user.value) {
      errorMessage.value = '로그인 처리 중 문제가 발생했습니다. 다시 시도해주세요.'
    }
  }, 8000)
})

onUnmounted(() => clearTimeout(timeoutId))
</script>

<template>
  <div class="card text-center">
    <template v-if="!errorMessage">
      <p class="text-2xl">⏳</p>
      <p class="mt-3 text-sm text-gray-500">로그인 처리 중입니다...</p>
    </template>
    <template v-else>
      <p class="text-2xl">⚠️</p>
      <p class="mt-3 text-sm text-red-500">{{ errorMessage }}</p>
      <NuxtLink to="/login" class="btn-secondary mt-4 inline-block">로그인 페이지로</NuxtLink>
    </template>
  </div>
</template>
