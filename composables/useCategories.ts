import type { Category } from '~/types/database.types'

export const useCategories = () => {
  const supabase = useSupabaseClient()

  // 쇼핑몰 필터용: 활성 카테고리만, 정렬 순서대로
  const fetchActiveCategories = async (): Promise<Category[]> => {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true })
    if (error) throw error
    return (data ?? []) as Category[]
  }

  // 관리자용: 전체
  const fetchAllCategories = async (): Promise<Category[]> => {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true })
    if (error) throw error
    return (data ?? []) as Category[]
  }

  const createCategory = async (input: { name: string; sortOrder?: number }) => {
    const { error } = await supabase
      .from('categories')
      .insert({ name: input.name.trim(), sort_order: input.sortOrder ?? 0 })
    if (error) throw error
  }

  const updateCategory = async (
    id: string,
    input: Partial<{ name: string; sortOrder: number; isActive: boolean }>,
    prevName?: string
  ) => {
    const patch: Record<string, unknown> = {}
    if (input.name !== undefined) patch.name = input.name.trim()
    if (input.sortOrder !== undefined) patch.sort_order = input.sortOrder
    if (input.isActive !== undefined) patch.is_active = input.isActive

    const { error } = await supabase.from('categories').update(patch).eq('id', id)
    if (error) throw error

    // 이름이 바뀌면 이 카테고리를 쓰던 상품들의 category 값도 함께 갱신
    if (input.name !== undefined && prevName && prevName !== input.name.trim()) {
      await supabase.from('products').update({ category: input.name.trim() }).eq('category', prevName)
    }
  }

  const deleteCategory = async (id: string, name: string) => {
    // 이 카테고리를 쓰던 상품은 '미분류'로 (null) 변경
    await supabase.from('products').update({ category: null }).eq('category', name)
    const { error } = await supabase.from('categories').delete().eq('id', id)
    if (error) throw error
  }

  return {
    fetchActiveCategories,
    fetchAllCategories,
    createCategory,
    updateCategory,
    deleteCategory
  }
}
