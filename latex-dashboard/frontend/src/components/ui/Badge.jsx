// src/components/ui/Badge.jsx

const TONES = {
  neutral: 'bg-slate-100 text-slate-600 border-slate-200',
  success: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  warning: 'bg-amber-50 text-amber-700 border-amber-200',
  danger:  'bg-red-50 text-red-700 border-red-200',
  brand:   'bg-brand-soft text-brand border-transparent',
}

// `variant="v2"` opts into the forest/ground redesign's pill colours without
// touching the default look other (not-yet-redesigned) pages still use.
const TONES_V2 = {
  neutral: 'bg-[#F7FAF4] text-[#5A6B5F]',
  success: 'bg-[#E3F5E8] text-[#0B5E2D]',
  warning: 'bg-[#FBF0D5] text-[#7A4A06]',
  danger:  'bg-[#FBE4E0] text-[#8E2A1D]',
  brand:   'bg-[#E3F5E8] text-brand-700',
}

const Badge = ({ tone = 'neutral', children, className = '', variant = 'default' }) => {
  if (variant === 'v2') {
    return (
      <span
        className={`inline-flex items-center gap-1 rounded-full px-[11px] py-[5px] text-[13px] font-semibold whitespace-nowrap ${TONES_V2[tone] || TONES_V2.neutral} ${className}`}
      >
        {children}
      </span>
    )
  }

  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full border px-2 py-0.5 text-xs font-medium ${TONES[tone] || TONES.neutral} ${className}`}
    >
      {children}
    </span>
  )
}

export default Badge
