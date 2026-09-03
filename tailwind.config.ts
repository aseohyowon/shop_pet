import type { Config } from 'tailwindcss'

// "Warm Paw Prints" 디자인 토큰 (util/stitch_*/DESIGN.md 기준)
// 고객용 테마1/테마2에서 사용. 기존 brand(오렌지) 팔레트는 그대로 유지.
const warmColors = {
  background: '#fff8f5',
  'on-background': '#221a15',
  surface: '#fff8f5',
  'surface-dim': '#e7d7ce',
  'surface-bright': '#fff8f5',
  'surface-container-lowest': '#ffffff',
  'surface-container-low': '#fff1ea',
  'surface-container': '#fbebe2',
  'surface-container-high': '#f5e5dc',
  'surface-container-highest': '#efdfd7',
  'surface-variant': '#efdfd7',
  'surface-tint': '#78583a',
  'on-surface': '#221a15',
  'on-surface-variant': '#4f453c',
  'inverse-surface': '#382f29',
  'inverse-on-surface': '#feeee5',
  outline: '#81756b',
  'outline-variant': '#d3c4b9',
  primary: '#442a10',
  'on-primary': '#ffffff',
  'primary-container': '#5d4024',
  'on-primary-container': '#d5ac89',
  'inverse-primary': '#e9bf9a',
  'primary-fixed': '#ffdcbf',
  'primary-fixed-dim': '#e9bf9a',
  'on-primary-fixed': '#2c1601',
  'on-primary-fixed-variant': '#5e4125',
  secondary: '#864e5a',
  'on-secondary': '#ffffff',
  'secondary-container': '#feb6c4',
  'on-secondary-container': '#7a4450',
  'secondary-fixed': '#ffd9df',
  'secondary-fixed-dim': '#fbb3c1',
  'on-secondary-fixed': '#360c19',
  'on-secondary-fixed-variant': '#6b3743',
  tertiary: '#31302c',
  'on-tertiary': '#ffffff',
  'tertiary-container': '#474642',
  'on-tertiary-container': '#b7b4ae',
  'tertiary-fixed': '#e6e2dc',
  'tertiary-fixed-dim': '#c9c6c1',
  'on-tertiary-fixed': '#1c1c18',
  'on-tertiary-fixed-variant': '#484743',
  error: '#ba1a1a',
  'on-error': '#ffffff',
  'error-container': '#ffdad6',
  'on-error-container': '#93000a'
}

export default <Partial<Config>>{
  content: [
    './components/**/*.{vue,js,ts}',
    './layouts/**/*.vue',
    './pages/**/*.vue',
    './app.vue',
    './error.vue'
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#fff7ed',
          100: '#ffedd5',
          200: '#fed7aa',
          300: '#fdba74',
          400: '#fb923c',
          500: '#f97316',
          600: '#ea580c',
          700: '#c2410c',
          800: '#9a3412',
          900: '#7c2d12'
        },
        ...warmColors
      },
      fontFamily: {
        sans: ['"Pretendard"', 'system-ui', 'sans-serif'],
        'headline-xl': ['"Plus Jakarta Sans"', '"Pretendard"', 'sans-serif'],
        'headline-lg': ['"Plus Jakarta Sans"', '"Pretendard"', 'sans-serif'],
        'headline-lg-mobile': ['"Plus Jakarta Sans"', '"Pretendard"', 'sans-serif'],
        'headline-md': ['"Plus Jakarta Sans"', '"Pretendard"', 'sans-serif'],
        'body-lg': ['"Be Vietnam Pro"', '"Pretendard"', 'sans-serif'],
        'body-md': ['"Be Vietnam Pro"', '"Pretendard"', 'sans-serif'],
        'label-md': ['"Be Vietnam Pro"', '"Pretendard"', 'sans-serif'],
        'label-sm': ['"Be Vietnam Pro"', '"Pretendard"', 'sans-serif']
      },
      fontSize: {
        'headline-xl': ['48px', { lineHeight: '56px', letterSpacing: '-0.02em', fontWeight: '700' }],
        'headline-lg': ['32px', { lineHeight: '40px', letterSpacing: '-0.01em', fontWeight: '700' }],
        'headline-lg-mobile': ['28px', { lineHeight: '36px', fontWeight: '700' }],
        'headline-md': ['24px', { lineHeight: '32px', fontWeight: '600' }],
        'body-lg': ['18px', { lineHeight: '28px', fontWeight: '400' }],
        'body-md': ['16px', { lineHeight: '24px', fontWeight: '400' }],
        'label-md': ['14px', { lineHeight: '20px', fontWeight: '600' }],
        'label-sm': ['12px', { lineHeight: '16px', fontWeight: '500' }]
      },
      spacing: {
        base: '8px',
        gutter: '24px',
        'container-max': '1200px',
        'margin-mobile': '16px',
        'margin-desktop': '40px',
        'stack-sm': '8px',
        'stack-md': '16px',
        'stack-lg': '32px'
      },
      maxWidth: {
        'container-max': '1200px'
      },
      borderRadius: {
        xl: '0.75rem',
        '2xl': '1rem'
      }
    }
  },
  plugins: []
}
