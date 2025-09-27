import { Link, Outlet, Route, Routes } from 'react-router-dom'
import Home from './pages/Home'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Tools from './pages/Tools'
import RequireAuth from './routes/RequireAuth'
import { useAuth } from './contexts/AuthContext'

function Shell() {
	const { user } = useAuth()
	return (
		<div className="min-h-screen flex flex-col">
			<nav className="glass border-b border-white/20 sticky top-0 z-50">
				<div className="mx-auto max-w-6xl px-4 py-4 flex items-center gap-6">
					<Link to="/" className="font-bold text-2xl gradient-text hover:scale-105 transition-transform duration-300">
						DailyCare
					</Link>
					<div className="ml-auto flex items-center gap-6">
						<Link to="/tools" className="text-sm text-gray-700 hover:text-brand transition-colors duration-200 font-medium">
							Tools
						</Link>
						{user ? (
							<Link to="/dashboard" className="text-sm text-gray-700 hover:text-brand transition-colors duration-200 font-medium">
								Dashboard
							</Link>
						) : (
							<Link to="/login" className="text-sm text-gray-700 hover:text-brand transition-colors duration-200 font-medium">
								Login
							</Link>
						)}
					</div>
				</div>
			</nav>
			<main className="flex-1">
				<Outlet />
			</main>
			<footer className="glass border-t border-white/20 text-xs text-gray-500 py-6">
				<div className="mx-auto max-w-6xl px-4 text-center">
					© {new Date().getFullYear()} DailyCare - Your Health & Wellness Companion
				</div>
			</footer>
		</div>
	)
}

export default function App() {
	return (
		<Routes>
			<Route element={<Shell />}> 
				<Route index element={<Home />} />
				<Route path="login" element={<Login />} />
				<Route path="tools" element={<Tools />} />
				<Route element={<RequireAuth />}>
					<Route path="dashboard" element={<Dashboard />} />
				</Route>
				<Route path="*" element={<div className="p-4">Not Found</div>} />
			</Route>
		</Routes>
	)
}
