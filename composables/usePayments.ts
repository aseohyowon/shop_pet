export const usePayments = () => {
  const supabase = useSupabaseClient()

  // 장바구니 상품으로 주문 + 결제 레코드 생성 (재고 확인/차감은 DB에서 원자적으로 처리)
  const createOrderPayment = async (
    items: { productId: string; quantity: number }[],
    shipping?: { recipientName: string; recipientPhone: string; shippingAddress: string; shippingMemo?: string }
  ) => {
    const { data, error } = await supabase.rpc('create_order', {
      p_items: items.map((i) => ({ product_id: i.productId, quantity: i.quantity })),
      p_shipping: shipping
        ? {
            recipient_name: shipping.recipientName,
            recipient_phone: shipping.recipientPhone,
            shipping_address: shipping.shippingAddress,
            shipping_memo: shipping.shippingMemo ?? ''
          }
        : {}
    })
    if (error) throw error
    const row = Array.isArray(data) ? data[0] : data
    return { orderId: row.order_id as string, paymentId: row.payment_id as string, totalAmount: row.total_amount as number }
  }

  // 결제 안 하고 이탈한 주문의 결제를 다시 이어가기 (기존 ready 결제 재사용)
  const resumeOrderPayment = async (orderId: string) => {
    const { data, error } = await supabase
      .from('payments')
      .select('*')
      .eq('target_type', 'order')
      .eq('target_id', orderId)
      .eq('status', 'ready')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (error) throw error
    return data
  }

  // 예약 건의 결제 레코드 생성 (금액은 서버에서 서비스 요금 기준으로 산정)
  const createReservationPayment = async (reservationId: string) => {
    const { data, error } = await supabase.rpc('create_reservation_payment', {
      p_reservation_id: reservationId
    })
    if (error) throw error
    return data
  }

  // 특정 주문/예약의 결제완료(부분환불 포함) 건 조회 — 취소/환불에 사용
  const fetchPaidPayment = async (targetType: 'order' | 'reservation', targetId: string) => {
    const { data, error } = await supabase
      .from('payments')
      .select('id, amount, status, refunded_amount, method, paid_at, cancel_reason')
      .eq('target_type', targetType)
      .eq('target_id', targetId)
      .eq('status', 'paid')
      .maybeSingle()
    if (error) throw error
    return data
  }

  // 토스페이먼츠 successUrl에서 호출: 서버가 시크릿 키로 결제 승인 처리
  const confirmPayment = async (input: { paymentId: string; paymentKey: string; amount: number }) => {
    return await $fetch<{ targetType: 'reservation' | 'order'; targetId: string }>('/api/payments/confirm', {
      method: 'POST',
      body: input
    })
  }

  return {
    createOrderPayment,
    resumeOrderPayment,
    fetchPaidPayment,
    createReservationPayment,
    confirmPayment
  }
}
