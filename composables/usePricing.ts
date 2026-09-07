import type { PricingItem, PricingCategory } from '~/types/database.types'

export const PRICING_CATEGORIES: { key: PricingCategory; label: string; icon: string }[] = [
  { key: 'daycare', label: '데이케어', icon: 'wb_sunny' },
  { key: 'daycare_pass', label: '데이케어 정기권', icon: 'confirmation_number' },
  { key: 'hotel', label: '호텔', icon: 'hotel' },
  { key: 'spa', label: '스파', icon: 'spa' }
]

export const usePricing = () => {
  const supabase = useSupabaseClient()

  // 고객용: 노출 중인 항목만, 카테고리별 그룹
  const fetchActiveGrouped = async () => {
    const { data, error } = await supabase
      .from('pricing_items')
      .select('*')
      .eq('is_active', true)
      .order('category', { ascending: true })
      .order('sort_order', { ascending: true })
    if (error) throw error
    const items = (data ?? []) as PricingItem[]
    return PRICING_CATEGORIES.map((c) => ({
      ...c,
      items: items.filter((i) => i.category === c.key)
    })).filter((g) => g.items.length > 0)
  }

  // 관리자용: 전체
  const fetchAll = async (): Promise<PricingItem[]> => {
    const { data, error } = await supabase
      .from('pricing_items')
      .select('*')
      .order('category', { ascending: true })
      .order('sort_order', { ascending: true })
    if (error) throw error
    return (data ?? []) as PricingItem[]
  }

  const createItem = async (input: Partial<PricingItem> & { category: PricingCategory; name: string }) => {
    const { error } = await supabase.from('pricing_items').insert({
      category: input.category,
      name: input.name,
      price: Math.max(0, Math.round(input.price ?? 0)),
      unit: input.unit ?? null,
      note: input.note ?? null,
      sort_order: input.sort_order ?? 0
    })
    if (error) throw error
  }

  const updateItem = async (id: string, patch: Partial<PricingItem>) => {
    const clean: Record<string, unknown> = {}
    if (patch.name !== undefined) clean.name = patch.name
    if (patch.price !== undefined) clean.price = Math.max(0, Math.round(patch.price))
    if (patch.unit !== undefined) clean.unit = patch.unit || null
    if (patch.note !== undefined) clean.note = patch.note || null
    if (patch.sort_order !== undefined) clean.sort_order = patch.sort_order
    if (patch.is_active !== undefined) clean.is_active = patch.is_active
    const { error } = await supabase.from('pricing_items').update(clean).eq('id', id)
    if (error) throw error
  }

  const deleteItem = async (id: string) => {
    const { error } = await supabase.from('pricing_items').delete().eq('id', id)
    if (error) throw error
  }

  // 예약 결제 기준가 (billing_key)
  const fetchReservationBasePrices = async (): Promise<Record<'hotel_night' | 'daycare_day', number>> => {
    const { data } = await supabase
      .from('pricing_items')
      .select('billing_key, price')
      .in('billing_key', ['hotel_night', 'daycare_day'])
    const map = { hotel_night: 0, daycare_day: 0 }
    for (const row of (data ?? []) as { billing_key: string; price: number }[]) {
      if (row.billing_key === 'hotel_night' || row.billing_key === 'daycare_day') map[row.billing_key] = row.price
    }
    return map
  }

  const updateBasePrice = async (billingKey: 'hotel_night' | 'daycare_day', price: number) => {
    const { error } = await supabase
      .from('pricing_items')
      .update({ price: Math.max(0, Math.round(price)) })
      .eq('billing_key', billingKey)
    if (error) throw error
  }

  return {
    fetchActiveGrouped,
    fetchAll,
    createItem,
    updateItem,
    deleteItem,
    fetchReservationBasePrices,
    updateBasePrice
  }
}
