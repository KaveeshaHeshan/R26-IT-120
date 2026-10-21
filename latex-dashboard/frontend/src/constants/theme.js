// src/constants/theme.js
//
// Single source of truth for colors used outside Tailwind classes — mainly
// Recharts, which needs literal hex values. Tailwind utility tokens live in
// src/index.css (@theme block). Keep the two in sync.

// ── Core palette ─────────────────────────────────────────────────────────────
export const COLORS = {
  bg:        '#f8fafc', // slate-50   — app background
  surface:   '#ffffff', // white      — cards
  border:    '#e2e8f0', // slate-200
  ink:       '#0f172a', // slate-900  — primary text
  muted:     '#64748b', // slate-500  — secondary text
  faint:     '#94a3b8', // slate-400  — axis / tick text

  brand:      '#0bb524', // brand green — thin accent only (active nav, primary series)
  brandSoft:  'rgba(11, 181, 36, 0.10)',
  brandDark:  '#07751a', // hover/pressed states on brand-filled buttons
}

// ── Grade semantics (the ONLY place green is a fill) ──────────────────────────
export const GRADE_COLORS = {
  A: '#059669', // emerald-600
  B: '#d97706', // amber-600
  C: '#dc2626', // red-600
}

export const getGradeColor = (grade) => GRADE_COLORS[grade] || COLORS.muted

// ── Categorical palette for charts (district bars, misc series) ───────────────
// Neutral-forward; green reserved for semantics above.
export const CHART_SERIES = [
  '#0bb524', // brand green (primary)
  '#334155', // slate-700
  '#0e7490', // cyan-700
  '#7c3aed', // violet-600
  '#b45309', // amber-700
  '#be123c', // rose-700
  '#1d4ed8', // blue-700
  '#4d7c0f', // lime-700
]

// ── Shared Recharts styling ──────────────────────────────────────────────────
export const AXIS_TICK = { fontSize: 11, fill: COLORS.faint, fontWeight: 600 }
export const GRID_STROKE = 'rgba(15, 23, 42, 0.06)'
