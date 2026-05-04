// src/utils/dateHelper.js

// ── Format time from ISO timestamp ───────────────────────────────────────────
export const formatTime = (timestamp) => {
  if (!timestamp) return '--:--:--'
  return timestamp.slice(11, 19)
}

// ── Format short time (HH:MM) ────────────────────────────────────────────────
export const formatShortTime = (timestamp) => {
  if (!timestamp) return '--:--'
  return timestamp.slice(11, 16)
}

// ── Format date from ISO timestamp ───────────────────────────────────────────
export const formatDate = (timestamp) => {
  if (!timestamp) return '----'
  return timestamp.slice(0, 10)
}

// ── Format date readable (April 25, 2026) ────────────────────────────────────
export const formatDateReadable = (timestamp) => {
  if (!timestamp) return '----'
  try {
    return new Date(timestamp).toLocaleDateString('en-US', {
      year:  'numeric',
      month: 'long',
      day:   'numeric',
    })
  } catch {
    return timestamp.slice(0, 10)
  }
}

// ── Format date + time readable ──────────────────────────────────────────────
export const formatDateTime = (timestamp) => {
  if (!timestamp) return '----'
  try {
    return new Date(timestamp).toLocaleString('en-US', {
      year:   'numeric',
      month:  'short',
      day:    'numeric',
      hour:   '2-digit',
      minute: '2-digit',
      second: '2-digit',
    })
  } catch {
    return timestamp
  }
}

// ── Time ago (2 minutes ago) ──────────────────────────────────────────────────
export const timeAgo = (timestamp) => {
  if (!timestamp) return '--'
  try {
    const now      = new Date()
    const past     = new Date(timestamp)
    const diffMs   = now - past
    const diffSec  = Math.floor(diffMs  / 1000)
    const diffMin  = Math.floor(diffSec / 60)
    const diffHour = Math.floor(diffMin / 60)
    const diffDay  = Math.floor(diffHour / 24)

    if (diffSec  < 60)  return `${diffSec}s ago`
    if (diffMin  < 60)  return `${diffMin}m ago`
    if (diffHour < 24)  return `${diffHour}h ago`
    return `${diffDay}d ago`
  } catch {
    return '--'
  }
}

// ── Get today's date (YYYY-MM-DD) ─────────────────────────────────────────────
export const getToday = () => {
  return new Date().toISOString().slice(0, 10)
}

// ── Get current timestamp (ISO) ───────────────────────────────────────────────
export const getCurrentTimestamp = () => {
  return new Date().toISOString()
}

// ── Is today ─────────────────────────────────────────────────────────────────
export const isToday = (timestamp) => {
  if (!timestamp) return false
  return timestamp.slice(0, 10) === getToday()
}

// ── Get date range (last N days) ──────────────────────────────────────────────
export const getLastNDays = (n) => {
  const dates = []
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date()
    d.setDate(d.getDate() - i)
    dates.push(d.toISOString().slice(0, 10))
  }
  return dates
}

// ── Format chart label (Apr 25) ───────────────────────────────────────────────
export const formatChartDate = (timestamp) => {
  if (!timestamp) return '--'
  try {
    return new Date(timestamp).toLocaleDateString('en-US', {
      month: 'short',
      day:   'numeric',
    })
  } catch {
    return timestamp.slice(5, 10)
  }
}

// ── Is same day ───────────────────────────────────────────────────────────────
export const isSameDay = (ts1, ts2) => {
  if (!ts1 || !ts2) return false
  return ts1.slice(0, 10) === ts2.slice(0, 10)
}

// ── Sort by timestamp ─────────────────────────────────────────────────────────
export const sortByTimestamp = (items, order = 'asc') => {
  return [...items].sort((a, b) => {
    const diff = new Date(a.timestamp) - new Date(b.timestamp)
    return order === 'asc' ? diff : -diff
  })
}