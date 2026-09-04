<script setup lang="ts">
definePageMeta({ layout: 'auth' })

const router = useRouter()
const { signUp, loading } = useAuth()
const { embed: embedPostcode } = usePostcode()

const name = ref('')
const email = ref('')
const phone = ref('')
const password = ref('')
const passwordConfirm = ref('')
const postcode = ref('')
const address = ref('')
const addressDetail = ref('')
const errorMessage = ref('')
const successMessage = ref('')

const addressDetailRef = ref<HTMLInputElement | null>(null)
const postcodeBox = ref<HTMLElement | null>(null)
const showPostcode = ref(false)

const findAddress = async () => {
  errorMessage.value = ''
  showPostcode.value = true
  await nextTick()
  if (!postcodeBox.value) return
  try {
    await embedPostcode(
      postcodeBox.value,
      ({ zonecode, address: addr }) => {
        postcode.value = zonecode
        address.value = addr
        showPostcode.value = false
        nextTick(() => addressDetailRef.value?.focus())
      },
      () => {
        showPostcode.value = false
      }
    )
  } catch (e: any) {
    showPostcode.value = false
    errorMessage.value = e?.message ?? '주소 검색에 실패했습니다.'
  }
}

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
    await signUp({
      email: email.value,
      password: password.value,
      name: name.value,
      phone: phone.value,
      postcode: postcode.value,
      address: address.value,
      addressDetail: addressDetail.value
    })
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
        <label class="label-field" for="postcode">주소</label>
        <div class="flex gap-2">
          <input
            id="postcode"
            v-model="postcode"
            type="text"
            readonly
            class="input-field !w-32 bg-gray-50"
            placeholder="우편번호"
          />
          <button
            type="button"
            class="shrink-0 rounded-lg border border-gray-300 px-4 text-sm font-medium text-gray-600 hover:border-brand-300 hover:text-brand-600"
            @click="findAddress"
          >
            주소 검색
          </button>
        </div>
        <div
          v-show="showPostcode"
          ref="postcodeBox"
          class="mt-2 h-[420px] w-full overflow-hidden rounded-lg border border-gray-200"
        />
        <input
          v-model="address"
          type="text"
          readonly
          class="input-field mt-2 bg-gray-50"
          placeholder="기본 주소"
        />
        <input
          ref="addressDetailRef"
          v-model="addressDetail"
          type="text"
          class="input-field mt-2"
          placeholder="상세 주소 (동/호수 등)"
        />
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
