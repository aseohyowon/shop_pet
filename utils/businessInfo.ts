// 사업자 정보 단일 출처. 값이 바뀌면 여기만 고치면 사이트 전체(푸터·홈·약관)에 반영된다.
export const BUSINESS_INFO = {
  name: '댕이를 부탁해',
  owner: '신경아', // 대표자
  address: '경기도 수원시 영통구 법조로 25, SK뷰레이크 B120호',
  hours: '매일 09:00 - 19:00',
  phone: '', // 대표전화 (미정 — 확정되면 입력)
  email: '', // 고객문의 이메일 (미정)

  // 사업자등록 완료 후 입력 (토스 가맹점 심사 시 표시 필요)
  bizRegNo: '', // 사업자등록번호
  onlineSalesNo: '', // 통신판매업 신고번호

  // 지도용 검색어
  mapQuery: '경기도 수원시 영통구 법조로 25 SK뷰레이크'
} as const

const enc = encodeURIComponent

// 키 없이 임베드 가능한 구글 지도 (한국 지도 데이터 정상 표시)
export const mapEmbedSrc = (q: string = BUSINESS_INFO.mapQuery) =>
  `https://maps.google.com/maps?q=${enc(q)}&z=17&hl=ko&output=embed`

// 외부 지도앱 바로가기
export const kakaoMapLink = (q: string = BUSINESS_INFO.address) =>
  `https://map.kakao.com/link/search/${enc(q)}`
export const naverMapLink = (q: string = BUSINESS_INFO.address) =>
  `https://map.naver.com/p/search/${enc(q)}`
