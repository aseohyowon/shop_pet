import type { ReservationType } from '~/types/database.types'

export interface ServiceSetting {
  type: ReservationType
  default_capacity: number
  price: number // 호텔=1박, 데이케어=종일 요금
  hourly_price?: number // 데이케어 시간제(1시간) 요금
  deposit_rate: number
}

export const useServiceSettings = () => {
  const supabase = useSupabaseClient()

  // 누구나 읽기 가능 (예약 화면에서 예상 금액 표시용)
  // price 는 pricing_items(billing_key)에서 가져와 덮어씀 → 가격은 요금표가 단일 출처
  const fetchServiceSettings = async (): Promise<Record<ReservationType, ServiceSetting>> => {
    const [{ data, error }, { data: pricing }] = await Promise.all([
      supabase.from('service_settings').select('*'),
      supabase
        .from('pricing_items')
        .select('billing_key, price')
        .in('billing_key', ['hotel_night', 'daycare_day', 'daycare_hourly'])
    ])
    if (error) throw error
    const byKey: Record<string, number> = {}
    for (const row of (pricing ?? []) as { billing_key: string; price: number }[]) byKey[row.billing_key] = row.price
    const map = {} as Record<ReservationType, ServiceSetting>
    for (const row of (data ?? []) as ServiceSetting[]) {
      map[row.type] = {
        ...row,
        price: row.type === 'hotel' ? (byKey.hotel_night ?? row.price) : (byKey.daycare_day ?? row.price),
        hourly_price: row.type === 'daycare' ? (byKey.daycare_hourly ?? 4000) : undefined
      }
    }
    return map
  }

  // 관리자 전용 — 정원/예약금 비율만. 요금(price)은 usePricing().updateBasePrice 로.
  const updateServiceSetting = async (
    type: ReservationType,
    patch: Partial<Pick<ServiceSetting, 'default_capacity' | 'deposit_rate'>>
  ) => {
    const { error } = await supabase.from('service_settings').update(patch).eq('type', type)
    if (error) throw error
  }

  // 호텔 박 수 (종료일 - 시작일, 최소 1)
  const nights = (startDate: string, endDate: string) => {
    const d = (Date.parse(endDate) - Date.parse(startDate)) / 86400000
    return Math.max(1, Math.round(d))
  }

  // 이용 시간(올림, 최소 1) — 데이케어 시간제 계산용. "HH:MM"
  const hoursBetween = (startTime: string, endTime: string) => {
    const [sh, sm] = startTime.split(':').map(Number)
    const [eh, em] = endTime.split(':').map(Number)
    const mins = eh * 60 + em - (sh * 60 + sm)
    return Math.max(1, Math.ceil(mins / 60))
  }

  return { fetchServiceSettings, updateServiceSetting, nights, hoursBetween }
}
