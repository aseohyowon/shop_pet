import type { Pet } from '~/types/database.types'

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
    isVaccinated: boolean
    notes: string
  }): Promise<Pet> => {
    if (!user.value) throw new Error('로그인이 필요합니다.')

    const { data, error } = await supabase
      .from('pets')
      .insert({
        owner_id: user.value.sub,
        name: input.name,
        breed: input.breed || null,
        age: input.age,
        weight: input.weight,
        is_vaccinated: input.isVaccinated,
        notes: input.notes || null
      })
      .select('*')
      .single()

    if (error) throw error
    return data as Pet
  }

  return { fetchMyPets, createPet }
}
