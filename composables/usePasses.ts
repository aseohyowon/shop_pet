import type { DaycarePass, DaycarePassUsage, PricingItem } from '~/types/database.types'

export interface PassWithRemaining extends DaycarePass {
  remaining: number
}

const withRemaining = (rows: DaycarePass[]): PassWithRemaining[] =>
  rows.map((p) => ({ ...p, remaining: Math.max(0, p.total_count - p.used_count) }))

export const usePasses = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  // 구매 가능한 정기권 상품 (요금표의 daycare_pass)
  const fetchPassProducts = async (): Promise<PricingItem[]> => {
    const { data, error } = await supabase
      .from('pricing_items')
      .select('*')
      .eq('category', 'daycare_pass')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
    if (error) throw error
    return (data ?? []) as PricingItem[]
  }

  // 내 정기권 (활성 + 대기)
  const fetchMyPasses = async (): Promise<PassWithRemaining[]> => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('daycare_passes')
      .select('*')
      .eq('user_id', user.value.sub)
      .in('status', ['active', 'pending'])
      .order('created_at', { ascending: false })
    if (error) throw error
    return withRemaining((data ?? []) as DaycarePass[])
  }

  // 종일 데이케어에 사용 가능한 정기권 (활성 + 잔여 있음)
  const fetchUsablePasses = async (): Promise<PassWithRemaining[]> => {
    const all = await fetchMyPasses()
    return all.filter((p) => p.status === 'active' && p.remaining > 0)
  }

  const fetchMyUsages = async (): Promise<(DaycarePassUsage & { daycare_passes: { name: string } })[]> => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('daycare_pass_usages')
      .select('*, daycare_passes!inner(name, user_id)')
      .eq('daycare_passes.user_id', user.value.sub)
      .order('used_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as any
  }

  const redeemPass = async (reservationId: string, passId: string) => {
    const { data, error } = await supabase.rpc('redeem_pass_for_reservation', {
      p_reservation_id: reservationId,
      p_pass_id: passId
    })
    if (error) throw error
    return data
  }

  // ── 관리자 ──
  const fetchCustomerPasses = async (userId: string): Promise<PassWithRemaining[]> => {
    const { data, error } = await supabase
      .from('daycare_passes')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
    if (error) throw error
    return withRemaining((data ?? []) as DaycarePass[])
  }

  const grantPass = async (userId: string, pricingItemId: string, memo?: string) => {
    const { data, error } = await supabase.rpc('admin_grant_pass', {
      p_user: userId,
      p_pricing_item_id: pricingItemId,
      p_memo: memo || null
    })
    if (error) throw error
    return data
  }

  const voidPass = async (passId: string) => {
    const { error } = await supabase.rpc('admin_void_pass', { p_pass_id: passId })
    if (error) throw error
  }

  return {
    fetchPassProducts,
    fetchMyPasses,
    fetchUsablePasses,
    fetchMyUsages,
    redeemPass,
    fetchCustomerPasses,
    grantPass,
    voidPass
  }
}
