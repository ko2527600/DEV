import type { HealthTip } from '../services/healthTipsService'

type Props = {
	tip: HealthTip
	onEdit?: (tip: HealthTip) => void
	onDelete?: (tip: HealthTip) => void
	showActions?: boolean
}

export default function TipCard({ tip, onEdit, onDelete, showActions = false }: Props) {
	const getCategoryIcon = (category: string) => {
		const icons: Record<string, string> = {
			nutrition: '🥗',
			exercise: '💪',
			'mental-health': '🧠',
			sleep: '😴',
			prevention: '🛡️',
			hydration: '💧'
		}
		return icons[category] || '💡'
	}

	const getCategoryColor = (category: string) => {
		const colors: Record<string, string> = {
			nutrition: 'bg-gradient-to-r from-green-100 to-emerald-100 text-green-800 border-green-300 shadow-sm',
			exercise: 'bg-gradient-to-r from-blue-100 to-cyan-100 text-blue-800 border-blue-300 shadow-sm',
			'mental-health': 'bg-gradient-to-r from-purple-100 to-violet-100 text-purple-800 border-purple-300 shadow-sm',
			sleep: 'bg-gradient-to-r from-indigo-100 to-blue-100 text-indigo-800 border-indigo-300 shadow-sm',
			prevention: 'bg-gradient-to-r from-red-100 to-pink-100 text-red-800 border-red-300 shadow-sm',
			hydration: 'bg-gradient-to-r from-cyan-100 to-blue-100 text-cyan-800 border-cyan-300 shadow-sm'
		}
		return colors[category] || 'bg-gradient-to-r from-gray-100 to-slate-100 text-gray-800 border-gray-300 shadow-sm'
	}

	return (
		<article className="card p-6 hover:shadow-2xl hover:shadow-gray-300/50 transition-all duration-300 transform hover:-translate-y-1 group">
			<div className="flex items-start justify-between mb-4">
				<div className="flex items-center gap-3">
					<span className="text-3xl group-hover:scale-110 transition-transform duration-300">{getCategoryIcon(tip.category)}</span>
					<span className={`px-3 py-1.5 rounded-full text-xs font-semibold border ${getCategoryColor(tip.category)}`}>
						{tip.category.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase())}
					</span>
					{tip.verified && (
						<span className="text-green-700 bg-green-100 p-1.5 rounded-full border border-green-200 shadow-sm" title="Verified health tip">
							✓
						</span>
					)}
				</div>
				<small className="text-gray-600 text-sm bg-gray-100 px-3 py-1.5 rounded-full font-medium border border-gray-200">
					{new Date(tip.created_at).toLocaleDateString()}
				</small>
			</div>
			
			<h3 className="text-xl font-bold mb-3 text-gray-900 group-hover:text-brand transition-colors duration-300 leading-tight">{tip.title}</h3>
			
			<p className="text-gray-700 leading-relaxed mb-4 whitespace-pre-wrap font-medium">{tip.content}</p>
			
			{tip.tags && tip.tags.length > 0 && (
				<div className="flex flex-wrap gap-2 mb-4">
					{tip.tags.map((tag, index) => (
						<span 
							key={index} 
							className="px-3 py-1 bg-gradient-to-r from-gray-100 to-gray-200 text-gray-700 text-xs rounded-full font-semibold border border-gray-300 shadow-sm"
						>
							#{tag}
						</span>
					))}
				</div>
			)}

			{showActions && (onEdit || onDelete) && (
				<div className="flex gap-2 pt-4 border-t border-gray-100">
					{onEdit && (
						<button 
							className="btn-secondary text-sm hover:bg-gray-100 transition-colors duration-200" 
							onClick={() => onEdit(tip)}
						>
							Edit
						</button>
					)}
					{onDelete && (
						<button 
							className="btn text-sm bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 transition-all duration-200" 
							onClick={() => onDelete(tip)}
						>
							Delete
						</button>
					)}
				</div>
			)}
		</article>
	)
}
