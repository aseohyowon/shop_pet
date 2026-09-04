import type { SiteTheme, HomeVariant } from '~/types/database.types'

/**
 * 고객용 화면 테마 상태.
 * 관리자가 /admin/settings 에서 저장한 값(site_settings 테이블)을 읽어
 * 모든 방문자에게 동일하게 적용한다. (SSR에서 1회 로드 → 클라이언트로 전달)
 */
export const useSiteTheme = () => {
  const siteTheme = useState<SiteTheme>('site-theme', () => 'default')
  const homeVariant = useState<HomeVariant>('home-variant', () => 'auto')
  // 1:1 문의 메뉴 노출 여부 (관리자가 /admin/settings 에서 on/off). 기본 off.
  const contactEnabled = useState<boolean>('contact-enabled', () => false)
  const loaded = useState<boolean>('site-theme-loaded', () => false)

  const supabase = useSupabaseClient()

  const load = async () => {
    try {
      const { data } = await supabase.from('site_settings').select('key, value')
      for (const row of (data ?? []) as { key: string; value: string }[]) {
        if (row.key === 'site_theme') siteTheme.value = row.value as SiteTheme
        if (row.key === 'home_variant') homeVariant.value = row.value as HomeVariant
        if (row.key === 'contact_enabled') contactEnabled.value = row.value === 'on'
      }
    } catch {
      // site_settings 테이블이 아직 없으면 기본(default) 테마 유지
    }
    loaded.value = true
  }

  // 헤더/푸터/예약/쇼핑몰/마이페이지에 Warm 스킨 적용 여부
  const isWarm = computed(() => siteTheme.value !== 'default')

  // 실제로 렌더링할 홈 화면
  const resolvedHome = computed<'classic' | 'main1' | 'main2'>(() => {
    if (homeVariant.value === 'main1') return 'main1'
    if (homeVariant.value === 'main2') return 'main2'
    if (siteTheme.value === 'theme1') return 'main1'
    if (siteTheme.value === 'theme2') return 'main2'
    return 'classic'
  })

  const updateSetting = async (
    key: 'site_theme' | 'home_variant' | 'contact_enabled',
    value: string
  ) => {
    const { error } = await supabase.from('site_settings').upsert({ key, value }, { onConflict: 'key' })
    if (error) throw error
    if (key === 'site_theme') siteTheme.value = value as SiteTheme
    if (key === 'home_variant') homeVariant.value = value as HomeVariant
    if (key === 'contact_enabled') contactEnabled.value = value === 'on'
  }

  return { siteTheme, homeVariant, contactEnabled, loaded, isWarm, resolvedHome, load, updateSetting }
}
