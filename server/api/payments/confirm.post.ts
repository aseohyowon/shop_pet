import { serverSupabaseServiceRole, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const body = await readBody<{ paymentId: string; paymentKey: string; amount: number }>(event)
  const { paymentId, paymentKey, amount } = body ?? {}

  if (!paymentId || !paymentKey || !amount) {
    throw createError({ statusCode: 400, statusMessage: '잘못된 요청입니다.' })
  }

  const user = await serverSupabaseUser(event)
  if (!user) {
    throw createError({ statusCode: 401, statusMessage: '로그인이 필요합니다.' })
  }

  const supabase = serverSupabaseServiceRole(event)

  const { data: payment, error: paymentError } = await supabase
    .from('payments')
    .select('*')
    .eq('id', paymentId)
    .single()

  if (paymentError || !payment) {
    throw createError({ statusCode: 404, statusMessage: '결제 정보를 찾을 수 없습니다.' })
  }

  if (payment.user_id !== user.sub) {
    throw createError({ statusCode: 403, statusMessage: '본인의 결제만 처리할 수 있습니다.' })
  }

  // 이미 처리된 결제면 그대로 결과만 반환 (successUrl 중복 진입 대비)
  if (payment.status === 'paid') {
    return { targetType: payment.target_type, targetId: payment.target_id }
  }

  if (payment.amount !== amount) {
    throw createError({ statusCode: 400, statusMessage: '결제 금액이 일치하지 않습니다.' })
  }

  const config = useRuntimeConfig()
  const secretKey = config.tossSecretKey as string

  let tossResult: { method?: string }
  try {
    tossResult = await $fetch('https://api.tosspayments.com/v1/payments/confirm', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${secretKey}:`).toString('base64')}`,
        'Content-Type': 'application/json'
      },
      body: { paymentKey, orderId: paymentId, amount }
    })
  } catch (err: any) {
    await supabase.from('payments').update({ status: 'failed' }).eq('id', paymentId)
    throw createError({
      statusCode: 400,
      statusMessage: err?.data?.message ?? '결제 승인에 실패했습니다.'
    })
  }

  await supabase
    .from('payments')
    .update({
      status: 'paid',
      toss_payment_key: paymentKey,
      method: tossResult.method ?? null,
      paid_at: new Date().toISOString()
    })
    .eq('id', paymentId)

  // 사용한 포인트 차감 (payments.points_used 만큼)
  const { error: consumeError } = await supabase.rpc('consume_points_for_payment', {
    p_payment_id: paymentId
  })
  if (consumeError) {
    console.error('consume_points_for_payment failed:', consumeError.message)
  }

  if (payment.target_type === 'order') {
    // 재고를 여기서(결제 승인 시점에) 원자적으로 재검증 + 차감한다.
    // 이미 토스 결제는 승인됐으므로, 이 시점의 재고 부족은 드문 예외 상황으로 간주해 관리자가 후속 처리한다.
    const { error: finalizeError } = await supabase.rpc('finalize_order', { p_order_id: payment.target_id })
    if (finalizeError) {
      console.error('finalize_order failed after payment capture:', finalizeError.message)
    }
  } else if (payment.target_type === 'pass') {
    const { error: activateError } = await supabase.rpc('activate_pass', { p_pass_id: payment.target_id })
    if (activateError) {
      console.error('activate_pass failed:', activateError.message)
    }
  } else {
    // 결제 완료 시 예약을 자동으로 확정 처리 (관리자 승인 단계 생략)
    await supabase
      .from('reservations')
      .update({ deposit_paid: true, status: 'confirmed' })
      .eq('id', payment.target_id)
      .in('status', ['pending', 'confirmed'])
  }

  // 구매 적립 (실제 카드 결제 금액의 N%)
  const { error: earnError } = await supabase.rpc('award_purchase_points', {
    p_target_type: payment.target_type,
    p_target_id: payment.target_id
  })
  if (earnError) {
    console.error('award_purchase_points failed:', earnError.message)
  }

  return { targetType: payment.target_type, targetId: payment.target_id }
})
