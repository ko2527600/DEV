type Props = {
	variant?: 'info' | 'success' | 'warning' | 'error'
	children: React.ReactNode
}

const variants: Record<NonNullable<Props['variant']>, string> = {
	info: 'bg-blue-50 text-blue-800 ring-blue-200',
	success: 'bg-green-50 text-green-800 ring-green-200',
	warning: 'bg-amber-50 text-amber-900 ring-amber-200',
	error: 'bg-red-50 text-red-800 ring-red-200',
}

export default function Alert({ variant = 'info', children }: Props) {
	return (
		<div className={`rounded-md ring-1 px-3 py-2 text-sm ${variants[variant]}`}>{children}</div>
	)
}
