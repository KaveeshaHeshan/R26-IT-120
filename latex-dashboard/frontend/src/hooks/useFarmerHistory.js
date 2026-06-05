// src/hooks/useFarmerHistory.js

import { useState, useEffect } from 'react'
import { db } from '../firebase/config'
import {
  ref,
  onValue,
  query,
  orderByChild,
  limitToLast
} from 'firebase/database'

// ── Mock Data Generators ──────────────────────────────────────────────────────
const generateMockFarmers = () => {
  return [
    { id: 'FARM-8239', label: 'Farmer FARM-8239 (Active)' },
    { id: 'FARM-9102', label: 'Farmer FARM-9102' },
    { id: 'FARM-1044', label: 'Farmer FARM-1044' },
    { id: 'FARM-7751', label: 'Farmer FARM-7751' },
    { id: 'FARM-3329', label: 'Farmer FARM-3329' }
  ]
}

const generateMockFarmerHistory = (farmerId, limit) => {
  const items = []
  const now = new Date()
  let currentVFA = 0.045
  
  // Seed random variation based on farmerId length to make them look distinct
  const seed = farmerId ? farmerId.length : 5
  
  for (let i = limit; i >= 0; i--) {
    const timestamp = new Date(now.getTime() - i * 86400000) // 1 per day
    currentVFA += (Math.random() - 0.45 + (seed % 3 === 0 ? 0.05 : 0)) * 0.01
    if (currentVFA < 0.02) currentVFA = 0.02
    if (currentVFA > 0.11) currentVFA = 0.09

    let grade = 'A'
    if (currentVFA >= 0.05 && currentVFA < 0.08) grade = 'B'
    if (currentVFA >= 0.08) grade = 'C'

    items.push({
      id: `mock_hist_${i}`,
      vfa: currentVFA,
      grade: grade,
      pH: 6.5 + Math.random(),
      turbidity: 20 + Math.random() * 20,
      temperature: 28 + Math.random() * 2,
      timestamp: timestamp.toISOString(),
      date: timestamp.toISOString().slice(0, 10),
      time: timestamp.toTimeString().slice(0, 5),
    })
  }
  return items
}

