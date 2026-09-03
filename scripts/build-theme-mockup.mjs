// util/stitch_*/code.html 5개를 하나의 발표용 목업 HTML로 합친다.
import { readFileSync, writeFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const screens = [
  { dir: 'stitch_',      id: 'main1',  label: '메인 화면 · 테마 1', url: 'daengyi.co.kr' },
  { dir: 'stitch_ (4)',  id: 'main2',  label: '메인 화면 · 테마 2', url: 'daengyi.co.kr' },
  { dir: 'stitch_ (5)',  id: 'reserve', label: '예약하기',          url: 'daengyi.co.kr/reservation' },
  { dir: 'stitch_ (2)',  id: 'shop',   label: '쇼핑몰',             url: 'daengyi.co.kr/shop' },
  { dir: 'stitch_ (3)',  id: 'mypage', label: '마이페이지',         url: 'daengyi.co.kr/mypage' }
]

// stitch_ (메인화면1)는 원본이 영문 About 페이지라, 발표용으로 한글 카피로 교체
const KO = [
  ['A Safe Haven for Your <br class="hidden md:block">Furriest Family Members.', '우리 아이를 위한 <br class="hidden md:block">가장 안전한 두 번째 집'],
  ['Our Story', '우리 이야기'],
  ["We believe every pet deserves a space that feels like home, filled with love, safety, and professional care. We're more than a pet hotel; we're your partner in pet parenthood.", '모든 반려동물이 집처럼 편안한 공간에서 사랑과 안전, 전문적인 케어를 받을 자격이 있다고 믿습니다. 댕이를 부탁해는 단순한 애견호텔이 아니라, 반려생활의 든든한 파트너입니다.'],
  ['Premium Environment', '프리미엄 환경'],
  ['Designed specifically to reduce stress and maximize comfort for dogs of all sizes and temperaments.', '모든 크기와 성향의 반려견이 스트레스 없이 편안하게 지낼 수 있도록 설계된 공간입니다.'],
  ['Virtual Tour', '시설 둘러보기'],
  ['Indoor Play Area', '실내 놀이 공간'],
  ['Climate-Controlled Playrooms', '냉난방 완비 실내 놀이방'],
  ['Our expansive indoor areas maintain perfect temperatures year-round, ensuring comfortable play regardless of the weather outside.', '넓은 실내 공간은 연중 쾌적한 온도를 유지해 날씨와 상관없이 편안한 놀이가 가능합니다.'],
  ['24/7 Care', '24시간 케어'],
  ['Veterinarian on-call and staff present around the clock.', '수의사 온콜 대기, 24시간 상주 케어 인력.'],
  ['Luxury Suites', '럭셔리 스위트'],
  ['Outdoor Parks', '야외 놀이터'],
  ['Meet The Caregivers', '케어 전문가 소개'],
  ['Certified trainers, experienced vet techs, and passionate pet lovers dedicated to your furry family.', '자격을 갖춘 훈련사, 숙련된 수의 테크니션, 반려동물을 사랑하는 전문 케어 인력이 함께합니다.'],
  ['Lead Behaviorist', '수석 행동전문가'],
  ['Certified in canine behavior modification with 10 years of experience.', '반려견 행동 교정 자격 보유, 10년 경력.'],
  ['Senior Caretaker', '시니어 케어테이커'],
  ['Former vet tech who ensures all medical and dietary needs are perfectly met.', '수의 테크니션 출신으로 건강·식이 관리를 꼼꼼히 챙깁니다.'],
  ['Enrichment Specialist', '놀이 프로그램 전문가'],
  ['Designs personalized play sessions to keep pups mentally stimulated.', '아이별 맞춤 놀이 세션을 설계해 두뇌 자극을 돕습니다.'],
  ['Join Our Pack', '함께할 분을 찾습니다'],
  ['We are always looking for passionate pet professionals.', '반려동물을 사랑하는 전문가를 언제나 환영합니다.'],
  ['Find Us Here', '오시는 길'],
  ['Address', '주소'],
  ['123 Pet Haven Lane, Gangnam-gu<br>Seoul, South Korea 06000', '서울특별시 ○○구 ○○로 123<br>댕이를 부탁해'],
  ['Phone', '전화'],
  ['02-555-DOGS (3647)', '02-000-0000'],
  ['Hours', '운영 시간'],
  ['Mon - Fri: 7:00 AM - 8:00 PM<br>Weekends: 8:00 AM - 6:00 PM', '매일 09:00 - 19:00 (연중무휴)'],
  ['Connect With Us', '소셜 채널'],
  ['Privacy Policy', '개인정보처리방침'],
  ['Terms of Service', '이용약관'],
  ['Customer Support', '고객센터'],
  ['Company', '회사'],
  ['Support', '고객지원'],
  ['Newsletter', '뉴스레터'],
  ['Enter email', '이메일 입력'],
  ['© 2024 댕이를 부탁해. All rights reserved.', '© 2026 댕이를 부탁해. All rights reserved.'],
  ['CPDT-KA', '행동교정 자격'],
  ['Pet CPR Certified', '반려동물 CPR'],
  ['Agility Expert', '어질리티 전문']
]

const bodyOf = (html, koreanize = false) => {
  const m = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i)
  let inner = m ? m[1] : html
  inner = inner.replace(/<script[\s\S]*?<\/script>/gi, '')
  if (koreanize) for (const [en, ko] of KO) inner = inner.split(en).join(ko)
  return inner.trim()
}

