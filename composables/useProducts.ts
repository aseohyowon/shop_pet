import type { Product } from '~/types/database.types'

export const useProducts = () => {
  const supabase = useSupabaseClient()

  const fetchProducts = async (category?: string): Promise<Product[]> => {
    let query = supabase.from('products').select('*').eq('is_active', true).order('created_at', { ascending: false })
    if (category) query = query.eq('category', category)

    const { data, error } = await query
    if (error) throw error
    return (data ?? []) as Product[]
  }

  const fetchProductById = async (id: string): Promise<Product> => {
    const { data, error } = await supabase.from('products').select('*').eq('id', id).single()
    if (error) throw error
    return data as Product
  }

  // 관리자 전용 -------------------------------------------------

  const fetchAllProductsForAdmin = async (): Promise<Product[]> => {
    const { data, error } = await supabase.from('products').select('*').order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as Product[]
  }

  const uploadProductImage = async (file: File): Promise<string> => {
    const ext = file.name.split('.').pop()
    const path = `${crypto.randomUUID()}.${ext}`

    const { error } = await supabase.storage.from('product-images').upload(path, file, { upsert: true })
    if (error) throw error

    const { data } = supabase.storage.from('product-images').getPublicUrl(path)
    return data.publicUrl
  }

  const createProduct = async (input: {
    name: string
    description: string
    price: number
    stock: number
    category: string
    imageUrl: string | null
  }): Promise<Product> => {
    const { data, error } = await supabase
      .from('products')
      .insert({
        name: input.name,
        description: input.description || null,
        price: input.price,
        stock: input.stock,
        category: input.category || null,
        image_url: input.imageUrl
      })
      .select('*')
      .single()

    if (error) throw error
    return data as Product
  }

  const updateProduct = async (
    id: string,
    input: Partial<{
      name: string
      description: string | null
      price: number
      stock: number
      category: string | null
      imageUrl: string | null
      isActive: boolean
    }>
  ) => {
    const { error } = await supabase
      .from('products')
      .update({
        ...(input.name !== undefined && { name: input.name }),
        ...(input.description !== undefined && { description: input.description }),
        ...(input.price !== undefined && { price: input.price }),
        ...(input.stock !== undefined && { stock: input.stock }),
        ...(input.category !== undefined && { category: input.category }),
        ...(input.imageUrl !== undefined && { image_url: input.imageUrl }),
        ...(input.isActive !== undefined && { is_active: input.isActive })
      })
      .eq('id', id)

    if (error) throw error
  }

  const deleteProduct = async (id: string) => {
    const { error } = await supabase.from('products').delete().eq('id', id)
    if (error) throw error
  }

  return {
    fetchProducts,
    fetchProductById,
    fetchAllProductsForAdmin,
    uploadProductImage,
    createProduct,
    updateProduct,
    deleteProduct
  }
}
