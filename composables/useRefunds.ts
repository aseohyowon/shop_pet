import type { RefundTier } from '~/types/database.types'

export const useRefunds = () => {
  const supabase = useSupabaseClient()

  const fetchRefundTiers = async (): Promise<RefundTier[]> => {
    const { data, error } = await supabase
      .from('refund_policy_tiers')
      .select('*')
      .order('days_before', { ascending: false })
    if (error) throw error
    return (data ?? []) as RefundTier[]
  }

  // 관리자: 환불 규정 전체 교체
  const replaceRefundTiers = async (tiers: { days_before: number; refund_rate: number }[]) => {
    const { error: delError } = await supabase.from('refund_policy_tiers').delete().gte('days_before', -1)
    if (delError) throw delError
    if (tiers.length) {
      const { error } = await supabase.from('refund_policy_tiers').insert(tiers)
      if (error) throw error
    }
  }

  // 예약 취소 시 환불율/금액 계산 (표시용 — 실제 금액은 서버에서 다시 산정)
  const reservationRefund = (startDate: string, paidAmount: number, tiers: RefundTier[]) => {
    const startMs = Date.parse(`${startDate}T00:00:00`)
    const daysUntil = Math.ceil((startMs - Date.now()) / 86_400_000)
    let rate = 0
    for (const t of tiers) {
      if (daysUntil >= t.days_before) {
        rate = t.refund_rate
        break
      }
    }
    return { daysUntil, rate, amount: Math.round((paidAmount * rate) / 100) }
  }

  const cancelPayment = async (input: {
    paymentId: string
    reason?: string
    cancelAmount?: number
    restoreStock?: boolean
  }) => {
    return await $fetch<{ ok: boolean; refundAmount: number; targetType: 'order' | 'reservation' }>(
      '/api/payments/cancel',
      { method: 'POST', body: input }
    )
  }

  return { fetchRefundTiers, replaceRefundTiers, reservationRefund, cancelPayment }
}
