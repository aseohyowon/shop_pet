// 최소 수동 타입 정의. 이후 Supabase CLI(`supabase gen types typescript`)로
// 전체 스키마 기준 자동 생성 타입으로 교체 예정입니다.
export type ReservationType = 'hotel' | 'daycare'
export type ReservationStatus = 'pending' | 'confirmed' | 'rejected' | 'cancelled' | 'completed'
export type OrderStatus = 'pending' | 'paid' | 'preparing' | 'shipping' | 'completed' | 'cancelled'
export type PaymentTargetType = 'reservation' | 'order'
export type PaymentStatus = 'ready' | 'paid' | 'failed' | 'cancelled'

// 고객용 화면 테마 (관리자가 /admin/settings 에서 선택)
export type SiteTheme = 'default' | 'theme1' | 'theme2'
export type HomeVariant = 'auto' | 'main1' | 'main2'

export type InquiryStatus = 'open' | 'answered' | 'closed'

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string
          email: string
          name: string | null
          phone: string | null
          role: 'customer' | 'admin'
          created_at: string
        }
        Insert: {
          id: string
          email: string
          name?: string | null
          phone?: string | null
          role?: 'customer' | 'admin'
        }
        Update: {
          name?: string | null
          phone?: string | null
          role?: 'customer' | 'admin'
        }
      }
      pets: {
        Row: {
          id: string
          owner_id: string
          name: string
          breed: string | null
          age: number | null
          weight: number | null
          is_vaccinated: boolean
          notes: string | null
          created_at: string
        }
        Insert: {
          owner_id: string
          name: string
          breed?: string | null
          age?: number | null
          weight?: number | null
          is_vaccinated?: boolean
          notes?: string | null
        }
        Update: Partial<Database['public']['Tables']['pets']['Insert']>
      }
      reservations: {
        Row: {
          id: string
          user_id: string
          pet_id: string
          type: ReservationType
          start_date: string
          end_date: string
          start_time: string
          end_time: string
          status: ReservationStatus
          memo: string | null
          deposit_paid: boolean
          created_at: string
        }
        Insert: {
          user_id: string
          pet_id: string
          type: ReservationType
          start_date: string
          end_date: string
          start_time?: string
          end_time?: string
          status?: ReservationStatus
          memo?: string | null
        }
        Update: {
          status?: ReservationStatus
          memo?: string | null
        }
      }
      service_settings: {
        Row: { type: ReservationType; default_capacity: number }
        Insert: { type: ReservationType; default_capacity: number }
        Update: { default_capacity?: number }
      }
      daily_capacity: {
        Row: { id: string; date: string; type: ReservationType; max_capacity: number }
        Insert: { date: string; type: ReservationType; max_capacity: number }
        Update: { max_capacity?: number }
      }
      products: {
        Row: {
          id: string
          name: string
          description: string | null
          price: number
          stock: number
          category: string | null
          image_url: string | null
          is_active: boolean
          created_at: string
        }
        Insert: {
          name: string
          description?: string | null
          price: number
          stock?: number
          category?: string | null
          image_url?: string | null
          is_active?: boolean
        }
        Update: Partial<Database['public']['Tables']['products']['Insert']>
      }
      cart_items: {
        Row: {
          id: string
          user_id: string
          product_id: string
          quantity: number
          created_at: string
        }
        Insert: { user_id: string; product_id: string; quantity: number }
        Update: { quantity?: number }
      }
      orders: {
        Row: {
          id: string
          user_id: string
          status: OrderStatus
          total_amount: number
          recipient_name: string | null
          recipient_phone: string | null
          shipping_address: string | null
          shipping_memo: string | null
          tracking_courier: string | null
          tracking_number: string | null
          created_at: string
        }
        Insert: { user_id: string; status?: OrderStatus; total_amount?: number }
        Update: {
          status?: OrderStatus
          recipient_name?: string | null
          recipient_phone?: string | null
          shipping_address?: string | null
          shipping_memo?: string | null
          tracking_courier?: string | null
          tracking_number?: string | null
        }
      }
      categories: {
        Row: { id: string; name: string; sort_order: number; is_active: boolean; created_at: string }
        Insert: { name: string; sort_order?: number; is_active?: boolean }
        Update: { name?: string; sort_order?: number; is_active?: boolean }
      }
      inquiries: {
        Row: {
          id: string
          user_id: string | null
          name: string
          phone: string | null
          email: string | null
          message: string
          status: InquiryStatus
          answer: string | null
          answered_at: string | null
          created_at: string
        }
        Insert: {
          user_id?: string | null
          name: string
          phone?: string | null
          email?: string | null
          message: string
        }
        Update: { status?: InquiryStatus; answer?: string | null; answered_at?: string | null }
      }
      order_items: {
        Row: {
          id: string
          order_id: string
          product_id: string
          quantity: number
          price_at_order: number
        }
        Insert: { order_id: string; product_id: string; quantity: number; price_at_order: number }
        Update: never
      }
      site_settings: {
        Row: { key: string; value: string; updated_at: string }
        Insert: { key: string; value: string }
        Update: { value?: string }
      }
      payments: {
        Row: {
          id: string
          user_id: string
          target_type: PaymentTargetType
          target_id: string
          amount: number
          status: PaymentStatus
          toss_payment_key: string | null
          method: string | null
          paid_at: string | null
          created_at: string
        }
        Insert: { user_id: string; target_type: PaymentTargetType; target_id: string; amount: number; status?: PaymentStatus }
        Update: { status?: PaymentStatus; toss_payment_key?: string | null; method?: string | null; paid_at?: string | null }
      }
    }
    Functions: {
      book_reservation: {
        Args: {
          p_pet_id: string
          p_type: ReservationType
          p_start_date: string
          p_end_date: string
          p_memo?: string | null
          p_start_time?: string
          p_end_time?: string
        }
        Returns: Database['public']['Tables']['reservations']['Row']
      }
      get_availability: {
        Args: { p_type: ReservationType; p_start: string; p_end: string }
        Returns: { date: string; capacity: number; booked: number; remaining: number }[]
      }
      create_order: {
        Args: {
          p_items: { product_id: string; quantity: number }[]
          p_shipping?: {
            recipient_name?: string
            recipient_phone?: string
            shipping_address?: string
            shipping_memo?: string
          }
        }
        Returns: { order_id: string; payment_id: string; total_amount: number }[]
      }
      create_reservation_payment: {
        Args: { p_reservation_id: string; p_amount?: number }
        Returns: Database['public']['Tables']['payments']['Row']
      }
    }
  }
}

export type Profile = Database['public']['Tables']['profiles']['Row']
export type Pet = Database['public']['Tables']['pets']['Row']
export type Reservation = Database['public']['Tables']['reservations']['Row']
export type AvailabilityDay = { date: string; capacity: number; booked: number; remaining: number }
export type Product = Database['public']['Tables']['products']['Row']
export type Category = Database['public']['Tables']['categories']['Row']
export type Inquiry = Database['public']['Tables']['inquiries']['Row']
export type CartItem = Database['public']['Tables']['cart_items']['Row']
export type Order = Database['public']['Tables']['orders']['Row']
export type OrderItem = Database['public']['Tables']['order_items']['Row']
export type Payment = Database['public']['Tables']['payments']['Row']
