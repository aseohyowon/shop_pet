import type { PointTransaction } from '~/types/database.types'

export const POINT_REASON_LABEL: Record<PointTransaction['reason'], string> = {
  signup: '회원가입 지급',
  earn: '구매 적립',
  use: '결제 사용',
  cancel: '취소 정산',
  admin: '관리자 조정'
}

export const usePoints = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  // 내 포인트 잔액
  const fetchMyBalance = async (): Promise<number> => {
    if (!user.value) return 0
    const { data, error } = await supabase
      .from('profiles')
      .select('points')
      .eq('id', user.value.sub)
      .single()
    if (error) throw error
    return (data as { points: number })?.points ?? 0
  }

  // 내 포인트 적립/사용 내역
  const fetchMyHistory = async (): Promise<PointTransaction[]> => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('point_transactions')
      .select('*')
      .eq('user_id', user.value.sub)
      .order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as PointTransaction[]
  }

  // 관리자: 특정 회원 포인트 수동 지급(양수)/차감(음수)
  const adminAdjust = async (userId: string, amount: number, memo?: string): Promise<number> => {
    const { data, error } = await supabase.rpc('admin_adjust_points', {
      p_user: userId,
      p_amount: Math.trunc(amount),
      p_memo: memo || null
    })
    if (error) throw error
    return data as number
  }

  return { fetchMyBalance, fetchMyHistory, adminAdjust }
}
