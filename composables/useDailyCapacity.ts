import type { ReservationType } from '~/types/database.types'

export interface CapacityOverride {
  id: string
  date: string
  type: ReservationType
  max_capacity: number
}

export const useDailyCapacity = () => {
  const supabase = useSupabaseClient()

  // 오늘 이후의 날짜별 정원 예외 목록
  const fetchOverrides = async (): Promise<CapacityOverride[]> => {
    const today = new Date().toISOString().slice(0, 10)
    const { data, error } = await supabase
      .from('daily_capacity')
      .select('*')
      .gte('date', today)
      .order('date', { ascending: true })
    if (error) throw error
    return (data ?? []) as CapacityOverride[]
  }

  // 특정 날짜 정원 설정/변경 (date+type 유니크 → upsert)
  const setOverride = async (date: string, type: ReservationType, maxCapacity: number) => {
    const { error } = await supabase
      .from('daily_capacity')
      .upsert({ date, type, max_capacity: Math.max(0, Math.round(maxCapacity)) }, { onConflict: 'date,type' })
    if (error) throw error
  }

  const removeOverride = async (id: string) => {
    const { error } = await supabase.from('daily_capacity').delete().eq('id', id)
    if (error) throw error
  }

  return { fetchOverrides, setOverride, removeOverride }
}
