// src/components/ui/StatCard.jsx

const TONES = {
  neutral: 'text-ink',
  brand:   'text-brand',
  a:       'text-grade-a',
  b:       'text-grade-b',
  c:       'text-grade-c',
}

// `variant` opts a card into the v2 (forest/ground) redesign without touching
// the default look relied on elsewhere (DailySummary, etc. — until their own
// redesign phase runs). `iconChip` is the small tinted/glow icon badge:
//   - variant="kpi":  { icon, bg, color }
//   - variant="hero": a bare icon node (styling is fixed — white/16 + glow)
const StatCard = ({ label, value, sub, icon, tone = 'neutral', variant = 'default', unit, iconChip, kpiTone = 'neutral', valueColor }) => {
  if (variant === 'hero') {
    return (
      <div className="h-full rounded-[20px] bg-forest-900 p-[22px] flex flex-col">
        <div className="flex items-start justify-between gap-2">
          <span className="text-xs font-bold uppercase tracking-[0.08em] text-[#9DBBA8]">{label}</span>
          {iconChip && (
            <span className="w-9 h-9 rounded-xl bg-white/16 text-glow flex items-center justify-center shrink-0">
              {iconChip}
            </span>
          )}
        </div>
        <div className="mt-2 font-display font-bold leading-[1.1] text-glow tabular-nums">
          <span className="text-[44px]">{value}</span>
          {unit && <span className="text-2xl ml-1">{unit}</span>}
        </div>
        {sub && <p className="mt-1 text-sm text-[#9DBBA8]">{sub}</p>}
      </div>
    )
  }

  if (variant === 'kpi') {
    // kpiTone="danger" tints the whole card (e.g. the "Grade C" critical KPI);
    // valueColor overrides just the value's color on an otherwise normal card
    // (e.g. Avg VFA in brand-700, Rejection rate in red) — both additive,
    // default kpi usage (Overview) is unaffected.
    const danger = kpiTone === 'danger'
    return (
      <div
        className={`h-full rounded-[20px] border p-[22px] flex flex-col ${
          danger ? 'bg-[#FBEDEA] border-[#F2CFC8]' : 'bg-white border-line'
        }`}
      >
        <div className="flex items-start justify-between gap-2">
          <span className={`text-xs font-bold uppercase tracking-[0.08em] ${danger ? 'text-[#8E2A1D]' : 'text-[#5A6B5F]'}`}>
            {label}
          </span>
          {iconChip && (
            <span
              className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
              style={{ background: iconChip.bg, color: iconChip.color }}
            >
              {iconChip.icon}
            </span>
          )}
        </div>
        <div
          className="mt-2 font-display font-bold leading-[1.1] tabular-nums"
          style={{ color: valueColor || (danger ? '#B42318' : '#11231A') }}
        >
          <span className="text-[44px]">{value}</span>
          {unit && <span className="text-2xl ml-1">{unit}</span>}
        </div>
        {sub && <p className={`mt-1 text-sm ${danger ? 'text-[#8E2A1D]' : 'text-[#5A6B5F]'}`}>{sub}</p>}
      </div>
    )
  }

  return (
    <div className="rounded-xl border border-border bg-surface shadow-sm p-4">
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold uppercase tracking-wide text-muted">{label}</span>
        {icon && <span className="text-base text-faint">{icon}</span>}
      </div>
      <div className={`mt-2 text-2xl font-bold tracking-tight tabular-nums ${TONES[tone] || TONES.neutral}`}>
        {value}
      </div>
      {sub && <p className="mt-1 text-xs text-muted">{sub}</p>}
    </div>
  )
}

export default StatCard
