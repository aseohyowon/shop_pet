import type { Pet, VaccineStatus } from '~/types/database.types'

export const usePets = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  const fetchMyPets = async (): Promise<Pet[]> => {
    if (!user.value) return []
    const { data, error } = await supabase
      .from('pets')
      .select('*')
      .eq('owner_id', user.value.sub)
      .order('created_at', { ascending: false })

    if (error) throw error
    return (data ?? []) as Pet[]
  }

  const createPet = async (input: {
    name: string
    breed: string
    age: number | null
    weight: number | null
    vaccinations: number[] // 회원이 체크한 예방접종 번호 (1~5)
    rulesAgreed: boolean
    registrationNo?: string // 동물등록번호 (선택)
    notes: string
  }): Promise<Pet> => {
    if (!user.value) throw new Error('로그인이 필요합니다.')
    if (!input.rulesAgreed) throw new Error('이용 규정에 동의해주세요.')

    const vaccinations: Record<string, VaccineStatus> = {}
    for (const n of input.vaccinations) {
      if (n >= 1 && n <= 5) vaccinations[String(n)] = 'member'
    }

    const { data, error } = await supabase
      .from('pets')
      .insert({
        owner_id: user.value.sub,
        name: input.name,
        breed: input.breed || null,
        age: input.age,
        weight: input.weight,
        is_vaccinated: input.vaccinations.length > 0,
        vaccinations,
        rules_agreed_at: new Date().toISOString(),
        registration_no: input.registrationNo?.trim() || null,
        notes: input.notes || null
      })
      .select('*')
      .single()

    if (error) throw error
    return data as Pet
  }

  // 관리자: 특정 반려동물 백신 상태 변경 ('member' → 'admin' 확인 등)
  const setVaccineStatus = async (petId: string, no: number, status: 'member' | 'admin' | 'none') => {
    const { error } = await supabase.rpc('set_vaccine_status', {
      p_pet_id: petId,
      p_no: no,
      p_status: status
    })
    if (error) throw error
  }

  return { fetchMyPets, createPet, setVaccineStatus }
}
