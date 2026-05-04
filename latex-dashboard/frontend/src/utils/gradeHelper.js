// src/utils/gradeHelper.js

// ── Grade from VFA value ──────────────────────────────────────────────────────
export const getGrade = (vfa) => {
  if (vfa < 0.05)  return 'A'
  if (vfa < 0.08)  return 'B'
  return 'C'
}

// ── Grade color (hex) ─────────────────────────────────────────────────────────
export const getGradeColor = (grade) => {
  if (grade === 'A') return '#1F6B38'
  if (grade === 'B') return '#C9A84C'
  return '#C00000'
}

// ── Grade background + border (Tailwind) ──────────────────────────────────────
export const getGradeBg = (grade) => {
  if (grade === 'A') return 'bg-green-50  border-green-500'
  if (grade === 'B') return 'bg-yellow-50 border-yellow-500'
  return 'bg-red-50 border-red-600'
}

// ── Grade text color (Tailwind) ───────────────────────────────────────────────
export const getGradeTextColor = (grade) => {
  if (grade === 'A') return 'text-green-700'
  if (grade === 'B') return 'text-yellow-600'
  return 'text-red-700'
}

// ── Grade badge color (Tailwind) ──────────────────────────────────────────────
export const getGradeBadgeColor = (grade) => {
  if (grade === 'A') return 'bg-green-100  text-green-800  border border-green-400'
  if (grade === 'B') return 'bg-yellow-100 text-yellow-800 border border-yellow-400'
  return 'bg-red-100 text-red-800 border border-red-400'
}

// ── Grade border color (Tailwind) ─────────────────────────────────────────────
export const getGradeBorder = (grade) => {
  if (grade === 'A') return 'border-green-500'
  if (grade === 'B') return 'border-yellow-500'
  return 'border-red-600'
}

// ── Grade icon / emoji ────────────────────────────────────────────────────────
export const getGradeIcon = (grade) => {
  if (grade === 'A') return '✅'
  if (grade === 'B') return '⚠️'
  return '❌'
}

// ── Grade label (full) ────────────────────────────────────────────────────────
export const getGradeLabel = (grade) => {
  if (grade === 'A') return 'Grade A — Fresh (High Quality)'
  if (grade === 'B') return 'Grade B — Acceptable'
  return 'Grade C — Degraded (Poor Quality)'
}

// ── Grade short label ─────────────────────────────────────────────────────────
export const getGradeShortLabel = (grade) => {
  if (grade === 'A') return 'Fresh'
  if (grade === 'B') return 'Acceptable'
  return 'Degraded'
}

// ── Grade description ─────────────────────────────────────────────────────────
export const getGradeDescription = (grade) => {
  if (grade === 'A') return 'VFA < 0.05 — Accept immediately'
  if (grade === 'B') return 'VFA 0.05–0.08 — Accept with caution'
  return 'VFA ≥ 0.08 — Reject or re-test'
}

// ── VFA status message ────────────────────────────────────────────────────────
export const getVFAStatus = (vfa) => {
  if (vfa < 0.03)  return 'Excellent — Very fresh latex'
  if (vfa < 0.05)  return 'Good — Fresh latex'
  if (vfa < 0.065) return 'Moderate — Slightly fermented'
  if (vfa < 0.08)  return 'Warning — Approaching Grade C'
  return 'Critical — Heavily degraded'
}

// ── VFA status color ──────────────────────────────────────────────────────────
export const getVFAStatusColor = (vfa) => {
  if (vfa < 0.03)  return '#0A5C2E'
  if (vfa < 0.05)  return '#1F6B38'
  if (vfa < 0.065) return '#C9A84C'
  if (vfa < 0.08)  return '#E05000'
  return '#C00000'
}

// ── Grade ring color (for gauge) ──────────────────────────────────────────────
export const getGradeRingColor = (grade) => {
  if (grade === 'A') return '#1F6B38'
  if (grade === 'B') return '#C9A84C'
  return '#C00000'
}

// ── Is alert grade ────────────────────────────────────────────────────────────
export const isAlertGrade = (grade) => grade === 'C'

// ── Grade sort order ──────────────────────────────────────────────────────────
export const getGradeSortOrder = (grade) => {
  if (grade === 'A') return 1
  if (grade === 'B') return 2
  return 3
}

// ── Full grade info object ────────────────────────────────────────────────────
export const getGradeInfo = (grade) => ({
  grade,
  color:       getGradeColor(grade),
  bg:          getGradeBg(grade),
  textColor:   getGradeTextColor(grade),
  badgeColor:  getGradeBadgeColor(grade),
  border:      getGradeBorder(grade),
  icon:        getGradeIcon(grade),
  label:       getGradeLabel(grade),
  shortLabel:  getGradeShortLabel(grade),
  description: getGradeDescription(grade),
  isAlert:     isAlertGrade(grade),
})