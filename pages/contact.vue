<script setup lang="ts">
const { isWarm } = useSiteTheme()
const { createInquiry } = useInquiries()
const { profile, user } = useAuth()

const form = reactive({ name: '', phone: '', email: '', message: '' })
const submitting = ref(false)
const done = ref(false)
const errorMessage = ref('')

watchEffect(() => {
  if (!form.name && profile.value?.name) form.name = profile.value.name
  if (!form.phone && profile.value?.phone) form.phone = profile.value.phone
  if (!form.email && user.value?.email) form.email = user.value.email
})

const submit = async () => {
  errorMessage.value = ''
  if (!form.name.trim() || !form.message.trim()) {
    errorMessage.value = '이름과 문의 내용을 입력해주세요.'
    return
  }
  submitting.value = true
  try {
    await createInquiry({ name: form.name, phone: form.phone, email: form.email, message: form.message })
    done.value = true
  } catch (e: any) {
    errorMessage.value = e?.message ?? '문의 접수에 실패했습니다. 잠시 후 다시 시도해주세요.'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <!-- Warm -->
  <div v-if="isWarm" class="container-warm py-12">
    <h1 class="mb-2 font-headline-xl text-[32px] text-primary md:text-headline-xl">문의하기</h1>
    <p class="mb-8 font-body-lg text-body-lg text-on-surface-variant">궁금한 점을 남겨주시면 확인 후 연락드립니다.</p>

    <div v-if="done" class="card-warm max-w-lg text-center">
      <p class="mb-2 font-headline-md text-headline-md text-primary">문의가 접수되었습니다</p>
      <p class="font-body-md text-on-surface-variant">빠른 시일 내에 답변드리겠습니다.</p>
      <div class="mt-6 flex justify-center gap-3">
        <NuxtLink v-if="user" to="/mypage/inquiries" class="btn-warm">내 문의 내역 보기</NuxtLink>
        <NuxtLink to="/" class="btn-warm-soft">홈으로</NuxtLink>
      </div>
      <p v-if="!user" class="mt-3 font-label-sm text-label-sm text-on-surface-variant">
        로그인하시면 마이페이지에서 답변을 확인할 수 있습니다.
      </p>
    </div>

    <form v-else class="card-warm max-w-lg space-y-4" @submit.prevent="submit">
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label class="label-warm" for="c-name">이름</label>
          <input id="c-name" v-model="form.name" type="text" class="input-warm" placeholder="홍길동" />
        </div>
        <div>
          <label class="label-warm" for="c-phone">연락처</label>
          <input id="c-phone" v-model="form.phone" type="tel" class="input-warm" placeholder="010-0000-0000" />
        </div>
      </div>
      <div>
        <label class="label-warm" for="c-email">이메일</label>
        <input id="c-email" v-model="form.email" type="email" class="input-warm" placeholder="you@example.com" />
      </div>
      <div>
        <label class="label-warm" for="c-msg">문의 내용</label>
        <textarea id="c-msg" v-model="form.message" rows="5" class="input-warm resize-none" placeholder="문의하실 내용을 입력해주세요" />
      </div>
      <p v-if="errorMessage" class="font-body-md text-sm text-error">{{ errorMessage }}</p>
      <button type="submit" class="btn-warm w-full" :disabled="submitting">
        {{ submitting ? '접수 중...' : '문의 보내기' }}
      </button>
    </form>
  </div>

  <!-- 기본 -->
  <div v-else class="container-page max-w-lg py-16">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">문의하기</h1>
    <p class="mb-8 text-gray-500">궁금한 점을 남겨주시면 확인 후 연락드립니다.</p>

    <div v-if="done" class="card text-center">
      <p class="mb-2 text-lg font-bold text-gray-900">문의가 접수되었습니다</p>
      <p class="text-gray-500">빠른 시일 내에 답변드리겠습니다.</p>
      <div class="mt-6 flex justify-center gap-3">
        <NuxtLink v-if="user" to="/mypage/inquiries" class="btn-primary">내 문의 내역 보기</NuxtLink>
        <NuxtLink to="/" class="btn-secondary">홈으로</NuxtLink>
      </div>
      <p v-if="!user" class="mt-3 text-xs text-gray-400">로그인하시면 마이페이지에서 답변을 확인할 수 있습니다.</p>
    </div>

    <form v-else class="space-y-4" @submit.prevent="submit">
      <div>
        <label class="label-field" for="c2-name">이름</label>
        <input id="c2-name" v-model="form.name" type="text" class="input-field" placeholder="홍길동" />
      </div>
      <div>
        <label class="label-field" for="c2-phone">연락처</label>
        <input id="c2-phone" v-model="form.phone" type="tel" class="input-field" placeholder="010-0000-0000" />
      </div>
      <div>
        <label class="label-field" for="c2-email">이메일</label>
        <input id="c2-email" v-model="form.email" type="email" class="input-field" placeholder="you@example.com" />
      </div>
      <div>
        <label class="label-field" for="c2-message">문의 내용</label>
        <textarea id="c2-message" v-model="form.message" rows="4" class="input-field" placeholder="문의하실 내용을 입력해주세요" />
      </div>
      <p v-if="errorMessage" class="text-sm text-red-500">{{ errorMessage }}</p>
      <button type="submit" class="btn-primary w-full" :disabled="submitting">
        {{ submitting ? '접수 중...' : '문의 보내기' }}
      </button>
    </form>
  </div>
</template>
