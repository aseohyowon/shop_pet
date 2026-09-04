import type { VaccineStatus } from '~/types/database.types'

export const VACCINE_NOS = [1, 2, 3, 4, 5] as const

// 접종 상태 뱃지 문구: "회원확인 1" / "관리자확인 1" / "미접종"
export const vaccineLabel = (no: number, status: VaccineStatus | undefined | null) => {
  if (status === 'admin') return `관리자확인 ${no}`
  if (status === 'member') return `회원확인 ${no}`
  return '미접종'
}
