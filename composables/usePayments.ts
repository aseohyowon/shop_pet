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

  // 예약 건의 예약금 결제 레코드 생성
  const createReservationPayment = async (reservationId: string, amount = 30000) => {
    const { data, error } = await supabase.rpc('create_reservation_payment', {
      p_reservation_id: reservationId,
      p_amount: amount
    })
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

  return { createOrderPayment, createReservationPayment, confirmPayment }
}
