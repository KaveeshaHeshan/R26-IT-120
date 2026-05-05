// src/components/shared/VFAGauge.jsx

import { getGradeColor, getGradeBg,
         getGradeBadgeColor, getGradeIcon,
         getGradeLabel, getVFAStatus,
         getVFAStatusColor }               from '../../utils/gradeHelper'

const VFAGauge = ({
  vfa       = 0,
  grade     = 'A',
  size      = 'lg',    // 'sm' | 'md' | 'lg' | 'xl'
  showLabel = true,
  showStatus = true,
  animated  = true,
}) => {

  // ── Size config ─────────────────────────────────────────────────────────────
  const sizes = {
    sm: {
      vfaText:   'text-3xl',
      gradeText: 'text-base',
      badgePad:  'px-3 py-1',
      statusText:'text-xs',
      padding:   'p-4',
    },
    md: {
      vfaText:   'text-5xl',
      gradeText: 'text-xl',
      badgePad:  'px-4 py-1.5',
      statusText:'text-xs',
      padding:   'p-5',
    },
    lg: {
      vfaText:   'text-7xl',
      gradeText: 'text-2xl',
      badgePad:  'px-5 py-2',
      statusText:'text-sm',
      padding:   'p-6',
    },
    xl: {
      vfaText:   'text-8xl',
      gradeText: 'text-3xl',
      badgePad:  'px-6 py-2.5',
      statusText:'text-base',
      padding:   'p-8',
    },
  }

  const sz = sizes[size] || sizes.lg

  // ── VFA percentage for gauge bar (0-0.15 range) ──────────────────────────
  const vfaPercent = Math.min((vfa / 0.15) * 100, 100)

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className={`border-4 rounded-2xl text-center
                     ${getGradeBg(grade)} ${sz.padding}`}>

      {/* ── Live indicator ──────────────────────────────────────────────────── */}
      <div className="flex items-center justify-center gap-2 mb-3">
        <div
          className={`w-2 h-2 rounded-full
                      ${animated ? 'animate-pulse' : ''}`}
          style={{ backgroundColor: getGradeColor(grade) }}
        />
        <span className="text-gray-500 text-xs font-medium">
          Live VFA Prediction
        </span>
      </div>

      {/* ── VFA Value ───────────────────────────────────────────────────────── */}
      <div
        className={`${sz.vfaText} font-bold mb-2 tracking-tight`}
        style={{ color: getGradeColor(grade) }}
      >
        {vfa.toFixed(4)}
      </div>

      {/* ── Grade Badge ─────────────────────────────────────────────────────── */}
      <div className="flex items-center justify-center mb-3">
        <span
          className={`${sz.gradeText} font-bold ${sz.badgePad}
                      rounded-xl ${getGradeBadgeColor(grade)}`}
        >
          {getGradeIcon(grade)} Grade {grade}
        </span>
      </div>

      {/* ── VFA Gauge Bar ───────────────────────────────────────────────────── */}
      <div className="relative mb-3">
        {/* Background bar */}
        <div className="bg-gray-200 rounded-full h-3 mx-4">
          {/* Fill bar */}
          <div
            className="h-3 rounded-full transition-all duration-700"
            style={{
              width:           `${vfaPercent}%`,
              backgroundColor:  getGradeColor(grade),
            }}
          />
        </div>

        {/* Grade markers */}
        <div className="relative mx-4 mt-1">
          {/* Grade A/B boundary (0.05) */}
          <div
            className="absolute top-0 w-0.5 h-2 bg-[#C9A84C]"
            style={{ left: `${(0.05/0.15)*100}%` }}
          />
          {/* Grade B/C boundary (0.08) */}
          <div
            className="absolute top-0 w-0.5 h-2 bg-[#C00000]"
            style={{ left: `${(0.08/0.15)*100}%` }}
          />
        </div>

        {/* Scale labels */}
        <div className="flex justify-between mx-4 mt-3">
          <span className="text-xs text-gray-400">0.00</span>
          <span className="text-xs text-[#C9A84C] font-medium">
            0.05
          </span>
          <span className="text-xs text-[#C00000] font-medium">
            0.08
          </span>
          <span className="text-xs text-gray-400">0.15</span>
        </div>
      </div>

      {/* ── Grade Label ─────────────────────────────────────────────────────── */}
      {showLabel && (
        <p className="text-gray-500 text-xs mb-2">
          {getGradeLabel(grade)}
        </p>
      )}

      {/* ── VFA Status ──────────────────────────────────────────────────────── */}
      {showStatus && (
        <p
          className={`${sz.statusText} font-semibold`}
          style={{ color: getVFAStatusColor(vfa) }}
        >
          {getVFAStatus(vfa)}
        </p>
      )}

    </div>
  )
}

export default VFAGauge