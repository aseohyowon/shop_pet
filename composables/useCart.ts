export const useCart = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  // 장바구니 + 상품 정보를 함께 조회
  const fetchCart = async () => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('cart_items')
      .select('*, products(*)')
      .eq('user_id', user.value.sub)
      .order('created_at', { ascending: true })

    if (error) throw error
    return data ?? []
  }

  const addToCart = async (productId: string, quantity: number, stock: number) => {
    if (!user.value) throw new Error('로그인이 필요합니다.')

    const { data: existing } = await supabase
      .from('cart_items')
      .select('id, quantity')
      .eq('user_id', user.value.sub)
      .eq('product_id', productId)
      .maybeSingle()

    if (existing) {
      const nextQuantity = Math.min(existing.quantity + quantity, stock)
      const { error } = await supabase.from('cart_items').update({ quantity: nextQuantity }).eq('id', existing.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('cart_items').insert({
        user_id: user.value.sub,
        product_id: productId,
        quantity: Math.min(quantity, stock)
      })
      if (error) throw error
    }
  }

  const updateQuantity = async (cartItemId: string, quantity: number) => {
    if (quantity < 1) return
    const { error } = await supabase.from('cart_items').update({ quantity }).eq('id', cartItemId)
    if (error) throw error
  }

  const removeFromCart = async (cartItemId: string) => {
    const { error } = await supabase.from('cart_items').delete().eq('id', cartItemId)
    if (error) throw error
  }

  return { fetchCart, addToCart, updateQuantity, removeFromCart }
}
