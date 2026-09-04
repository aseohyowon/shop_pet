// 관리자가 1:1 문의 메뉴를 비활성화한 경우 관련 페이지 접근을 막는다.
export default defineNuxtRouteMiddleware(async () => {
  const { contactEnabled, loaded, load } = useSiteTheme()
  if (!loaded.value) await load()
  if (!contactEnabled.value) {
    return navigateTo('/', { replace: true })
  }
})
