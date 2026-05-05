// src/components/shared/GradeBadge.jsx

import { getGradeBadgeColor, getGradeIcon,
         getGradeLabel, getGradeDescription,
         getGradeColor }                   from '../../utils/gradeHelper'

const GradeBadge = ({
  grade    = 'A',
  size     = 'md',     // 'xs' | 'sm' | 'md' | 'lg'
  showIcon = true,
  showDesc = false,
  pulse    = false,
}) => {

  // ── Size config ─────────────────────────────────────────────────────────────
  const sizes = {
    xs: 'text-xs px-1.5 py-0.5 rounded-md',
    sm: 'text-xs px-2   py-1   rounded-lg',
    md: 'text-sm px-3   py-1.5 rounded-lg',
    lg: 'text-base px-4 py-2   rounded-xl font-bold',
  }

  const sz = sizes[size] || sizes.md

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="inline-flex flex-col items-center gap-1">

      {/* ── Badge ─────────────────────────────────────────────────────────── */}
      <div className="relative inline-flex items-center">

        {/* Pulse ring for Grade C */}
        {pulse && grade === 'C' && (
          <span
            className="absolute inset-0 rounded-lg animate-ping opacity-30"
            style={{ backgroundColor: getGradeColor(grade) }}
          />
        )}

        <span
          className={`inline-flex items-center gap-1.5
                      font-semibold ${sz}
                      ${getGradeBadgeColor(grade)}`}
        >
          {/* Icon */}
          {showIcon && (
            <span>{getGradeIcon(grade)}</span>
          )}

          {/* Grade text */}
          <span>Grade {grade}</span>
        </span>
      </div>

      {/* ── Description ───────────────────────────────────────────────────── */}
      {showDesc && (
        <p
          className="text-xs text-center"
          style={{ color: getGradeColor(grade) }}
        >
          {getGradeDescription(grade)}
        </p>
      )}

    </div>
  )
}

export default GradeBadge