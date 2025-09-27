import { useState, useEffect } from 'react'
import { type HealthTip, type HealthCategory } from '../services/healthTipsService'
import Alert from './ui/Alert'

type Props = {
	tip: HealthTip
	categories: HealthCategory[]
	onUpdated: (tip: HealthTip) => void
	onCancel: () => void
}

export default function EditTipForm({ tip, categories, onUpdated, onCancel }: Props) {
	const [title, setTitle] = useState(tip.title)
	const [content, setContent] = useState(tip.content)
	const [category, setCategory] = useState(tip.category)
	const [tags, setTags] = useState(tip.tags.join(', '))
	const [submitting, setSubmitting] = useState(false)
	const [error, setError] = useState<string | null>(null)

	useEffect(() => {
		setTitle(tip.title)
		setContent(tip.content)
		setCategory(tip.category)
		setTags(tip.tags.join(', '))
	}, [tip])

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault()
		if (!category) {
			setError('Please select a category')
			return
		}
		
		setSubmitting(true)
		setError(null)
		
		try {
			const updatedTip: HealthTip = {
				...tip,
				title,
				content,
				category,
				tags: tags.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0)
			}
			
			onUpdated(updatedTip)
		} catch (err) {
			setError('Failed to update health tip')
		} finally {
			setSubmitting(false)
		}
	}

	return (
		<div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
			<h4 className="font-medium text-gray-900 mb-4">Edit Health Tip</h4>
			
			<form onSubmit={handleSubmit} className="space-y-4">
				<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
					<label className="block">
						<span className="block text-sm font-medium text-gray-700 mb-1">Title *</span>
						<input 
							className="input" 
							value={title} 
							onChange={(e) => setTitle(e.target.value)} 
							required 
						/>
					</label>
					
					<label className="block">
						<span className="block text-sm font-medium text-gray-700 mb-1">Category *</span>
						<select 
							className="input" 
							value={category} 
							onChange={(e) => setCategory(e.target.value)}
							required
						>
							{categories.map((cat) => (
								<option key={cat.id} value={cat.id}>
									{cat.icon} {cat.name}
								</option>
							))}
						</select>
					</label>
				</div>

				<label className="block">
					<span className="block text-sm font-medium text-gray-700 mb-1">Content *</span>
					<textarea 
						className="textarea" 
						value={content} 
						onChange={(e) => setContent(e.target.value)} 
						required 
						rows={4}
					/>
				</label>

				<label className="block">
					<span className="block text-sm font-medium text-gray-700 mb-1">Tags</span>
					<input 
						className="input" 
						value={tags} 
						onChange={(e) => setTags(e.target.value)} 
						placeholder="Enter tags separated by commas"
					/>
				</label>

				{error && <Alert variant="error">{error}</Alert>}
				
				<div className="flex gap-2">
					<button 
						type="submit" 
						className="btn" 
						disabled={submitting || !title || !content || !category}
					>
						{submitting ? 'Updating...' : 'Update Tip'}
					</button>
					<button 
						type="button" 
						className="btn-secondary" 
						onClick={onCancel}
						disabled={submitting}
					>
						Cancel
					</button>
				</div>
			</form>
		</div>
	)
}
