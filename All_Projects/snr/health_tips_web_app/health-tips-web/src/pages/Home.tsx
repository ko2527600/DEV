import { useEffect, useState } from 'react'
import { HealthTipsService, type HealthTip, type HealthCategory } from '../services/healthTipsService'
import TipCard from '../components/TipCard'
import RandomTipCard from '../components/RandomTipCard'

export default function Home() {
	const [tips, setTips] = useState<HealthTip[]>([])
	const [categories, setCategories] = useState<HealthCategory[]>([])
	const [loading, setLoading] = useState(true)
	const [error, setError] = useState<string | null>(null)
	const [selectedCategory, setSelectedCategory] = useState<string>('')
	const [searchQuery, setSearchQuery] = useState('')
	const [filteredTips, setFilteredTips] = useState<HealthTip[]>([])

	useEffect(() => {
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
		load()
	}, [])

	useEffect(() => {
		let filtered = tips

		// Filter by category
		if (selectedCategory) {
			filtered = filtered.filter(tip => tip.category === selectedCategory)
		}

		// Filter by search query
		if (searchQuery.trim()) {
			filtered = filtered.filter(tip => 
				tip.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
				tip.content.toLowerCase().includes(searchQuery.toLowerCase()) ||
				tip.tags.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase()))
			)
		}

		setFilteredTips(filtered)
	}, [tips, selectedCategory, searchQuery])

	const handleCategoryChange = (categoryId: string) => {
		setSelectedCategory(categoryId === selectedCategory ? '' : categoryId)
	}

	const handleSearch = (query: string) => {
		setSearchQuery(query)
	}

	const clearFilters = () => {
		setSelectedCategory('')
		setSearchQuery('')
	}

	return (
		<div className="relative min-h-screen">
			{/* Floating decorative elements */}
			<div className="absolute inset-0 overflow-hidden pointer-events-none">
				<div className="absolute -top-40 -right-40 w-80 h-80 bg-gradient-to-br from-blue-200/20 to-purple-200/20 rounded-full blur-3xl"></div>
				<div className="absolute -bottom-40 -left-40 w-80 h-80 bg-gradient-to-tr from-green-200/20 to-blue-200/20 rounded-full blur-3xl"></div>
				<div className="absolute top-1/2 left-1/4 w-32 h-32 bg-gradient-to-r from-yellow-200/30 to-orange-200/30 rounded-full blur-2xl"></div>
			</div>

			<div className="relative z-10 mx-auto max-w-6xl p-4">
				{/* Hero Section */}
				<div className="text-center mb-12">
					<div className="card p-8 mb-8">
						<h1 className="text-5xl font-bold gradient-text mb-6">
							Daily Health Tips for a Better Life
						</h1>
						<p className="text-xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
							Discover evidence-based health advice to improve your nutrition, fitness, mental health, and overall well-being.
						</p>
					</div>
				</div>

				{/* Random Tip of the Day */}
				<div className="mb-12">
					<RandomTipCard />
				</div>

				{/* Search and Filters */}
				<div className="card p-8 mb-12">
					{/* Search Bar */}
					<div className="max-w-md mx-auto mb-6">
						<div className="relative">
							<input
								type="text"
								placeholder="Search health tips..."
								value={searchQuery}
								onChange={(e) => handleSearch(e.target.value)}
								className="search-input w-full pl-12 text-lg"
							/>
							<span className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-500 text-xl">
								🔍
							</span>
						</div>
					</div>

					{/* Category Filters */}
					<div className="flex flex-wrap justify-center gap-3 mb-6">
						{categories.map((category) => (
							<button
								key={category.id}
								onClick={() => handleCategoryChange(category.id)}
								className={`px-6 py-3 rounded-full text-sm font-semibold transition-all duration-300 transform hover:scale-105 border-2 ${
									selectedCategory === category.id
										? 'bg-gradient-to-r from-brand to-blue-600 text-white shadow-lg border-brand'
										: 'bg-white hover:bg-gray-50 text-gray-700 shadow-md hover:shadow-lg border-gray-200'
								}`}
							>
								<span className="mr-2 text-lg">{category.icon}</span>
								{category.name}
							</button>
						))}
					</div>

					{/* Clear Filters */}
					{(selectedCategory || searchQuery) && (
						<div className="text-center">
							<button
								onClick={clearFilters}
								className="text-sm text-gray-600 hover:text-brand underline hover:no-underline transition-colors duration-200 font-medium"
							>
								Clear all filters
							</button>
						</div>
					)}
				</div>

				{/* Results Summary */}
				{!loading && (
					<div className="text-center mb-8">
						<div className="glass inline-block px-6 py-3 rounded-full">
							<p className="text-gray-700 font-medium">
								Showing {filteredTips.length} of {tips.length} health tips
								{selectedCategory && ` in ${categories.find(c => c.id === selectedCategory)?.name}`}
								{searchQuery && ` matching "${searchQuery}"`}
							</p>
						</div>
					</div>
				)}

				{/* Loading State */}
				{loading && (
					<div className="text-center py-16">
						<div className="inline-block animate-spin rounded-full h-12 w-12 border-b-4 border-brand mb-4"></div>
						<p className="text-xl text-gray-600 font-medium">Loading health tips...</p>
					</div>
				)}

				{/* Error State */}
				{error && (
					<div className="text-center py-12">
						<div className="glass inline-block p-8 rounded-2xl">
							<div className="text-red-500 text-6xl mb-4">⚠️</div>
							<p className="text-red-600 text-xl font-medium">{error}</p>
						</div>
					</div>
				)}

				{/* No Results */}
				{!loading && !error && filteredTips.length === 0 && (
					<div className="text-center py-16">
						<div className="glass inline-block p-8 rounded-2xl">
							<div className="text-gray-400 text-6xl mb-4">🔍</div>
							<p className="text-gray-600 text-xl font-medium mb-2">No health tips found</p>
							<p className="text-gray-500">
								Try adjusting your search or category filters
							</p>
						</div>
					</div>
				)}

				{/* Health Tips Grid */}
				{!loading && !error && filteredTips.length > 0 && (
					<div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
						{filteredTips.map((tip) => (
							<TipCard key={tip.id} tip={tip} showActions={false} />
						))}
					</div>
				)}
			</div>
		</div>
	)
}
