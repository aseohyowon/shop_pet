import type { OrderStatus } from '~/types/database.types'

export const useOrders = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  const fetchMyOrders = async () => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*, products(name, image_url))')
      .eq('user_id', user.value.sub)
      .order('created_at', { ascending: false })

    if (error) throw error
    return data ?? []
  }

  const fetchAllOrdersForAdmin = async () => {
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*, products(name)), profiles(name, phone, email)')
      .order('created_at', { ascending: false })

    if (error) throw error
    return data ?? []
  }

  const fetchOrderByIdForAdmin = async (id: string) => {
    const { data, error } = await supabase
      .from('orders')
      .select('*, order_items(*, products(name, image_url)), profiles(name, phone, email)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  }

  const updateOrderStatus = async (id: string, status: OrderStatus) => {
    const { error } = await supabase.from('orders').update({ status }).eq('id', id)
    if (error) throw error
  }

  // 관리자: 송장(택배사/운송장번호) 등록 — 등록 시 상태를 '배송중'으로 올림
  const updateOrderTracking = async (
    id: string,
    input: { courier: string; number: string; markShipping?: boolean }
  ) => {
    const patch: Record<string, unknown> = {
      tracking_courier: input.courier.trim() || null,
      tracking_number: input.number.trim() || null
    }
    if (input.markShipping && input.number.trim()) patch.status = 'shipping'
    const { error } = await supabase.from('orders').update(patch).eq('id', id)
    if (error) throw error
  }

  return {
    fetchMyOrders,
    fetchAllOrdersForAdmin,
    fetchOrderByIdForAdmin,
    updateOrderStatus,
    updateOrderTracking
  }
}
