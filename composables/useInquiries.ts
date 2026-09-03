import type { Inquiry, InquiryStatus } from '~/types/database.types'

export const useInquiries = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  // 고객: 문의 접수 (비로그인도 가능)
  const createInquiry = async (input: { name: string; phone: string; email?: string; message: string }) => {
    const { error } = await supabase.from('inquiries').insert({
      user_id: user.value?.sub ?? null,
      name: input.name.trim(),
      phone: input.phone.trim() || null,
      email: input.email?.trim() || null,
      message: input.message.trim()
    })
    if (error) throw error
  }

  // 고객: 본인 문의 내역 (로그인 상태에서 남긴 것만)
  const fetchMyInquiries = async (): Promise<Inquiry[]> => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('inquiries')
      .select('*')
      .eq('user_id', user.value.sub)
      .order('created_at', { ascending: false })
    if (error) throw error
    return (data ?? []) as Inquiry[]
  }

  // 관리자: 전체 문의
  const fetchAllInquiries = async (status?: InquiryStatus): Promise<Inquiry[]> => {
    let query = supabase.from('inquiries').select('*').order('created_at', { ascending: false })
    if (status) query = query.eq('status', status)
    const { data, error } = await query
    if (error) throw error
    return (data ?? []) as Inquiry[]
  }

  const fetchInquiryById = async (id: string): Promise<Inquiry> => {
    const { data, error } = await supabase.from('inquiries').select('*').eq('id', id).single()
    if (error) throw error
    return data as Inquiry
  }

  const answerInquiry = async (id: string, answer: string) => {
    const { error } = await supabase
      .from('inquiries')
      .update({ answer: answer.trim(), status: 'answered', answered_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
  }

  const updateInquiryStatus = async (id: string, status: InquiryStatus) => {
    const { error } = await supabase.from('inquiries').update({ status }).eq('id', id)
    if (error) throw error
  }

  const countOpenInquiries = async (): Promise<number> => {
    const { count, error } = await supabase
      .from('inquiries')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'open')
    if (error) throw error
    return count ?? 0
  }

  return {
    createInquiry,
    fetchMyInquiries,
    fetchAllInquiries,
    fetchInquiryById,
    answerInquiry,
    updateInquiryStatus,
    countOpenInquiries
  }
}
