// src/components/ui/DonutLegend.jsx
// Custom legend for donut charts: colored dot + bold label + "N (X%)" in muted regular weight.
// Renders every item passed in, including zero-value ones — filtering for the
// pie's own slice rendering happens upstream, not here.

// `variant="v2"` opts into the forest/ground redesign's legend styling
// (square swatch, "count · pct%") without touching the default look the
// not-yet-redesigned Quality Summary page still relies on.
const DonutLegend = ({ items, variant = 'default' }) => {
  const total = items.reduce((sum, d) => sum + d.value, 0)

  if (variant === 'v2') {
    return (
      <ul className="space-y-3">
        {items.map((d) => {
          const pct = total ? Math.round((d.value / total) * 100) : 0
          return (
            <li key={d.name} className="flex items-center justify-between gap-3 text-sm">
              <span className="flex items-center gap-2 min-w-0">
                <span className="w-3 h-3 rounded-sm shrink-0" style={{ background: d.color }} />
                <span className="font-semibold text-[#11231A] truncate">{d.name}</span>
              </span>
              <span className="text-[#5A6B5F] tabular-nums shrink-0">
                {d.value} · {pct}%
              </span>
            </li>
          )
        })}
      </ul>
    )
  }

  return (
    <ul className="space-y-2">
      {items.map((d) => {
        const pct = total ? Math.round((d.value / total) * 100) : 0
        return (
          <li key={d.name} className="flex items-center justify-between gap-3 text-sm">
            <span className="flex items-center gap-2 min-w-0">
              <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ background: d.color }} />
              <span className="font-semibold text-ink truncate">{d.name}</span>
            </span>
            <span className="text-muted tabular-nums shrink-0">
              {d.value} ({pct}%)
            </span>
          </li>
        )
      })}
    </ul>
  )
}

export default DonutLegend