// 5개가 동일한 Warm Paw Prints 토큰을 쓰므로 config는 stitch_ 것 하나만 사용
const tailwindConfig = readFileSync(resolve(root, 'util', 'stitch_', 'code.html'), 'utf8')
  .match(/<script id="tailwind-config">([\s\S]*?)<\/script>/)[1]

const sections = screens
  .map((s) => {
    const html = readFileSync(resolve(root, 'util', s.dir, 'code.html'), 'utf8')
    const inner = bodyOf(html, s.id === 'main1')
    return `
  <section id="screen-${s.id}" class="screen">
    <p class="caption">${s.label}</p>
    <div class="window">
      <div class="chrome">
        <span class="dot" style="background:#f87171"></span>
        <span class="dot" style="background:#fbbf24"></span>
        <span class="dot" style="background:#34d399"></span>
        <span class="url">${s.url}</span>
      </div>
      <div class="frame">
        <div class="frame-inner">
${inner}
        </div>
      </div>
    </div>
  </section>`
  })
  .join('\n')

const tabs = screens
  .map((s) => `<a href="#screen-${s.id}">${s.label.replace(' · ', ' ')}</a>`)
  .join('')

const out = `<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>댕이를 부탁해 — 새 디자인 테마 미리보기</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<script id="tailwind-config">${tailwindConfig}</script>
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;600;700&family=Plus+Jakarta+Sans:wght@500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap" rel="stylesheet">
<style>
  *{box-sizing:border-box}
  body{margin:0;background:#efe4dc;color:#221a15;font-family:"Be Vietnam Pro","Malgun Gothic","Apple SD Gothic Neo","Segoe UI",sans-serif}
  .material-symbols-outlined{font-family:"Material Symbols Outlined";font-weight:normal;font-style:normal;line-height:1;letter-spacing:normal;text-transform:none;display:inline-block;white-space:nowrap;direction:ltr;font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 24}
  .tabbar{position:sticky;top:0;z-index:100;background:rgba(68,42,16,.96);backdrop-filter:blur(6px);display:flex;flex-wrap:wrap;gap:4px;padding:10px 16px;justify-content:center}
  .tabbar a{color:#e9bf9a;font-size:13px;font-weight:600;text-decoration:none;padding:7px 14px;border-radius:999px;transition:.15s}
  .tabbar a:hover{background:rgba(255,255,255,.12);color:#fff}
  .wrap{max-width:1320px;margin:0 auto;padding:44px 20px 120px}
  .intro{text-align:center;margin-bottom:52px}
  .intro h1{margin:0 0 8px;font-family:"Plus Jakarta Sans",sans-serif;font-size:30px;font-weight:700;color:#442a10}
  .intro p{margin:0;font-size:14px;color:#6b5d52}
  .intro .badge{display:inline-block;margin-bottom:14px;background:#feb6c4;color:#7a4450;font-size:12px;font-weight:600;padding:5px 14px;border-radius:999px;letter-spacing:.02em}
  .screen{margin-bottom:64px;scroll-margin-top:70px}
  .caption{font-family:"Plus Jakarta Sans",sans-serif;font-size:13px;font-weight:700;color:#864e5a;margin:0 0 10px;letter-spacing:.03em}
  .window{border-radius:14px;overflow:hidden;box-shadow:0 12px 40px rgba(68,42,16,.14);background:#fff}
  .chrome{background:#e7d7ce;padding:10px 14px;display:flex;align-items:center;gap:8px}
  .dot{width:10px;height:10px;border-radius:50%}
  .url{margin-left:8px;background:#fff8f5;border-radius:6px;padding:4px 12px;font-size:12px;color:#6b5d52;flex:1}
  .frame{height:760px;overflow-y:auto;overflow-x:hidden;background:#fff8f5}
  .frame-inner{min-width:1024px}
  .frame-inner header,.frame-inner nav.bg-surface,.frame-inner nav.bg-background{position:static !important}
  .outro{text-align:center;color:#6b5d52;font-size:13px;padding-top:8px}
  @media(max-width:900px){.frame{height:620px}}
</style>
</head>
<body>
<nav class="tabbar">${tabs}</nav>
<div class="wrap">
  <div class="intro">
    <span class="badge">DESIGN PREVIEW</span>
    <h1>댕이를 부탁해 — 새 디자인 테마</h1>
    <p>관리자 페이지에서 &lsquo;테마 1 / 테마 2&rsquo;로 전환 가능한 새 화면 시안입니다. (Warm Paw Prints)</p>
  </div>
${sections}
  <p class="outro">© ${new Date().getFullYear()} 댕이를 부탁해 · 내부 검토용 목업</p>
</div>
</body>
</html>`

writeFileSync(resolve(root, 'daengyi-theme-mockup.html'), out, 'utf8')
console.log('daengyi-theme-mockup.html 생성 완료 (' + (out.length / 1024).toFixed(0) + ' KB)')
