import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export default function RequireAuth() {
	const { loading, user } = useAuth()
	const location = useLocation()
	if (loading) return <div>Loading…</div>
	if (!user) return <Navigate to="/login" replace state={{ from: location }} />
	return <Outlet />
}
