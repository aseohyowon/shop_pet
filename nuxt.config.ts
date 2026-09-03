// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },

  modules: ['@nuxtjs/tailwindcss', '@nuxtjs/supabase'],

  // Cloudflare Workers 배포용 (wrangler.jsonc + .output/server/index.mjs)
  nitro: {
    preset: 'cloudflare_module'
  },

  css: ['~/assets/css/main.css'],

  supabase: {
    url: process.env.SUPABASE_URL,
    key: process.env.SUPABASE_ANON_KEY,
    // 고객용(/mypage)과 관리자용(/admin) 로그인 페이지가 분리되어 있어
    // 모듈의 자동 리다이렉트 대신 middleware/auth.ts, middleware/admin.ts에서 직접 처리한다.
    redirect: false,
    types: '~/types/database.types.ts'
  },

  app: {
    head: {
      title: '댕이를 부탁해 — 애견호텔 & 데이케어',
      meta: [
        { name: 'description', content: '반려동물 호텔/데이케어 예약과 용품 쇼핑을 한 곳에서, 댕이를 부탁해.' }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@500;600;700&display=swap'
        },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap'
        }
      ]
    }
  },

  typescript: {
    strict: true
  },

  runtimeConfig: {
    tossSecretKey: process.env.TOSS_SECRET_KEY,
    public: {
      tossClientKey: process.env.TOSS_CLIENT_KEY
    }
  }
})
