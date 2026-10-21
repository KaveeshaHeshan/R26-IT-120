// src/components/dashboard/DailySummary.jsx

import { useMemo } from 'react'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  AreaChart, Area, ReferenceLine,
} from 'recharts'
import { LuDownload } from 'react-icons/lu'
import usePredictions from '../../hooks/usePredictions'
import { Card, StatCard, ChartTooltip, Donut, DonutLegend, EmptyState, Spinner, Badge, Button, ProgressBar } from '../ui'
import { GRADE_COLORS } from '../../constants/theme'
import { getToday } from '../../utils/dateHelper'
import { exportCsv } from '../../utils/csv'

const GRADE_META = [
  { grade: 'A', label: 'Superior' },
  { grade: 'B', label: 'Standard' },
  { grade: 'C', label: 'Critical' },
]

const GRADE_TILE = {
  A: { bg: '#DDF3EA', ink: '#065F46' },
  B: { bg: '#FBEBD0', ink: '#7A4A06' },
  C: { bg: '#FBE4E0', ink: '#8E2A1D' },
}

const PRESETS = [
  { key: 'all', label: 'All time' },
  { key: '7d', label: 'Last 7 days' },
  { key: '30d', label: 'Last 30 days' },
]

const AXIS_TICK_V2 = { fontSize: 12, fill: '#5A6B5F' }
const GRID_STROKE_V2 = '#EEF2EA'

