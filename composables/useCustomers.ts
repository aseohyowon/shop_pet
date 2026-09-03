import type { Profile } from '~/types/database.types'

export const useCustomers = () => {
  const supabase = useSupabaseClient()

  // 관리자: 고객(role='customer') 목록 + 검색
  const fetchCustomers = async (keyword = ''): Promise<Profile[]> => {
    let query = supabase
      .from('profiles')
      .select('*')
      .eq('role', 'customer')
      .order('created_at', { ascending: false })

    const kw = keyword.trim()
    if (kw) {
      query = query.or(`name.ilike.%${kw}%,email.ilike.%${kw}%,phone.ilike.%${kw}%`)
    }

    const { data, error } = await query
    if (error) throw error
    return (data ?? []) as Profile[]
  }

  const fetchCustomerDetail = async (id: string) => {
    const [{ data: profile }, { data: pets }, { data: reservations }, { data: orders }] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', id).single(),
      supabase.from('pets').select('*').eq('owner_id', id).order('created_at', { ascending: false }),
      supabase
        .from('reservations')
        .select('*, pets(name, breed)')
        .eq('user_id', id)
        .order('start_date', { ascending: false }),
      supabase
        .from('orders')
        .select('*, order_items(*, products(name))')
        .eq('user_id', id)
        .order('created_at', { ascending: false })
    ])

    return {
      profile: profile as Profile | null,
      pets: pets ?? [],
      reservations: reservations ?? [],
      orders: orders ?? []
    }
  }

  return { fetchCustomers, fetchCustomerDetail }
}
