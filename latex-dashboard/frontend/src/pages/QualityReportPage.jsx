// src/pages/QualityReportPage.jsx

import { useEffect, useState } from 'react'
import { PageHeader } from '../components/ui'
import DailySummary from '../components/dashboard/DailySummary'
import { getToday, getLastNDays } from '../utils/dateHelper'

const QualityReportPage = () => {
  const [preset, setPreset] = useState('all') // 'all' | '7d' | '30d' | 'custom'
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')

  useEffect(() => {
    document.title = 'Quality Summary — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  const applyPreset = (p) => {
    setPreset(p)
    if (p === 'all') {
      setFrom('')
      setTo('')
    } else if (p === '7d') {
      setFrom(getLastNDays(7)[0])
      setTo(getToday())
    } else if (p === '30d') {
      setFrom(getLastNDays(30)[0])
      setTo(getToday())
    }
  }

  const handleFromChange = (value) => {
    setFrom(value)
    setPreset('custom')
  }

  const handleToChange = (value) => {
    setTo(value)
    setPreset('custom')
  }

  const rangeLabel = preset !== 'all' && from && to ? `${from} → ${to}` : null

  return (
    <div className="space-y-6">
      <PageHeader
        title="Quality Summary"
        description={
          'VFA quality readings from the ESP32 + ML pipeline — cumulative totals and trends.' +
          (rangeLabel ? ` · ${rangeLabel}` : '')
        }
      />
      <DailySummary
        preset={preset}
        from={from}
        to={to}
        onPresetChange={applyPreset}
        onFromChange={handleFromChange}
        onToChange={handleToChange}
      />
    </div>
  )
}

export default QualityReportPage
