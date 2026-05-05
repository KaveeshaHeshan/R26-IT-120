// src/components/shared/SensorCard.jsx

const SensorCard = ({
  label    = '',
  value    = 0,
  unit     = '',
  icon     = '📡',
  min      = 0,
  max      = 100,
  normalMin = null,
  normalMax = null,
  decimals  = 2,
  color     = '#1F3864',
  bg        = 'bg-blue-50',
}) => {

  // ── Progress percentage ─────────────────────────────────────────────────────
  const percent = Math.min(Math.max(
    ((value - min) / (max - min)) * 100, 0
  ), 100)

  // ── Is value in normal range ────────────────────────────────────────────────
  const isNormal = normalMin !== null && normalMax !== null
    ? value >= normalMin && value <= normalMax
    : true

  // ── Status color ────────────────────────────────────────────────────────────
  const statusColor = isNormal ? '#1F6B38' : '#C00000'
  const statusLabel = isNormal ? 'Normal' : 'Out of range'
  const statusIcon  = isNormal ? '✅' : '⚠️'

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className={`${bg} rounded-xl shadow-sm p-5
                     border border-gray-100`}>

      {/* ── Header ──────────────────────────────────────────────────────────── */}
      <div className="flex items-center justify-between mb-3">
        <span className="text-gray-500 text-sm font-medium">
          {label}
        </span>
        <span className="text-2xl">{icon}</span>
      </div>

      {/* ── Value ───────────────────────────────────────────────────────────── */}
      <div className="flex items-end gap-1 mb-1">
        <p
          className="text-4xl font-bold leading-none"
          style={{ color }}
        >
          {typeof value === 'number'
            ? value.toFixed(decimals)
            : value}
        </p>
        {unit && (
          <span className="text-gray-400 text-sm mb-0.5">
            {unit}
          </span>
        )}
      </div>

      {/* ── Normal range label ───────────────────────────────────────────────── */}
      {normalMin !== null && normalMax !== null && (
        <p className="text-gray-400 text-xs mb-3">
          Normal: {normalMin} — {normalMax} {unit}
        </p>
      )}

      {/* ── Progress bar ────────────────────────────────────────────────────── */}
      <div className="bg-gray-200 rounded-full h-2 mb-2">
        <div
          className="h-2 rounded-full transition-all duration-700"
          style={{
            width:           `${percent}%`,
            backgroundColor:  color,
          }}
        />
      </div>

      {/* ── Min / Max labels ────────────────────────────────────────────────── */}
      <div className="flex justify-between text-xs text-gray-400 mb-3">
        <span>{min}</span>
        <span>{max} {unit}</span>
      </div>

      {/* ── Status ──────────────────────────────────────────────────────────── */}
      {normalMin !== null && normalMax !== null && (
        <div
          className="flex items-center gap-1.5 px-2.5 py-1.5
                     rounded-lg w-fit"
          style={{
            backgroundColor: statusColor + '15',
          }}
        >
          <span className="text-xs">{statusIcon}</span>
          <span
            className="text-xs font-medium"
            style={{ color: statusColor }}
          >
            {statusLabel}
          </span>
        </div>
      )}

    </div>
  )
}

export default SensorCard