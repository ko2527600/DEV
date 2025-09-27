import { useState, useEffect } from 'react'
import { HealthTipsService, type HealthTip } from '../services/healthTipsService'

export default function RandomTipCard() {
	const [tip, setTip] = useState<HealthTip | null>(null)
	const [loading, setLoading] = useState(true)

	useEffect(() => {
		loadRandomTip()
	}, [])

	async function loadRandomTip() {
		setLoading(true)
		try {
			const randomTip = await HealthTipsService.getRandomTip()
			setTip(randomTip)
		} catch (err) {
			console.error('Failed to load random tip:', err)
		} finally {
			setLoading(false)
		}
	}

	if (loading) {
		return (
			<div className="bg-gradient-to-br from-brand to-brand-dark text-white p-8 text-center rounded-2xl shadow-2xl shadow-brand/20">
				<div className="inline-block animate-spin rounded-full h-12 w-12 border-b-4 border-white mb-6"></div>
				<p className="text-xl font-medium text-white">Loading your daily tip...</p>
			</div>
		)
	}

	if (!tip) {
		return null
	}

	return (
		<div className="bg-gradient-to-br from-brand via-brand-dark to-green-800 text-white p-8 rounded-2xl shadow-2xl shadow-brand/20 relative overflow-hidden">
			{/* Background decorative elements */}
			<div className="absolute inset-0 overflow-hidden pointer-events-none">
				<div className="absolute -top-20 -right-20 w-40 h-40 bg-white/10 rounded-full blur-xl"></div>
				<div className="absolute -bottom-20 -left-20 w-40 h-40 bg-white/10 rounded-full blur-xl"></div>
			</div>
			
			<div className="relative z-10">
				<div className="flex items-center justify-between mb-6">
					<div className="flex items-center gap-3">
						<span className="text-3xl animate-pulse">🎯</span>
						<h3 className="text-2xl font-bold text-white drop-shadow-sm">Tip of the Day</h3>
					</div>
					<button
						onClick={loadRandomTip}
						className="text-white/90 hover:text-white transition-all duration-300 hover:scale-110 p-2 rounded-full hover:bg-white/20"
						title="Get another random tip"
					>
						🔄
					</button>
				</div>
				
				<h4 className="text-2xl font-bold mb-4 text-white drop-shadow-sm leading-tight">{tip.title}</h4>
				<p className="text-white/95 leading-relaxed mb-6 text-lg drop-shadow-sm font-medium">{tip.content}</p>
				
				<div className="flex items-center justify-between">
					<div className="flex items-center gap-3">
						<span className="text-sm text-white/90 bg-white/20 px-3 py-1.5 rounded-full font-medium">
							Category: {tip.category.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
						</span>
						{tip.verified && (
							<span className="text-green-200 bg-green-900/50 p-2 rounded-full font-semibold" title="Verified health tip">
								✓ Verified
							</span>
						)}
					</div>
					<button
						onClick={loadRandomTip}
						className="bg-white/25 hover:bg-white/35 text-white px-6 py-3 rounded-xl text-sm font-semibold transition-all duration-300 hover:scale-105 hover:shadow-lg border border-white/30"
					>
						New Tip
					</button>
				</div>
			</div>
		</div>
	)
}
