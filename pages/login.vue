<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const route = useRoute()
const router = useRouter()
const { signIn, signInWithKakao, loading } = useAuth()

const email = ref('')
const password = ref('')
const errorMessage = ref('')
const kakaoLoading = ref(false)

const redirectPath = computed(() => (typeof route.query.redirect === 'string' ? route.query.redirect : '/mypage'))

const handleSubmit = async () => {
  errorMessage.value = ''
  try {
    await signIn(email.value, password.value)
    await router.push(redirectPath.value)
  } catch (e) {
    errorMessage.value = '이메일 또는 비밀번호가 올바르지 않습니다.'
  }
}

const handleKakaoLogin = async () => {
  errorMessage.value = ''
  kakaoLoading.value = true
  try {
    await signInWithKakao(redirectPath.value)
  } catch (e) {
    errorMessage.value = '카카오 로그인에 실패했습니다.'
    kakaoLoading.value = false
  }
}
</script>

<template>
  <div class="card">
    <h1 class="mb-1 text-xl font-bold text-gray-900">로그인</h1>
    <p class="mb-6 text-sm text-gray-500">댕이를 부탁해 계정으로 로그인하세요.</p>

    <form class="space-y-4" @submit.prevent="handleSubmit">
      <div>
        <label class="label-field" for="email">이메일</label>
        <input id="email" v-model="email" type="email" required class="input-field" placeholder="you@example.com" />
      </div>
      <div>
        <label class="label-field" for="password">비밀번호</label>
        <input id="password" v-model="password" type="password" required class="input-field" placeholder="********" />
      </div>

      <p v-if="errorMessage" class="text-sm text-red-500">{{ errorMessage }}</p>

      <button type="submit" class="btn-primary w-full" :disabled="loading">
        {{ loading ? '로그인 중...' : '로그인' }}
      </button>
    </form>

    <div class="my-5 flex items-center gap-3">
      <div class="h-px flex-1 bg-gray-200" />
      <span class="text-xs text-gray-400">또는</span>
      <div class="h-px flex-1 bg-gray-200" />
    </div>

    <button
      type="button"
      class="flex w-full items-center justify-center gap-2 rounded-lg py-2.5 text-sm font-semibold"
      style="background-color: #fee500; color: #191919;"
      :disabled="kakaoLoading"
      @click="handleKakaoLogin"
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path
          d="M12 3.5C6.7 3.5 2.4 6.9 2.4 11.1c0 2.7 1.75 5.07 4.4 6.45-.19.71-1.03 3.55-1.06 3.78 0 0-.02.17.09.24.11.07.24.02.24.02.32-.04 3.71-2.43 4.3-2.85.53.08 1.08.12 1.63.12 5.3 0 9.6-3.4 9.6-7.6S17.3 3.5 12 3.5z"
          fill="#191919"
        />
      </svg>
      {{ kakaoLoading ? '이동 중...' : '카카오로 시작하기' }}
    </button>

    <p class="mt-6 text-center text-sm text-gray-500">
      아직 회원이 아니신가요?
      <NuxtLink to="/signup" class="font-semibold text-brand-600">회원가입</NuxtLink>
    </p>
  </div>
</template>
