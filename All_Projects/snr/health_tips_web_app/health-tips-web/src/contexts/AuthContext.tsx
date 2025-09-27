import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '../supabaseClient'

export type AuthContextValue = {
	loading: boolean
	session: Session | null
	user: User | null
	signInWithPassword: (params: { email: string; password: string }) => Promise<{ error: string | null }>
	signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
	const [loading, setLoading] = useState(true)
	const [session, setSession] = useState<Session | null>(null)

	useEffect(() => {
		let isMounted = true
		async function init() {
			const { data } = await supabase.auth.getSession()
			if (!isMounted) return
			setSession(data.session)
			setLoading(false)
		}
		init()
		const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
			setSession(newSession)
		})
		return () => {
			isMounted = false
			sub.subscription.unsubscribe()
		}
	}, [])

	const value = useMemo<AuthContextValue>(() => ({
		loading,
		session,
		user: session?.user ?? null,
		signInWithPassword: async ({ email, password }) => {
			const { error } = await supabase.auth.signInWithPassword({ email, password })
			return { error: error?.message ?? null }
		},
		signOut: async () => {
			await supabase.auth.signOut()
		}
	}), [loading, session])

	return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
	const ctx = useContext(AuthContext)
	if (!ctx) throw new Error('useAuth must be used within AuthProvider')
	return ctx
}
