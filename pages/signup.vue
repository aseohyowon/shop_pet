<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const router = useRouter()
const { signUp, loading } = useAuth()

const name = ref('')
const email = ref('')
const phone = ref('')
const password = ref('')
const passwordConfirm = ref('')
const errorMessage = ref('')
const successMessage = ref('')

const handleSubmit = async () => {
  errorMessage.value = ''
  successMessage.value = ''

  if (password.value.length < 8) {
    errorMessage.value = '비밀번호는 8자 이상이어야 합니다.'
    return
  }
  if (password.value !== passwordConfirm.value) {
    errorMessage.value = '비밀번호가 일치하지 않습니다.'
    return
  }

  try {
    await signUp({ email: email.value, password: password.value, name: name.value, phone: phone.value })
    successMessage.value = '가입 확인 이메일을 보냈습니다. 메일함을 확인해주세요.'
    setTimeout(() => router.push('/login'), 1500)
  } catch (e: any) {
    if (e?.message === 'User already registered') {
      errorMessage.value = '이미 가입된 이메일입니다.'
    } else if (e?.status === 429 || /rate limit/i.test(e?.message ?? '')) {
      errorMessage.value = '이메일 발송 횟수 제한에 걸렸습니다. 잠시 후(약 1시간 뒤) 다시 시도해주세요.'
    } else {
      errorMessage.value = '가입에 실패했습니다. 잠시 후 다시 시도해주세요.'
    }
  }
}
</script>

<template>
  <div class="card">
    <h1 class="mb-1 text-xl font-bold text-gray-900">회원가입</h1>
    <p class="mb-6 text-sm text-gray-500">이메일로 간편하게 가입하세요.</p>

    <form class="space-y-4" @submit.prevent="handleSubmit">
      <div>
        <label class="label-field" for="name">이름</label>
        <input id="name" v-model="name" type="text" required class="input-field" placeholder="홍길동" />
      </div>
      <div>
        <label class="label-field" for="email">이메일</label>
        <input id="email" v-model="email" type="email" required class="input-field" placeholder="you@example.com" />
      </div>
      <div>
        <label class="label-field" for="phone">연락처</label>
        <input id="phone" v-model="phone" type="tel" required class="input-field" placeholder="010-0000-0000" />
      </div>
      <div>
        <label class="label-field" for="password">비밀번호</label>
        <input id="password" v-model="password" type="password" required class="input-field" placeholder="8자 이상" />
      </div>
      <div>
        <label class="label-field" for="password-confirm">비밀번호 확인</label>
        <input id="password-confirm" v-model="passwordConfirm" type="password" required class="input-field" placeholder="비밀번호 재입력" />
      </div>

      <p v-if="errorMessage" class="text-sm text-red-500">{{ errorMessage }}</p>
      <p v-if="successMessage" class="text-sm text-green-600">{{ successMessage }}</p>

      <button type="submit" class="btn-primary w-full" :disabled="loading">
        {{ loading ? '가입 처리 중...' : '가입하기' }}
      </button>
    </form>

    <p class="mt-6 text-center text-sm text-gray-500">
      이미 계정이 있으신가요?
      <NuxtLink to="/login" class="font-semibold text-brand-600">로그인</NuxtLink>
    </p>
  </div>
</template>
