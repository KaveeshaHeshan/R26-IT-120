// src/hooks/useVFAData.js

import { useState, useEffect } from 'react'
import { db } from '../firebase/config'
import {
  ref,
  onValue,
  query,
  orderByChild,
  limitToLast
} from 'firebase/database'

const useVFAData = (limit = 20) => {

  const [latestVFA,    setLatestVFA]    = useState(null)
  const [vfaHistory,   setVfaHistory]   = useState([])
  const [loading,      setLoading]      = useState(true)
  const [error,        setError]        = useState(null)
  const [isGradeC,     setIsGradeC]     = useState(false)

  useEffect(() => {
    setLoading(true)

    // ── Firebase real-time listener ─────────────────────────────────────────
    const predictionsRef = query(
      ref(db, 'predictions'),
      orderByChild('timestamp'),
      limitToLast(limit)
    )

    const unsubscribe = onValue(
      predictionsRef,
      (snapshot) => {
        try {
          const data = snapshot.val()

          if (!data) {
            setLatestVFA(null)
            setVfaHistory([])
            setLoading(false)
            return
          }

          // Convert object to array
          const items = Object.entries(data).map(([key, val]) => ({
            id:          key,
            vfa:         parseFloat(val.vfa) || 0,
            grade:       val.grade || 'A',
            pH:          parseFloat(val.pH) || 0,
            turbidity:   parseFloat(val.turbidity) || 0,
            temperature: parseFloat(val.temperature) || 0,
            farmer_id:   val.farmer_id || '',
            device_id:   val.device_id || '',
            sample_id:   val.sample_id || '',
            timestamp:   val.timestamp || '',
          }))

          // Sort by timestamp
          items.sort((a, b) =>
            new Date(a.timestamp) - new Date(b.timestamp)
          )

          // Latest prediction
          const latest = items[items.length - 1]
          setLatestVFA(latest)

          // Grade C check — auto alert
          setIsGradeC(latest?.grade === 'C')

          // History for chart
          const history = items.map(item => ({
            id:          item.id,
            vfa:         item.vfa,
            grade:       item.grade,
            pH:          item.pH,
            turbidity:   item.turbidity,
            temperature: item.temperature,
            farmer_id:   item.farmer_id,
            timestamp:   item.timestamp,
            time:        item.timestamp?.slice(11, 16) || '',
            date:        item.timestamp?.slice(0, 10)  || '',
          }))
          setVfaHistory(history)

          setLoading(false)
          setError(null)

        } catch (err) {
          setError('Failed to process VFA data: ' + err.message)
          setLoading(false)
        }
      },
      (err) => {
        setError('Firebase connection error: ' + err.message)
        setLoading(false)
      }
    )

    // Cleanup listener on unmount
    return () => unsubscribe()

  }, [limit])

  // ── Computed values ─────────────────────────────────────────────────────────

  // Grade color
  const getGradeColor = (grade) => {
    if (grade === 'A') return '#1F6B38'
    if (grade === 'B') return '#C9A84C'
    return '#C00000'
  }

  // Grade background
  const getGradeBg = (grade) => {
    if (grade === 'A') return 'bg-green-50 border-green-500'
    if (grade === 'B') return 'bg-yellow-50 border-yellow-500'
    return 'bg-red-50 border-red-600'
  }

  // Grade text color class
  const getGradeTextColor = (grade) => {
    if (grade === 'A') return 'text-green-700'
    if (grade === 'B') return 'text-yellow-600'
    return 'text-red-700'
  }

  // Average VFA from history
  const averageVFA = vfaHistory.length > 0
    ? (vfaHistory.reduce((sum, item) => sum + item.vfa, 0) / vfaHistory.length).toFixed(4)
    : 0

  // Grade counts from history
  const gradeCounts = vfaHistory.reduce(
    (acc, item) => {
      acc[item.grade] = (acc[item.grade] || 0) + 1
      return acc
    },
    { A: 0, B: 0, C: 0 }
  )

  // ── Return ──────────────────────────────────────────────────────────────────
  return {
    // Data
    latestVFA,
    vfaHistory,
    loading,
    error,
    isGradeC,

    // Computed
    averageVFA,
    gradeCounts,

    // Helpers
    getGradeColor,
    getGradeBg,
    getGradeTextColor,
  }
}

export default useVFAData