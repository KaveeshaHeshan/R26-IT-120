// src/hooks/usePredictions.js
//
// Shared subscription to the RTDB `predictions/` node (VFA readings from the
// ESP32 + ML pipeline). Extracted from DailySummary so multiple views can reuse it.

import { useState, useEffect } from 'react'
import { db } from '../firebase/config'
import { ref, onValue, query, orderByChild } from 'firebase/database'

const usePredictions = () => {
  const [predictions, setPredictions] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    const q = query(ref(db, 'predictions'), orderByChild('timestamp'))
    const unsub = onValue(
      q,
      (snapshot) => {
        try {
          const data = snapshot.val()
          if (!data) {
            setPredictions([])
            setLoading(false)
            return
          }
          const items = Object.entries(data).map(([key, val]) => ({
            id: key,
            vfa: parseFloat(val.vfa) || 0,
            grade: val.grade || 'A',
            pH: parseFloat(val.pH) || 0,
            turbidity: parseFloat(val.turbidity) || 0,
            temperature: parseFloat(val.temperature) || 0,
            farmer_id: val.farmer_id || '',
            timestamp: val.timestamp || '',
            date: val.timestamp?.slice(0, 10) || '',
          }))
          setPredictions(items)
          setError(null)
          setLoading(false)
        } catch {
          setPredictions([])
          setLoading(false)
        }
      },
      () => {
        setError('Unable to reach the IoT data stream.')
        setPredictions([])
        setLoading(false)
      },
    )
    return () => unsub()
  }, [])

  return { predictions, loading, error }
}

export default usePredictions
