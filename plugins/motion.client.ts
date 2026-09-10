import Lenis from 'lenis'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

/**
 * 부드러운 스크롤(Lenis) + GSAP ScrollTrigger 연동.
 * - 관리자(/admin)에서는 비활성
 * - prefers-reduced-motion 존중
 */
export default defineNuxtPlugin((nuxtApp) => {
  gsap.registerPlugin(ScrollTrigger)

  let lenis: Lenis | null = null
  let rafId: ((t: number) => void) | null = null

  const reduce = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches
  const isAdmin = () => window.location.pathname.startsWith('/admin')

  const start = () => {
    if (lenis || reduce() || isAdmin()) return
    lenis = new Lenis({
      duration: 1.1,
      easing: (t: number) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      smoothWheel: true,
      touchMultiplier: 1.6
    })
    lenis.on('scroll', ScrollTrigger.update)
    rafId = (time: number) => lenis?.raf(time * 1000)
    gsap.ticker.add(rafId)
    gsap.ticker.lagSmoothing(0)
    document.documentElement.classList.add('lenis-on')
  }

  const stop = () => {
    if (!lenis) return
    if (rafId) gsap.ticker.remove(rafId)
    lenis.destroy()
    lenis = null
    rafId = null
    document.documentElement.classList.remove('lenis-on')
  }

  onNuxtReady(() => {
    start()
    setTimeout(() => ScrollTrigger.refresh(), 400)
  })

  const router = useRouter()
  router.afterEach(() => {
    setTimeout(() => {
      window.scrollTo(0, 0)
      lenis?.scrollTo(0, { immediate: true })
      if (isAdmin()) stop()
      else start()
      ScrollTrigger.refresh()
    }, 120)
  })

  return {
    provide: {
      lenis: () => lenis,
      gsap: () => gsap,
      ScrollTrigger: () => ScrollTrigger
    }
  }
})
