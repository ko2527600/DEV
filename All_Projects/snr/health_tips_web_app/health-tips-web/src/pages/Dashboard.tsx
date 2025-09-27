import { useEffect, useMemo, useState } from 'react'
import { HealthTipsService, type HealthTip, type HealthCategory } from '../services/healthTipsService'
import TipCard from '../components/TipCard'
import AddTipForm from '../components/AddTipForm'
import EditTipForm from '../components/EditTipForm'
import { useAuth } from '../contexts/AuthContext'

export default function Dashboard() {
	const { signOut, user } = useAuth()
	const [tips, setTips] = useState<HealthTip[]>([])
	const [categories, setCategories] = useState<HealthCategory[]>([])
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState<string | null>(null)
	const [editing, setEditing] = useState<HealthTip | null>(null)
	const [selectedCategory, setSelectedCategory] = useState<string>('')

	const sorted = useMemo(() => [...tips].sort((a, b) => (a.created_at < b.created_at ? 1 : -1)), [tips])

	async function load() {
		setLoading(true)
		setError(null)
		try {
			const [tipsData, categoriesData] = await Promise.all([
				HealthTipsService.getHealthTips(),
				HealthTipsService.getCategories()
			])
			setTips(tipsData)
			setCategories(categoriesData)
		} catch (err) {
			setError('Failed to load health tips')
		} finally {
			setLoading(false)
		}
	}

	useEffect(() => { load() }, [])

	async function handleDelete(tip: HealthTip) {
		if (!confirm('Delete this tip?')) return
		// In a real app, you'd call the API here
		setTips((prev) => prev.filter((t) => t.id !== tip.id))
	}

	const filteredTips = selectedCategory 
		? sorted.filter(tip => tip.category === selectedCategory)
		: sorted

	return (
		<div className="relative min-h-screen">
			{/* Floating decorative elements */}
			<div className="absolute inset-0 overflow-hidden pointer-events-none">
				<div className="absolute -top-40 -right-40 w-80 h-80 bg-gradient-to-br from-green-200/20 to-emerald-200/20 rounded-full blur-3xl"></div>
				<div className="absolute -bottom-40 -left-40 w-80 h-80 bg-gradient-to-tr from-blue-200/20 to-cyan-200/20 rounded-full blur-3xl"></div>
			</div>

			<div className="relative z-10 mx-auto max-w-6xl p-4">
				<header className="flex items-center justify-between mb-8">
					<div className="card p-6">
						<h2 className="text-3xl font-bold gradient-text mb-2">Health Tips Dashboard</h2>
						<p className="text-gray-600">Manage and organize your health content</p>
					</div>
					<div className="flex items-center gap-4">
						<span className="text-sm text-gray-600 bg-white/80 px-4 py-2 rounded-full">{user?.email}</span>
						<button className="btn-secondary hover:bg-gray-100 transition-colors duration-200" onClick={() => signOut()}>Logout</button>
					</div>
				</header>

				<section className="card p-8 mb-8">
					<h3 className="text-2xl font-bold mb-6 gradient-text">Add New Health Tip</h3>
					<AddTipForm 
						categories={categories}
						onCreated={(t) => setTips((prev) => [t, ...prev])} 
					/>
				</section>

				<section className="card p-8">
					<div className="flex items-center justify-between mb-6">
						<h3 className="text-2xl font-bold gradient-text">All Health Tips</h3>
						<div className="flex items-center gap-4">
							<select
								value={selectedCategory}
								onChange={(e) => setSelectedCategory(e.target.value)}
								className="input text-sm max-w-xs"
							>
								<option value="">All Categories</option>
								{categories.map((category) => (
									<option key={category.id} value={category.id}>
										{category.icon} {category.name}
									</option>
								))}
							</select>
							{selectedCategory && (
								<button
									onClick={() => setSelectedCategory('')}
									className="text-sm text-gray-500 hover:text-gray-700 underline hover:no-underline transition-colors"
								>
									Clear filter
								</button>
							)}
						</div>
					</div>

					{loading && (
						<div className="text-center py-12">
							<div className="inline-block animate-spin rounded-full h-12 w-12 border-b-4 border-brand mb-4"></div>
							<p className="text-xl text-gray-600 font-medium">Loading health tips...</p>
						</div>
					)}

					{error && (
						<div className="text-center py-12">
							<div className="glass inline-block p-8 rounded-2xl">
								<div className="text-red-500 text-6xl mb-4">⚠️</div>
								<p className="text-red-600 text-xl font-medium">{error}</p>
							</div>
						</div>
					)}

					{!loading && !error && filteredTips.length === 0 && (
						<div className="text-center py-12">
							<div className="glass inline-block p-8 rounded-2xl">
								<div className="text-gray-400 text-6xl mb-4">📝</div>
								<p className="text-gray-600 text-xl font-medium mb-2">No health tips found</p>
								<p className="text-gray-500">
									{selectedCategory ? 'Try a different category or add some tips!' : 'Start by adding your first health tip!'}
								</p>
							</div>
						</div>
					)}

					{!loading && !error && filteredTips.length > 0 && (
						<div className="space-y-6">
							{filteredTips.map((t) => (
								<div key={t.id}>
									{editing?.id === t.id ? (
										<EditTipForm 
											tip={editing} 
											categories={categories}
											onUpdated={(u) => { 
												setEditing(null); 
												setTips((prev) => prev.map((x) => (x.id === u.id ? u : x))) 
											}} 
											onCancel={() => setEditing(null)} 
										/>
									) : (
										<TipCard 
											tip={t} 
											onEdit={(tip) => setEditing(tip)} 
											onDelete={handleDelete}
											showActions={true}
										/>
									)}
								</div>
							))}
						</div>
					)}
				</section>
			</div>
		</div>
	)
}
