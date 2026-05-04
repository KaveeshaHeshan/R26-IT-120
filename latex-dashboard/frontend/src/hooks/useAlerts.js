// src/hooks/useAlerts.js

import { useState, useEffect } from 'react'
import { db } from '../firebase/config'
import {
  ref,
  onValue,
  query,
  orderByChild,
  limitToLast,
  update
} from 'firebase/database'

const useAlerts = (limit = 50) => {

  const [alerts,       setAlerts]       = useState([])
  const [unreadCount,  setUnreadCount]  = useState(0)
  const [loading,      setLoading]      = useState(true)
  const [error,        setError]        = useState(null)
  const [latestAlert,  setLatestAlert]  = useState(null)

  useEffect(() => {
    setLoading(true)

    // ── Firebase real-time listener ─────────────────────────────────────────
    const alertsRef = query(
      ref(db, 'alerts'),
      orderByChild('timestamp'),
      limitToLast(limit)
    )

    const unsubscribe = onValue(
      alertsRef,
      (snapshot) => {
        try {
          const data = snapshot.val()

          if (!data) {
            setAlerts([])
            setUnreadCount(0)
            setLatestAlert(null)
            setLoading(false)
            return
          }

          // Convert object to array
          const items = Object.entries(data).map(([key, val]) => ({
            id:          key,
            vfa:         parseFloat(val.vfa) || 0,
            grade:       val.grade || 'C',
            pH:          parseFloat(val.pH) || 0,
            turbidity:   parseFloat(val.turbidity) || 0,
            temperature: parseFloat(val.temperature) || 0,
            farmer_id:   val.farmer_id  || '',
            device_id:   val.device_id  || '',
            sample_id:   val.sample_id  || '',
            timestamp:   val.timestamp  || '',
            read:        val.read       || false,
            severity:    getSeverity(parseFloat(val.vfa)),
          }))

          // Sort newest first
          items.sort((a, b) =>
            new Date(b.timestamp) - new Date(a.timestamp)
          )

          setAlerts(items)

          // Unread count
          const unread = items.filter(item => !item.read).length
          setUnreadCount(unread)

          // Latest alert
          setLatestAlert(items[0] || null)

          setLoading(false)
          setError(null)

        } catch (err) {
          setError('Failed to process alerts: ' + err.message)
          setLoading(false)
        }
      },
      (err) => {
        setError('Firebase connection error: ' + err.message)
        setLoading(false)
      }
    )

    return () => unsubscribe()

  }, [limit])

  // ── Severity level ──────────────────────────────────────────────────────────
  const getSeverity = (vfa) => {
    if (vfa >= 0.09) return 'critical'   // VFA >= 0.09
    if (vfa >= 0.08) return 'high'       // VFA 0.08 - 0.089
    return 'medium'
  }

  // ── Severity color ──────────────────────────────────────────────────────────
  const getSeverityColor = (severity) => {
    if (severity === 'critical') return '#7B0000'
    if (severity === 'high')     return '#C00000'
    return '#E05000'
  }

  // ── Severity label ──────────────────────────────────────────────────────────
  const getSeverityLabel = (severity) => {
    if (severity === 'critical') return '🔴 CRITICAL'
    if (severity === 'high')     return '🟠 HIGH'
    return '🟡 MEDIUM'
  }

  // ── Mark single alert as read ───────────────────────────────────────────────
  const markAsRead = async (alertId) => {
    try {
      const alertRef = ref(db, `alerts/${alertId}`)
      await update(alertRef, { read: true })
      return { success: true }
    } catch (err) {
      return { success: false, error: err.message }
    }
  }

  // ── Mark all alerts as read ─────────────────────────────────────────────────
  const markAllAsRead = async () => {
    try {
      const unreadAlerts = alerts.filter(a => !a.read)
      const updates = {}
      unreadAlerts.forEach(alert => {
        updates[`alerts/${alert.id}/read`] = true
      })
      const dbRef = ref(db)
      await update(dbRef, updates)
      return { success: true }
    } catch (err) {
      return { success: false, error: err.message }
    }
  }

  // ── Filter by severity ──────────────────────────────────────────────────────
  const filterBySeverity = (severity) => {
    if (!severity) return alerts
    return alerts.filter(a => a.severity === severity)
  }

  // ── Filter by farmer ────────────────────────────────────────────────────────
  const filterByFarmer = (farmerId) => {
    if (!farmerId) return alerts
    return alerts.filter(a => a.farmer_id === farmerId)
  }

  // ── Filter by date ──────────────────────────────────────────────────────────
  const filterByDate = (date) => {
    if (!date) return alerts
    return alerts.filter(a => a.timestamp?.slice(0, 10) === date)
  }

  // ── Computed stats ──────────────────────────────────────────────────────────
  const alertStats = {
    total:    alerts.length,
    unread:   unreadCount,
    critical: alerts.filter(a => a.severity === 'critical').length,
    high:     alerts.filter(a => a.severity === 'high').length,
    medium:   alerts.filter(a => a.severity === 'medium').length,
    today:    alerts.filter(a =>
                a.timestamp?.slice(0, 10) ===
                new Date().toISOString().slice(0, 10)
              ).length,
  }

  // ── Return ──────────────────────────────────────────────────────────────────
  return {
    // Data
    alerts,
    unreadCount,
    loading,
    error,
    latestAlert,

    // Stats
    alertStats,

    // Actions
    markAsRead,
    markAllAsRead,

    // Filters
    filterBySeverity,
    filterByFarmer,
    filterByDate,

    // Helpers
    getSeverity,
    getSeverityColor,
    getSeverityLabel,
  }
}

export default useAlerts