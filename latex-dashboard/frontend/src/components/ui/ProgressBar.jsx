// src/components/ui/ProgressBar.jsx
//
// Simple rounded progress track for the forest/ground redesign (district
// volume rows, top-farmer rows). Pure presentation — value/max are computed
// by the caller from real data.

const ProgressBar = ({ value = 0, max = 100, height = 14, color = '#22B14C', trackColor = '#EEF3EA', className = '' }) => {
  const pct = max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0
  return (
    <div className={`w-full rounded-full overflow-hidden ${className}`} style={{ height, background: trackColor }}>
      <div
        className="h-full rounded-full transition-all duration-500"
        style={{ width: `${pct}%`, background: color }}
      />
    </div>
  )
}

export default ProgressBar
