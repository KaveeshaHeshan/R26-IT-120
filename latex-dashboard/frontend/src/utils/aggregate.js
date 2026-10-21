// src/utils/aggregate.js
//
// Pure aggregation helpers for Firestore users/ + tapping_details/ data.
// A "joined session" is a tapping_details doc enriched with its farmer's
// profile fields (see useFactoryData): { ...session, farmerName, district, ... }

// ── Coercion ─────────────────────────────────────────────────────────────────
export const parseNum = (v) => {
  const n = parseFloat(v)
  return Number.isFinite(n) ? n : 0
}

/** Firestore Timestamp | Date | ISO string -> Date | null */
export const toDate = (v) => {
  if (!v) return null
  if (typeof v?.toDate === 'function') return v.toDate()
  if (v instanceof Date) return v
  const d = new Date(v)
  return Number.isNaN(d.getTime()) ? null : d
}

const inRange = (date, from, to) => {
  if (!date) return false
  if (from && date < from) return false
  if (to && date > to) return false
  return true
}

export const daysAgo = (n) => {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  d.setDate(d.getDate() - n)
  return d
}

// ── District volume ──────────────────────────────────────────────────────────
/**
 * @param {Array} sessions joined sessions with `district` + `latexVolumeL` + `sessionDate` (Date)
 * @param {{ from?: Date, to?: Date }} range
 * @returns {Array<{ district: string, volumeL: number, sessions: number }>}
 */
export const volumeByDistrict = (sessions, { from, to } = {}) => {
  const map = new Map()
  for (const s of sessions) {
    if ((from || to) && !inRange(s.sessionDate, from, to)) continue
    const key = s.district || 'Unknown'
    const entry = map.get(key) || { district: key, volumeL: 0, sessions: 0 }
    entry.volumeL += parseNum(s.latexVolumeL)
    entry.sessions += 1
    map.set(key, entry)
  }
  return [...map.values()]
    .map((e) => ({ ...e, volumeL: round(e.volumeL) }))
    .sort((a, b) => b.volumeL - a.volumeL)
}

// ── Top farmers by volume ────────────────────────────────────────────────────
export const topFarmersByVolume = (sessions, { days = 30, limit = 10 } = {}) => {
  const cutoff = daysAgo(days)
  const map = new Map()
  for (const s of sessions) {
    if (s.sessionDate && s.sessionDate < cutoff) continue
    const key = s.userId
    if (!key) continue
    const entry =
      map.get(key) ||
      { uid: key, name: s.farmerName || key, district: s.district || '—', volumeL: 0, sessions: 0 }
    entry.volumeL += parseNum(s.latexVolumeL)
    entry.sessions += 1
    map.set(key, entry)
  }
  return [...map.values()]
    .map((e) => ({ ...e, volumeL: round(e.volumeL) }))
    .sort((a, b) => b.volumeL - a.volumeL)
    .slice(0, limit)
}

// ── Per-farmer activity ──────────────────────────────────────────────────────
/**
 * @returns {Map<uid, { lastSession: Date|null, sessionCount: number, totalVolumeL: number, avgYieldPerTreeL: number }>}
 */
export const farmerActivity = (sessions) => {
  const map = new Map()
  for (const s of sessions) {
    const key = s.userId
    if (!key) continue
    const entry =
      map.get(key) ||
      { lastSession: null, sessionCount: 0, totalVolumeL: 0, _yieldSum: 0 }
    entry.sessionCount += 1
    entry.totalVolumeL += parseNum(s.latexVolumeL)
    entry._yieldSum += parseNum(s.yieldPerTreeL)
    if (s.sessionDate && (!entry.lastSession || s.sessionDate > entry.lastSession)) {
      entry.lastSession = s.sessionDate
    }
    map.set(key, entry)
  }
  for (const entry of map.values()) {
    entry.totalVolumeL = round(entry.totalVolumeL)
    entry.avgYieldPerTreeL = entry.sessionCount ? round(entry._yieldSum / entry.sessionCount, 3) : 0
    delete entry._yieldSum
  }
  return map
}

export const isLowActivity = (lastSession, days) => {
  if (!lastSession) return true
  return lastSession < daysAgo(days)
}

// ── Recent activity feed ─────────────────────────────────────────────────────
export const recentSessions = (sessions, limit = 15) =>
  [...sessions]
    .filter((s) => s.sessionDate)
    .sort((a, b) => b.sessionDate - a.sessionDate)
    .slice(0, limit)

// ── misc ─────────────────────────────────────────────────────────────────────
export const round = (n, dp = 2) => {
  const f = 10 ** dp
  return Math.round((n + Number.EPSILON) * f) / f
}

export const uniqueSorted = (values) =>
  [...new Set(values.filter(Boolean))].sort((a, b) => String(a).localeCompare(String(b)))
