import type { Profile } from '~/types/database.types'

// 관리자 로그인 + role='admin' 확인이 필요한 페이지(/admin/**, 로그인 페이지 자체는 제외)에 적용
export default defineNuxtRouteMiddleware(async () => {
  const user = useSupabaseUser()

  if (!user.value) {
    return navigateTo('/admin/login')
  }

  const supabase = useSupabaseClient()
  const { data } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.value.sub)
    .single()

  if ((data as Pick<Profile, 'role'> | null)?.role !== 'admin') {
    return navigateTo('/admin/login')
  }
})
