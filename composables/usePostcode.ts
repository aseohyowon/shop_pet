// 다음(카카오) 우편번호 서비스 — 무료, API 키 불필요.
// 팝업 차단 이슈를 피하려고 embed(인라인) 방식을 쓴다.
const SCRIPT_SRC = 'https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js'

export interface PostcodeResult {
  zonecode: string // 우편번호
  address: string // 도로명(or 지번) + 참고항목
}

export const usePostcode = () => {
  const loadScript = () =>
    new Promise<void>((resolve, reject) => {
      const w = window as any
      if (w.daum?.Postcode) return resolve()

      const existing = document.querySelector<HTMLScriptElement>(`script[src="${SCRIPT_SRC}"]`)
      if (existing) {
        existing.addEventListener('load', () => resolve())
        existing.addEventListener('error', () => reject(new Error('주소 검색 서비스를 불러오지 못했습니다.')))
        return
      }

      const s = document.createElement('script')
      s.src = SCRIPT_SRC
      s.async = true
      s.onload = () => resolve()
      s.onerror = () => reject(new Error('주소 검색 서비스를 불러오지 못했습니다.'))
      document.head.appendChild(s)
    })

  const toResult = (data: any): PostcodeResult => {
    const base = data.userSelectedType === 'R' ? data.roadAddress : data.jibunAddress
    let extra = ''
    if (data.userSelectedType === 'R') {
      if (data.bname && /[동로가]$/.test(data.bname)) extra += data.bname
      if (data.buildingName && data.apartment === 'Y') {
        extra += (extra ? ', ' : '') + data.buildingName
      }
      if (extra) extra = ` (${extra})`
    }
    return { zonecode: data.zonecode, address: base + extra }
  }

  /** 컨테이너 엘리먼트 안에 검색 UI를 인라인으로 띄운다. 선택/닫기 시 콜백. */
  const embed = async (
    el: HTMLElement,
    onComplete: (result: PostcodeResult) => void,
    onClose?: () => void
  ) => {
    await loadScript()
    const w = window as any
    new w.daum.Postcode({
      width: '100%',
      height: '100%',
      oncomplete: (data: any) => onComplete(toResult(data)),
      onclose: (state: string) => {
        // state === 'FORCE_CLOSE' | 'COMPLETE_CLOSE'
        onClose?.()
      }
    }).embed(el, { autoClose: true })
  }

  return { embed }
}
