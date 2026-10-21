// src/components/ui/EmptyState.jsx

const EmptyState = ({ icon = '—', title = 'No data', description, className = '' }) => (
  <div className={`flex flex-col items-center justify-center text-center py-12 px-4 ${className}`}>
    <div className="w-10 h-10 rounded-full border border-dashed border-slate-300 flex items-center justify-center text-faint text-sm mb-3">
      {icon}
    </div>
    <p className="text-sm font-medium text-ink">{title}</p>
    {description && <p className="mt-1 text-xs text-muted max-w-xs">{description}</p>}
  </div>
)

export default EmptyState
