// src/components/ui/Select.jsx
// Read-only filter control. Never used for data entry.

// `variant="v2"` opts into the forest/ground redesign's pill styling without
// touching the default look other (not-yet-redesigned) pages still use.
const Select = ({ label, value, onChange, options, className = '', variant = 'default' }) => {
  const renderOptions = () =>
    options.map((opt) => {
      const o = typeof opt === 'string' ? { value: opt, label: opt } : opt
      return (
        <option key={o.value} value={o.value}>
          {o.label}
        </option>
      )
    })

  if (variant === 'v2') {
    return (
      <label className={`inline-flex items-center gap-2 text-sm ${className}`}>
        {label && <span className="text-sm font-medium text-[#5A6B5F] whitespace-nowrap">{label}</span>}
        <select
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-[42px] rounded-xl border border-[#DDE4D8] bg-white px-3 text-sm font-medium text-[#11231A] focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition"
        >
          {renderOptions()}
        </select>
      </label>
    )
  }

  return (
    <label className={`inline-flex items-center gap-2 text-sm ${className}`}>
      {label && <span className="text-xs font-medium text-muted whitespace-nowrap">{label}</span>}
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="rounded-lg border border-border bg-surface px-3 py-2 text-sm text-ink focus:outline-none focus:ring-2 focus:ring-brand/20 focus:border-brand transition"
      >
        {renderOptions()}
      </select>
    </label>
  )
}

export default Select
