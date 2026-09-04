import { serverSupabaseServiceRole, serverSupabaseUser } from '#supabase/server'

/**
 * 결제 취소 / 환불.
 * - 고객: 본인 건만, 정책에 맞는 금액만 (주문: 배송 전 전액 / 예약: 취소 시점별 %)
 * - 관리자: 임의 금액(부분 환불 가능), 재고 복구 여부 선택
 */
export default defineEventHandler(async (event) => {
  const body = await readBody<{
    paymentId: string
    reason?: string
    cancelAmount?: number // 관리자 전용 (부분 환불)
    restoreStock?: boolean // 관리자 전용 (주문)
  }>(event)

  const { paymentId } = body ?? {}
  if (!paymentId) throw createError({ statusCode: 400, statusMessage: '잘못된 요청입니다.' })

  const authUser = await serverSupabaseUser(event)
  if (!authUser) throw createError({ statusCode: 401, statusMessage: '로그인이 필요합니다.' })

  const supabase = serverSupabaseServiceRole(event)

  const { data: payment } = await supabase.from('payments').select('*').eq('id', paymentId).single()
  if (!payment) throw createError({ statusCode: 404, statusMessage: '결제 정보를 찾을 수 없습니다.' })

  const { data: profile } = await supabase.from('profiles').select('role').eq('id', authUser.sub).single()
  const isAdmin = (profile as { role?: string } | null)?.role === 'admin'

  if (!isAdmin && payment.user_id !== authUser.sub) {
    throw createError({ statusCode: 403, statusMessage: '본인의 결제만 취소할 수 있습니다.' })
  }
  if (payment.status !== 'paid') {
    throw createError({ statusCode: 400, statusMessage: '결제 완료된 건만 취소할 수 있습니다.' })
  }

  // ── 취소 가능 여부 + 환불 금액 산정 ──────────────────────────
  let refundAmount = payment.amount
  let restoreStock = true

  if (payment.target_type === 'order') {
    const { data: order } = await supabase.from('orders').select('*').eq('id', payment.target_id).single()
    if (!order) throw createError({ statusCode: 404, statusMessage: '주문을 찾을 수 없습니다.' })

    if (isAdmin) {
      refundAmount = Math.min(body.cancelAmount ?? payment.amount, payment.amount)
      restoreStock = body.restoreStock ?? true
    } else {
      if (!['paid', 'preparing'].includes(order.status)) {
        throw createError({
          statusCode: 400,
          statusMessage: '배송이 시작된 주문은 취소할 수 없습니다. 고객센터로 문의해주세요.'
        })
      }
      refundAmount = payment.amount // 배송 전 전액 환불
    }
  } else {
    // reservation
    const { data: resv } = await supabase.from('reservations').select('*').eq('id', payment.target_id).single()
    if (!resv) throw createError({ statusCode: 404, statusMessage: '예약을 찾을 수 없습니다.' })
    restoreStock = false

    if (isAdmin) {
      refundAmount = Math.min(body.cancelAmount ?? payment.amount, payment.amount)
    } else {
      if (['cancelled', 'rejected', 'completed'].includes(resv.status)) {
        throw createError({ statusCode: 400, statusMessage: '취소할 수 없는 예약입니다.' })
      }
      const { data: tiers } = await supabase
        .from('refund_policy_tiers')
        .select('*')
        .order('days_before', { ascending: false })

      const startMs = Date.parse(`${resv.start_date}T00:00:00`)
      const daysUntil = Math.ceil((startMs - Date.now()) / 86_400_000)
      let rate = 0
      for (const t of (tiers ?? []) as { days_before: number; refund_rate: number }[]) {
        if (daysUntil >= t.days_before) {
          rate = t.refund_rate
          break
        }
      }
      refundAmount = Math.round((payment.amount * rate) / 100)
    }
  }

  // ── 토스 결제 취소 호출 ─────────────────────────────────────
  if (refundAmount > 0 && payment.toss_payment_key) {
    const secretKey = useRuntimeConfig().tossSecretKey as string
    try {
      await $fetch(`https://api.tosspayments.com/v1/payments/${payment.toss_payment_key}/cancel`, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(`${secretKey}:`).toString('base64')}`,
          'Content-Type': 'application/json'
        },
        body: {
          cancelReason: body.reason || '고객 요청',
          ...(refundAmount < payment.amount ? { cancelAmount: refundAmount } : {})
        }
      })
    } catch (err: any) {
      throw createError({
        statusCode: 400,
        statusMessage: err?.data?.message ?? '결제 취소 처리에 실패했습니다.'
      })
    }
  }

  // ── DB 반영 ────────────────────────────────────────────────
  const totalRefunded = payment.refunded_amount + refundAmount
  await supabase
    .from('payments')
    .update({
      status: totalRefunded >= payment.amount ? 'cancelled' : 'paid',
      refunded_amount: totalRefunded,
      refunded_at: new Date().toISOString(),
      cancel_reason: body.reason ?? null
    })
    .eq('id', paymentId)

  if (payment.target_type === 'order') {
    const { data: order } = await supabase.from('orders').select('status').eq('id', payment.target_id).single()
    if (restoreStock && ['paid', 'preparing', 'shipping'].includes((order as { status: string })?.status)) {
      await supabase.rpc('restore_order_stock', { p_order_id: payment.target_id })
    }
    await supabase.from('orders').update({ status: 'cancelled' }).eq('id', payment.target_id)
  } else {
    await supabase.from('reservations').update({ status: 'cancelled' }).eq('id', payment.target_id)
  }

  // 사용 포인트 복원 + 적립 포인트 회수
  const { error: revertError } = await supabase.rpc('revert_purchase_points', {
    p_target_type: payment.target_type,
    p_target_id: payment.target_id
  })
  if (revertError) {
    console.error('revert_purchase_points failed:', revertError.message)
  }

  return { ok: true, refundAmount, targetType: payment.target_type }
})
