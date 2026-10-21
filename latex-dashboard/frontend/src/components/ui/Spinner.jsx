// src/components/ui/Spinner.jsx

const SIZES = { sm: 'w-4 h-4 border-2', md: 'w-8 h-8 border-[3px]', lg: 'w-12 h-12 border-4' }

const Spinner = ({ size = 'md', label, className = '' }) => (
  <div className={`flex flex-col items-center justify-center gap-3 ${className}`}>
    <div
      className={`${SIZES[size]} rounded-full border-slate-200 border-t-brand animate-spin`}
    />
    {label && (
      <p className="text-xs font-medium text-muted">{label}</p>
    )}
  </div>
)

export default Spinner