const useFarmerHistory = (farmerId = null, limit = 30) => {

  const [history,     setHistory]     = useState([])
  const [farmerStats, setFarmerStats] = useState(null)
  const [allFarmers,  setAllFarmers]  = useState([])
  const [loading,     setLoading]     = useState(true)
  const [error,       setError]       = useState(null)

  // ── Fetch all farmers list ──────────────────────────────────────────────────
  useEffect(() => {
    const handleMockFarmers = () => {
      setAllFarmers(generateMockFarmers())
    }

    const farmersRef = ref(db, 'farmers')
    const unsubscribe = onValue(farmersRef, (snapshot) => {
      const data = snapshot.val()
      if (data) {
        const farmers = Object.keys(data).map(id => ({
          id,
          label: `Farmer ${id}`,
        }))
        setAllFarmers(farmers.length > 0 ? farmers : generateMockFarmers())
      } else {
        handleMockFarmers()
      }
    }, (err) => {
      handleMockFarmers()
    })
    return () => unsubscribe()
  }, [])

  // ── Fetch selected farmer history ───────────────────────────────────────────
  useEffect(() => {
    if (!farmerId) {
      setHistory([])
      setFarmerStats(null)
      setLoading(false)
      return
    }

    setLoading(true)

    const processHistoryItems = (items) => {
      setHistory(items)

      // ── Compute farmer stats ──────────────────────────────────────────
      const vfaValues  = items.map(i => i.vfa)
      const totalCount = items.length
      const gradeCount = items.reduce(
        (acc, i) => { acc[i.grade] = (acc[i.grade] || 0) + 1; return acc },
        { A: 0, B: 0, C: 0 }
      )

      setFarmerStats({
        farmer_id:    farmerId,
        total:        totalCount,
        avgVFA:       (vfaValues.reduce((s, v) => s + v, 0) / totalCount).toFixed(4),
        minVFA:       Math.min(...vfaValues).toFixed(4),
        maxVFA:       Math.max(...vfaValues).toFixed(4),
        latestVFA:    items[items.length - 1]?.vfa.toFixed(4),
        latestGrade:  items[items.length - 1]?.grade,
        latestDate:   items[items.length - 1]?.date,
        gradeA:       gradeCount.A,
        gradeB:       gradeCount.B,
        gradeC:       gradeCount.C,
        gradeAPercent: ((gradeCount.A / totalCount) * 100).toFixed(1),
        gradeBPercent: ((gradeCount.B / totalCount) * 100).toFixed(1),
        gradeCPercent: ((gradeCount.C / totalCount) * 100).toFixed(1),
        hasAlerts:    gradeCount.C > 0,
      })

      setLoading(false)
      setError(null)
    }

    const handleMockHistory = () => {
      const mockItems = generateMockFarmerHistory(farmerId, limit)
      processHistoryItems(mockItems)
    }

    const historyRef = query(
      ref(db, `farmers/${farmerId}/history`),
      orderByChild('timestamp'),
      limitToLast(limit)
    )

    const unsubscribe = onValue(
      historyRef,
      (snapshot) => {
        try {
          const data = snapshot.val()

          if (!data) {
            handleMockHistory()
            return
          }

          // Convert to array
          const items = Object.entries(data).map(([key, val]) => ({
            id:          key,
            vfa:         parseFloat(val.vfa)         || 0,
            grade:       val.grade                   || 'A',
            pH:          parseFloat(val.pH)          || 0,
            turbidity:   parseFloat(val.turbidity)   || 0,
            temperature: parseFloat(val.temperature) || 0,
            timestamp:   val.timestamp               || '',
            date:        val.timestamp?.slice(0, 10) || '',
            time:        val.timestamp?.slice(11,16) || '',
          }))

          // Sort oldest → newest
          items.sort((a, b) =>
            new Date(a.timestamp) - new Date(b.timestamp)
          )

          if (items.length === 0) {
            handleMockHistory()
          } else {
            processHistoryItems(items)
          }

        } catch (err) {
          console.warn('Firebase error processing history, using mock', err)
          handleMockHistory()
        }
      },
      (err) => {
        console.warn('Firebase connection error, using mock', err)
        handleMockHistory()
      }
    )

    return () => unsubscribe()

  }, [farmerId, limit])

  // ── Get quality trend ───────────────────────────────────────────────────────
  const getQualityTrend = () => {
    if (history.length < 2) return 'stable'
    const recent = history.slice(-5).map(i => i.vfa)
    const older  = history.slice(-10, -5).map(i => i.vfa)
    const recentAvg = recent.reduce((s, v) => s + v, 0) / recent.length
    const olderAvg  = older.reduce((s, v) => s + v, 0)  / older.length
    if (recentAvg > olderAvg + 0.005) return 'degrading'  // VFA increasing
    if (recentAvg < olderAvg - 0.005) return 'improving'  // VFA decreasing
    return 'stable'
  }

  // ── Trend label ─────────────────────────────────────────────────────────────
  const getTrendLabel = () => {
    const trend = getQualityTrend()
    if (trend === 'improving')  return '📈 Improving'
    if (trend === 'degrading')  return '📉 Degrading'
    return '➡️ Stable'
  }

  // ── Trend color ─────────────────────────────────────────────────────────────
  const getTrendColor = () => {
    const trend = getQualityTrend()
    if (trend === 'improving') return '#00f5d4'
    if (trend === 'degrading') return '#ef4444'
    return '#eab308'
  }

  // ── Filter history by date range ────────────────────────────────────────────
  const filterByDateRange = (startDate, endDate) => {
    return history.filter(item => {
      const d = item.date
      return d >= startDate && d <= endDate
    })
  }

  // ── Filter history by grade ─────────────────────────────────────────────────
  const filterByGrade = (grade) => {
    if (!grade) return history
    return history.filter(item => item.grade === grade)
  }

  // ── Return ──────────────────────────────────────────────────────────────────
  return {
    // Data
    history,
    farmerStats,
    allFarmers,
    loading,
    error,

    // Trend
    getQualityTrend,
    getTrendLabel,
    getTrendColor,

    // Filters
    filterByDateRange,
    filterByGrade,
  }
}

export default useFarmerHistory