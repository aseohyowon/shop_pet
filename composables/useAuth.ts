import type { Profile } from '~/types/database.types'

export const useAuth = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const profile = useState<Profile | null>('auth-profile', () => null)
  const loading = useState<boolean>('auth-loading', () => false)

  const fetchProfile = async () => {
    if (!user.value) {
      profile.value = null
      return
    }
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.value.sub)
      .single()

    profile.value = error ? null : (data as Profile)
  }

  const signUp = async (params: {
    email: string
    password: string
    name: string
    phone: string
    postcode?: string
    address?: string
    addressDetail?: string
  }) => {
    loading.value = true
    try {
      const { error } = await supabase.auth.signUp({
        email: params.email,
        password: params.password,
        options: {
          data: {
            name: params.name,
            phone: params.phone,
            postcode: params.postcode ?? '',
            address: params.address ?? '',
            address_detail: params.addressDetail ?? ''
          }
        }
      })
      if (error) throw error
    } finally {
      loading.value = false
    }
  }

  const signIn = async (email: string, password: string) => {
    loading.value = true
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error
      await fetchProfile()
    } finally {
      loading.value = false
    }
  }

  const signInWithKakao = async (redirectPath = '/mypage') => {
    loading.value = true
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'kakao',
        options: {
          redirectTo: `${window.location.origin}/auth/callback?redirect=${encodeURIComponent(redirectPath)}`
        }
      })
      if (error) throw error
    } finally {
      loading.value = false
    }
  }

  const signOut = async () => {
    await supabase.auth.signOut()
    profile.value = null
  }

  watch(
    user,
    () => {
      fetchProfile()
    },
    { immediate: true }
  )

  const isAdmin = computed(() => profile.value?.role === 'admin')

  return { user, profile, loading, isAdmin, signUp, signIn, signInWithKakao, signOut, fetchProfile }
}
