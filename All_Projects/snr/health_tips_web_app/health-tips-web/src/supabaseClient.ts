export type HealthTip = {
	id: number
	title: string
	content: string
	created_at: string
}

import { createClient } from '@supabase/supabase-js'

const supabaseUrl = (import.meta as any).env.VITE_SUPABASE_URL as string | undefined
const supabaseAnonKey = (import.meta as any).env.VITE_SUPABASE_ANON_KEY as string | undefined

export const supabase = createClient(supabaseUrl ?? '', supabaseAnonKey ?? '')
