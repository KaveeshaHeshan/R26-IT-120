// src/components/ui/ChartTooltip.jsx
// Consistent Recharts tooltip surface.

const ChartTooltip = ({ active, payload, label, rows }) => {
  if (!active || !payload?.length) return null
  const lines = rows ? rows(payload) : payload.map((p) => ({ label: p.name, value: p.value, color: p.color }))
  return (
    <div className="rounded-lg border border-border bg-surface shadow-lg px-3 py-2 text-xs">
      {label != null && <p className="font-medium text-ink mb-1">{label}</p>}
      {lines.map((l, i) => (
        <div key={i} className="flex items-center justify-between gap-4">
          <span className="flex items-center gap-1.5 text-muted">
            {l.color && <span className="w-2 h-2 rounded-full" style={{ background: l.color }} />}
            {l.label}
          </span>
          <span className="font-semibold text-ink tabular-nums">{l.value}</span>
        </div>
      ))}
    </div>
  )
}

export default ChartTooltip
