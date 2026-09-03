// 택배사 목록 — code는 tracker.delivery 조회 링크에 사용
export const COURIERS: { code: string; label: string }[] = [
  { code: 'kr.cjlogistics', label: 'CJ대한통운' },
  { code: 'kr.epost', label: '우체국택배' },
  { code: 'kr.hanjin', label: '한진택배' },
  { code: 'kr.lotte', label: '롯데택배' },
  { code: 'kr.logen', label: '로젠택배' },
  { code: 'kr.kdexp', label: '경동택배' },
  { code: 'kr.daesin', label: '대신택배' },
  { code: 'kr.cupost', label: 'CU 편의점택배' },
  { code: 'kr.cvsnet', label: 'GS Postbox 택배' },
  { code: 'kr.chunilps', label: '천일택배' },
  { code: 'kr.honamlogis', label: '한의사랑택배' }
]

export const courierLabel = (code: string | null | undefined) =>
  COURIERS.find((c) => c.code === code)?.label ?? code ?? ''

// 고객 배송조회 링크
export const trackingUrl = (courierCode: string | null | undefined, trackingNumber: string | null | undefined) => {
  if (!trackingNumber) return ''
  const num = String(trackingNumber).replace(/[^0-9]/g, '')
  if (courierCode) return `https://tracker.delivery/#/${courierCode}/${num}`
  // 택배사 코드가 없으면 통합 검색으로 폴백
  return `https://search.naver.com/search.naver?query=${encodeURIComponent(`${trackingNumber} 택배조회`)}`
}