const DailySummary = ({ preset, from, to, onPresetChange, onFromChange, onToChange }) => {
  const { predictions, loading, error } = usePredictions()

  const filteredPredictions = useMemo(
    () => predictions.filter((p) => (!from || p.date >= from) && (!to || p.date <= to)),
    [predictions, from, to],
  )

  const stats = useMemo(() => {
    const total = filteredPredictions.length
    const count = (g) => filteredPredictions.filter((p) => p.grade === g).length
    const vfas = filteredPredictions.map((p) => p.vfa)
    return {
      total,
      gradeA: count('A'),
      gradeB: count('B'),
      gradeC: count('C'),
      avgVFA: total ? (vfas.reduce((s, v) => s + v, 0) / total).toFixed(4) : '0.0000',
      minVFA: total ? Math.min(...vfas).toFixed(4) : '0.0000',
      maxVFA: total ? Math.max(...vfas).toFixed(4) : '0.0000',
      rejectionRate: total ? ((count('C') / total) * 100).toFixed(1) : '0.0',
    }
  }, [filteredPredictions])

  const gradeData = useMemo(
    () => [
      { name: 'Grade A', value: stats.gradeA, color: GRADE_COLORS.A },
      { name: 'Grade B', value: stats.gradeB, color: GRADE_COLORS.B },
      { name: 'Grade C', value: stats.gradeC, color: GRADE_COLORS.C },
    ],
    [stats],
  )
  const pieData = useMemo(() => gradeData.filter((d) => d.value > 0), [gradeData])

  // Feeds both the trend and grade-distribution charts. Only dates with at
  // least one reading are included — sparse field-test data shouldn't plot
  // as a flat 0.0000 line on days nothing was recorded.
  const dailyBreakdown = useMemo(() => {
    const map = new Map()
    for (const p of filteredPredictions) {
      const entry = map.get(p.date) || { date: p.date, gradeA: 0, gradeB: 0, gradeC: 0, vfaSum: 0, count: 0 }
      entry.count += 1
      entry.vfaSum += p.vfa
      if (p.grade === 'A') entry.gradeA += 1
      else if (p.grade === 'B') entry.gradeB += 1
      else if (p.grade === 'C') entry.gradeC += 1
      map.set(p.date, entry)
    }
    return [...map.values()]
      .sort((a, b) => a.date.localeCompare(b.date))
      .map((e) => ({
        date: e.date.slice(5),
        gradeA: e.gradeA,
        gradeB: e.gradeB,
        gradeC: e.gradeC,
        avgVFA: parseFloat((e.vfaSum / e.count).toFixed(4)),
      }))
  }, [filteredPredictions])

  const peakDay = useMemo(
    () => (dailyBreakdown.length ? dailyBreakdown.reduce((max, d) => (d.avgVFA > max.avgVFA ? d : max), dailyBreakdown[0]) : null),
    [dailyBreakdown],
  )

  const renderTrendDot = (props) => {
    const { cx, cy, payload } = props
    const isPeak = peakDay && payload.date === peakDay.date && payload.avgVFA === peakDay.avgVFA
    if (isPeak) {
      return (
        <g key={`peak-${cx}-${cy}`}>
          <circle cx={cx} cy={cy} r={6} fill="#138A43" stroke="#138A43" strokeWidth={2.5} />
          <text x={cx} y={cy - 12} textAnchor="middle" fontSize={12} fontWeight={700} fill="#11231A">
            {payload.avgVFA.toFixed(4)}
          </text>
        </g>
      )
    }
    return <circle key={`dot-${cx}-${cy}`} cx={cx} cy={cy} r={5} fill="#fff" stroke="#138A43" strokeWidth={2.5} />
  }

  const topFarmers = useMemo(() => {
    const map = {}
    filteredPredictions.forEach((p) => {
      if (!map[p.farmer_id]) map[p.farmer_id] = { id: p.farmer_id, total: 0, gradeA: 0, gradeC: 0 }
      map[p.farmer_id].total += 1
      if (p.grade === 'A') map[p.farmer_id].gradeA += 1
      if (p.grade === 'C') map[p.farmer_id].gradeC += 1
    })
    return Object.values(map).sort((a, b) => b.total - a.total).slice(0, 5)
  }, [filteredPredictions])

  const rangeLabel = preset === 'all' || !from || !to ? 'All time' : `${from} → ${to}`

  const handleExport = () =>
    exportCsv(
      preset === 'all' ? 'quality-summary-all-time' : `quality-summary-${from}-to-${to}`,
      filteredPredictions,
      [
        { key: 'date', label: 'Date' },
        { key: 'timestamp', label: 'Timestamp' },
        { key: 'farmer_id', label: 'Farmer ID' },
        { key: 'vfa', label: 'VFA' },
        { key: 'grade', label: 'Grade' },
        { key: 'pH', label: 'pH' },
        { key: 'turbidity', label: 'Turbidity' },
        { key: 'temperature', label: 'Temperature' },
      ],
    )

  if (loading) return <Spinner size="lg" label="Loading data stream…" className="min-h-[50vh]" />
  if (error) {
    return (
      <Card className="border-amber-200 bg-amber-50">
        <p className="text-sm text-amber-800">{error}</p>
      </Card>
    )
  }

  if (predictions.length === 0) {
    return <EmptyState title="No readings yet" description="Classified VFA readings will appear here once the ESP32 + ML pipeline reports data." />
  }

  return (
    <div className="space-y-6">
      {/* Filter bar */}
      <div className="flex flex-wrap items-center gap-3">
        <div className="inline-flex items-center gap-1 rounded-[14px] border border-[#DDE4D8] bg-white p-1">
          {PRESETS.map(({ key, label }) => {
            const selected = preset === key
            return (
              <button
                key={key}
                type="button"
                aria-pressed={selected}
                onClick={() => onPresetChange(key)}
                className={`rounded-[10px] px-4 py-[9px] text-sm font-semibold transition-colors ${
                  selected ? 'bg-forest-900 text-white' : 'bg-transparent text-[#3F5146] hover:bg-[#F7FAF4]'
                }`}
              >
                {label}
              </button>
            )
          })}
        </div>
        <input
          type="date"
          value={from}
          max={to || getToday()}
          onChange={(e) => onFromChange(e.target.value)}
          className="h-[42px] rounded-xl border border-[#DDE4D8] bg-white px-3 text-sm text-[#11231A]"
        />
        <span className="text-sm text-[#8FA093]">→</span>
        <input
          type="date"
          value={to}
          min={from}
          max={getToday()}
          onChange={(e) => onToChange(e.target.value)}
          className="h-[42px] rounded-xl border border-[#DDE4D8] bg-white px-3 text-sm text-[#11231A]"
        />
        {preset !== 'all' && (
          <button onClick={() => onPresetChange('all')} className="text-sm text-[#5A6B5F] hover:text-[#11231A] underline">
            Clear filter
          </button>
        )}
        <Button
          variant="primary"
          icon={<LuDownload size={16} className="text-glow" />}
          onClick={handleExport}
          className="ml-auto"
        >
          Export CSV
        </Button>
      </div>

      {/* KPIs */}
      <div className="flex flex-wrap gap-5">
        <div className="flex-[1_1_220px]">
          <StatCard variant="kpi" label="Total readings" value={stats.total} sub="Classified samples" />
        </div>
        <div className="flex-[1_1_220px]">
          <StatCard variant="kpi" label="Avg VFA" value={stats.avgVFA} valueColor="#0E6B33" />
        </div>
        <div className="flex-[1_1_220px]">
          <StatCard variant="kpi" label="Rejection rate" value={`${stats.rejectionRate}%`} valueColor="#B42318" sub="Grade C share" />
        </div>
        <div className="flex-[1_1_220px]">
          <StatCard variant="kpi" kpiTone="danger" label="Grade C" value={stats.gradeC} sub="Critical readings" />
        </div>
      </div>

      <div className="flex flex-wrap gap-5">
        {/* Grade classification */}
        <Card
          variant="v2"
          className="flex-[1.2_1_440px]"
          title="Grade classification"
          subtitle={`${rangeLabel} · ${stats.total} readings`}
        >
          <div className="space-y-5">
            {GRADE_META.map(({ grade, label }) => {
              const count = stats[`grade${grade}`]
              const pct = stats.total ? (count / stats.total) * 100 : 0
              const tile = GRADE_TILE[grade]
              return (
                <div key={grade}>
                  <div className="flex items-center gap-3 mb-2">
                    <span
                      className="w-8 h-8 rounded-[10px] text-sm font-bold flex items-center justify-center shrink-0"
                      style={{ background: tile.bg, color: tile.ink }}
                    >
                      {grade}
                    </span>
                    <span className="text-base font-semibold text-[#11231A]">{label}</span>
                    <span className="text-sm text-[#5A6B5F]">{count} units</span>
                    <span className="ml-auto text-sm font-bold text-[#11231A] tabular-nums">{pct.toFixed(1)}%</span>
                  </div>
                  <ProgressBar value={count} max={stats.total || 1} height={10} color={GRADE_COLORS[grade]} trackColor="#EEF3EA" />
                </div>
              )
            })}
          </div>
          <div className="mt-6 pt-5 border-t border-[#EDF1E9] grid grid-cols-3 gap-3">
            {[
              { label: 'Min VFA', value: stats.minVFA },
              { label: 'Avg VFA', value: stats.avgVFA },
              { label: 'Max VFA', value: stats.maxVFA },
            ].map((v) => (
              <div key={v.label} className="rounded-[14px] bg-[#F7FAF4] px-4 py-[14px]">
                <p className="text-xs font-bold uppercase tracking-[0.06em] text-[#5A6B5F]">{v.label}</p>
                <p className="font-display text-2xl font-bold text-[#11231A] tabular-nums mt-1">{v.value}</p>
              </div>
            ))}
          </div>
        </Card>

        {/* Pie */}
        <Card
          variant="v2"
          className="flex-[1_1_380px]"
          title="Grade breakdown"
          subtitle={`${stats.total} readings · ${rangeLabel}`}
        >
          {pieData.length === 0 ? (
            <EmptyState title="No readings in this range" />
          ) : (
            <div className="flex flex-col sm:flex-row items-center gap-6">
              <Donut data={pieData} size={210} centerValue={stats.total} centerLabel="Readings" />
              <div className="w-full sm:flex-1 sm:min-w-0">
                <DonutLegend items={gradeData} variant="v2" />
              </div>
            </div>
          )}
        </Card>
      </div>

      {/* VFA trend */}
      <Card
        variant="v2"
        title="VFA trend"
        subtitle={`Average VFA per active day · ${rangeLabel}`}
        action={
          <div className="flex flex-wrap items-center gap-4 text-xs text-[#5A6B5F]">
            <span className="flex items-center gap-1.5">
              <span className="w-4 border-t-2 border-dashed" style={{ borderColor: '#D97706' }} />
              Grade A limit (0.05)
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-4 border-t-2 border-dashed" style={{ borderColor: '#DC2626' }} />
              Critical limit (0.08)
            </span>
          </div>
        }
      >
        {dailyBreakdown.length === 0 ? (
          <EmptyState title="No readings in this range" />
        ) : (
          <div style={{ width: '100%', height: 290 }}>
            <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={220}>
              <AreaChart data={dailyBreakdown} margin={{ top: 16, right: 12, left: -16, bottom: 0 }}>
                <defs>
                  <linearGradient id="vfaFillV2" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#22B14C" stopOpacity={0.12} />
                    <stop offset="95%" stopColor="#22B14C" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE_V2} vertical={false} />
                <XAxis dataKey="date" tick={AXIS_TICK_V2} axisLine={false} tickLine={false} interval="preserveStartEnd" />
                <YAxis
                  domain={[0, 0.12]}
                  ticks={[0, 0.03, 0.06, 0.09, 0.12]}
                  tick={AXIS_TICK_V2}
                  axisLine={false}
                  tickLine={false}
                  tickFormatter={(v) => v.toFixed(3)}
                />
                <Tooltip content={<ChartTooltip rows={(p) => [{ label: 'Avg VFA', value: Number(p[0].value).toFixed(4), color: '#138A43' }]} />} />
                <ReferenceLine y={0.05} stroke="#D97706" strokeDasharray="4 4" />
                <ReferenceLine y={0.08} stroke="#DC2626" strokeDasharray="4 4" />
                <Area type="monotone" dataKey="avgVFA" stroke="#138A43" strokeWidth={3} fill="url(#vfaFillV2)" dot={renderTrendDot} activeDot={{ r: 6 }} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}
      </Card>

      <div className="flex flex-wrap gap-5">
        <Card
          variant="v2"
          className="flex-[1_1_420px]"
          title="Grade distribution"
          subtitle={`Daily grade counts · ${rangeLabel}`}
        >
          {dailyBreakdown.length === 0 ? (
            <EmptyState title="No readings in this range" />
          ) : (
            <div style={{ width: '100%', height: 240 }}>
              <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={180}>
                <BarChart data={dailyBreakdown} margin={{ top: 8, right: 8, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE_V2} vertical={false} />
                  <XAxis dataKey="date" tick={AXIS_TICK_V2} axisLine={false} tickLine={false} interval="preserveStartEnd" />
                  <YAxis tick={AXIS_TICK_V2} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip
                    cursor={{ fill: 'rgba(34,177,76,0.06)' }}
                    content={
                      <ChartTooltip
                        rows={(p) => [
                          { label: 'Grade A', value: p[0].payload.gradeA, color: GRADE_COLORS.A },
                          { label: 'Grade B', value: p[0].payload.gradeB, color: GRADE_COLORS.B },
                          { label: 'Grade C', value: p[0].payload.gradeC, color: GRADE_COLORS.C },
                        ]}
                      />
                    }
                  />
                  <Bar dataKey="gradeA" stackId="a" fill={GRADE_COLORS.A} barSize={22} />
                  <Bar dataKey="gradeB" stackId="a" fill={GRADE_COLORS.B} />
                  <Bar dataKey="gradeC" stackId="a" fill={GRADE_COLORS.C} radius={[3, 3, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>

        <Card variant="v2" className="flex-[1_1_420px]" title="Top farmers" subtitle={`Most readings · ${rangeLabel}`}>
          {topFarmers.length === 0 ? (
            <EmptyState title="No readings in this range" />
          ) : (
            <ul>
              {topFarmers.map((f, i) => (
                <li
                  key={f.id}
                  className={`flex items-center justify-between gap-3 py-3 ${i > 0 ? 'border-t border-[#EDF1E9]' : ''}`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="w-7 h-7 rounded-full bg-[#E8F6EC] text-brand-700 text-xs font-bold flex items-center justify-center shrink-0">
                      {i + 1}
                    </span>
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-[#11231A] truncate">{f.id || 'Unknown'}</p>
                      <p className="text-xs text-[#5A6B5F]">{f.total} readings</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <Badge variant="v2" tone="success">{f.gradeA} A</Badge>
                    {f.gradeC > 0 && <Badge variant="v2" tone="danger">{f.gradeC} C</Badge>}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
    </div>
  )
}

export default DailySummary
