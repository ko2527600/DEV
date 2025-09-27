import { useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { Navigate, useLocation } from 'react-router-dom'
import Alert from '../components/ui/Alert'

export default function Login() {
	const { user, signInWithPassword } = useAuth()
	const [email, setEmail] = useState('')
	const [password, setPassword] = useState('')
	const [submitting, setSubmitting] = useState(false)
	const [error, setError] = useState<string | null>(null)
	const location = useLocation() as any
	const from = location.state?.from?.pathname || '/dashboard'

	if (user) return <Navigate to={from} replace />

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault()
		setSubmitting(true)
		setError(null)
		const { error } = await signInWithPassword({ email, password })
		setSubmitting(false)
		if (error) setError(error)
	}

	return (
		<div className="mx-auto max-w-md p-4">
			<h2 className="text-xl font-semibold mb-4">Admin Login</h2>
			<form onSubmit={handleSubmit} className="space-y-3">
				<label className="block">
					<span className="block text-sm text-gray-700">Email</span>
					<input className="input mt-1" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
				</label>
				<label className="block">
					<span className="block text-sm text-gray-700">Password</span>
					<input className="input mt-1" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
				</label>
				{error && <Alert variant="error">{error}</Alert>}
				<button type="submit" className="btn w-full" disabled={submitting}>{submitting ? 'Signing in…' : 'Sign in'}</button>
			</form>
		</div>
	)
}
