import type { AvailabilityDay, Reservation, ReservationStatus, ReservationType } from '~/types/database.types'

export const useReservations = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  const getAvailability = async (type: ReservationType, start: string, end: string): Promise<AvailabilityDay[]> => {
    const { data, error } = await supabase.rpc('get_availability', {
      p_type: type,
      p_start: start,
      p_end: end
    })
    if (error) throw error
    return (data ?? []) as AvailabilityDay[]
  }

  const createReservation = async (input: {
    petId: string
    type: ReservationType
    startDate: string
    endDate: string
    startTime: string
    endTime: string
    memo: string
    termsAgreed: boolean
    daycareHourly?: boolean
    options?: { pricing_item_id: string; quantity: number }[]
  }): Promise<Reservation> => {
    const { data, error } = await supabase.rpc('book_reservation', {
      p_pet_id: input.petId,
      p_type: input.type,
      p_start_date: input.startDate,
      p_end_date: input.endDate,
      p_memo: input.memo || null,
      p_start_time: input.startTime,
      p_end_time: input.endTime,
      p_terms_agreed: input.termsAgreed,
      p_daycare_hourly: input.daycareHourly ?? false,
      p_options: input.options ?? []
    })
    if (error) throw error
    return data as Reservation
  }

  // 마이페이지: 반려동물 정보를 함께 가져옴
  const fetchMyReservations = async () => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('reservations')
      .select('*, pets(name, breed)')
      .eq('user_id', user.value.sub)
      .order('start_date', { ascending: false })

    if (error) throw error
    return data ?? []
  }

  // 관리자: 전체 예약 + 보호자/반려동물 정보를 함께 가져옴
  const fetchAllReservations = async () => {
    const { data, error } = await supabase
      .from('reservations')
      .select('*, pets(id, name, breed, age, weight, vaccinations, rules_agreed_at, registration_no, notes), profiles(name, phone, email), reservation_options(name, unit_price, quantity)')
      .order('start_date', { ascending: false })

    if (error) throw error
    return data ?? []
  }

  const fetchReservationById = async (id: string) => {
    const { data, error } = await supabase
      .from('reservations')
      .select('*, pets(id, name, breed, age, weight, vaccinations, rules_agreed_at, registration_no, notes), profiles(name, phone, email), reservation_options(name, unit_price, quantity)')
      .eq('id', id)
      .single()

    if (error) throw error
    return data
  }

  const updateReservationStatus = async (id: string, status: ReservationStatus) => {
    const { error } = await supabase.from('reservations').update({ status }).eq('id', id)
    if (error) throw error
  }

  // 고객: 결제 전 승인 대기 예약 취소 (RLS: pending → cancelled 만 허용)
  const cancelMyPendingReservation = async (id: string) => {
    const { error } = await supabase.from('reservations').update({ status: 'cancelled' }).eq('id', id)
    if (error) throw error
  }

  return {
    getAvailability,
    createReservation,
    fetchMyReservations,
    fetchAllReservations,
    fetchReservationById,
    updateReservationStatus,
    cancelMyPendingReservation
  }
}
