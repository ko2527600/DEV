import { useState } from 'react'
import { type HealthTip, type HealthCategory } from '../services/healthTipsService'
import Alert from './ui/Alert'

type Props = {
	categories: HealthCategory[]
	onCreated?: (tip: HealthTip) => void
}

export default function AddTipForm({ categories, onCreated }: Props) {
	const [title, setTitle] = useState('')
	const [content, setContent] = useState('')
	const [category, setCategory] = useState('')
	const [tags, setTags] = useState('')
	const [submitting, setSubmitting] = useState(false)
	const [error, setError] = useState<string | null>(null)

	async function handleSubmit(e: React.FormEvent) {
		e.preventDefault()
		if (!category) {
			setError('Please select a category')
			return
		}
		
		setSubmitting(true)
		setError(null)
		
		try {
			// Create new tip with generated ID and timestamp
			const newTip: HealthTip = {
				id: Date.now(), // Simple ID generation for demo
				title,
				content,
				category,
				tags: tags.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0),
				created_at: new Date().toISOString(),
				verified: false
			}
			
			if (onCreated) onCreated(newTip)
			
			// Reset form
			setTitle('')
			setContent('')
			setCategory('')
			setTags('')
		} catch (err) {
			setError('Failed to create health tip')
		} finally {
			setSubmitting(false)
		}
	}

	return (
		<form onSubmit={handleSubmit} className="space-y-4">
			<div className="grid grid-cols-1 md:grid-cols-2 gap-4">
				<label className="block">
					<span className="block text-sm font-medium text-gray-700 mb-1">Title *</span>
					<input 
						className="input" 
						value={title} 
						onChange={(e) => setTitle(e.target.value)} 
						required 
						placeholder="Enter health tip title"
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
						<option value="">Select a category</option>
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
					rows={5}
					placeholder="Enter detailed health tip content..."
				/>
			</label>

			<label className="block">
				<span className="block text-sm font-medium text-gray-700 mb-1">Tags</span>
				<input 
					className="input" 
					value={tags} 
					onChange={(e) => setTags(e.target.value)} 
					placeholder="Enter tags separated by commas (e.g., nutrition, wellness, tips)"
				/>
				<p className="text-xs text-gray-500 mt-1">Tags help users find related health tips</p>
			</label>

			{error && <Alert variant="error">{error}</Alert>}
			
			<button 
				type="submit" 
				className="btn" 
				disabled={submitting || !title || !content || !category}
			>
				{submitting ? 'Creating...' : 'Create Health Tip'}
			</button>
		</form>
	)
}
