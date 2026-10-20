import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const key = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined
export const supabase: SupabaseClient | null = url && key && !url.includes('your-project') && !key.includes('your-public') ? createClient(url, key) : null

export type PasswordRecoverySession = Session

let passwordRecoverySession: PasswordRecoverySession | null = null
const passwordRecoveryListeners = new Set<(session: PasswordRecoverySession | null) => void>()

if (supabase) {
  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'PASSWORD_RECOVERY') passwordRecoverySession = session
    else if (event === 'SIGNED_OUT' || event === 'SIGNED_IN') passwordRecoverySession = null
    else if (passwordRecoverySession && session) passwordRecoverySession = session

    passwordRecoveryListeners.forEach((listener) => listener(passwordRecoverySession))
  })
}

export function subscribeToPasswordRecoverySession(listener: (session: PasswordRecoverySession | null) => void) {
  passwordRecoveryListeners.add(listener)
  listener(passwordRecoverySession)
  return () => { passwordRecoveryListeners.delete(listener) }
}

export type Category = { id: string; name_ar: string; slug: string; sort_order: number }
export type MenuItem = { id: string; name_ar: string; description_ar: string | null; price_egp: number | null; category_id: string | null; image_path: string | null; is_published: boolean; is_available: boolean; is_demo: boolean; is_featured?: boolean; needs_review?: boolean; review_note_ar?: string | null; variation_ar?: string[]; categories?: Category | null }
export type Offer = { id: string; title_ar: string; description_ar: string | null; image_path: string | null; starts_at: string | null; ends_at: string | null; is_active: boolean; is_published: boolean; is_demo: boolean }
export type Testimonial = { id: string; display_name: string | null; content: string; rating: number | null; is_published: boolean; created_at: string }

export function imageUrl(path: string | null | undefined) {
  if (!path) return null
  if (path.startsWith('http') || path.startsWith('/')) return path
  return supabase?.storage.from('restaurant-images').getPublicUrl(path).data.publicUrl ?? null
}
