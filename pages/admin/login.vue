<script setup lang="ts">
import type { Profile } from '~/types/database.types'

definePageMeta({ layout: 'auth' })

const router = useRouter()
const supabase = useSupabaseClient()

const email = ref('')
const password = ref('')
const errorMessage = ref('')
const loading = ref(false)

const handleSubmit = async () => {
  errorMessage.value = ''
  loading.value = true
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.value,
      password: password.value
    })
    if (error) throw error

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', data.user.id)
      .single()

    if ((profile as Pick<Profile, 'role'> | null)?.role !== 'admin') {
      await supabase.auth.signOut()
      errorMessage.value = '관리자 계정이 아닙니다.'
      return
    }

    await router.push('/admin')
  } catch (e) {
    errorMessage.value = '이메일 또는 비밀번호가 올바르지 않습니다.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="card-warm">
    <div class="mb-6 flex items-center gap-2 font-headline-md text-lg font-bold text-primary">
      <span class="material-symbols-outlined icon-filled text-secondary">pets</span>
      <span>댕이를 부탁해 <span class="font-label-sm text-label-sm text-on-surface-variant">Admin</span></span>
    </div>
    <h1 class="mb-1 font-headline-md text-headline-md text-on-surface">관리자 로그인</h1>
    <p class="mb-6 font-body-md text-sm text-on-surface-variant">관리자 계정으로 로그인하세요. (고객 로그인과 별도 계정)</p>

    <form class="space-y-4" @submit.prevent="handleSubmit">
      <div>
        <label class="label-warm" for="admin-email">이메일</label>
        <input id="admin-email" v-model="email" type="email" required class="input-warm" placeholder="admin@daengyi.example" />
      </div>
      <div>
        <label class="label-warm" for="admin-password">비밀번호</label>
        <input id="admin-password" v-model="password" type="password" required class="input-warm" placeholder="********" />
      </div>

      <p v-if="errorMessage" class="font-body-md text-sm text-error">{{ errorMessage }}</p>

      <button type="submit" class="btn-warm w-full" :disabled="loading">
        {{ loading ? '로그인 중...' : '로그인' }}
      </button>
    </form>
  </div>
</template>
