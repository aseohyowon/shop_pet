import type { ReservationType } from '~/types/database.types'

export interface ServiceSetting {
  type: ReservationType
  default_capacity: number
  price: number
  deposit_rate: number
}

export const useServiceSettings = () => {
  const supabase = useSupabaseClient()

  // 누구나 읽기 가능 (예약 화면에서 예상 금액 표시용)
  const fetchServiceSettings = async (): Promise<Record<ReservationType, ServiceSetting>> => {
    const { data, error } = await supabase.from('service_settings').select('*')
    if (error) throw error
    const map = {} as Record<ReservationType, ServiceSetting>
    for (const row of (data ?? []) as ServiceSetting[]) map[row.type] = row
    return map
  }

  // 관리자 전용
  const updateServiceSetting = async (
    type: ReservationType,
    patch: Partial<Pick<ServiceSetting, 'default_capacity' | 'price' | 'deposit_rate'>>
  ) => {
    const { error } = await supabase.from('service_settings').update(patch).eq('type', type)
    if (error) throw error
  }

  // 호텔 박 수 (종료일 - 시작일, 최소 1)
  const nights = (startDate: string, endDate: string) => {
    const d = (Date.parse(endDate) - Date.parse(startDate)) / 86400000
    return Math.max(1, Math.round(d))
  }

  return { fetchServiceSettings, updateServiceSetting, nights }
}
