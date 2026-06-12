// src/components/dashboard/DailySummary.jsx

import { useState, useEffect }              from 'react'
import { db }                               from '../../firebase/config'
import { ref, onValue, query,
         orderByChild }                     from 'firebase/database'
import { BarChart, Bar, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer, Cell,
         PieChart, Pie, Legend,
         LineChart, Line,
         ReferenceLine, AreaChart, Area }    from 'recharts'
import { getGradeColor, getGradeBadgeColor,
         getGradeIcon }                     from '../../utils/gradeHelper'
import { getToday, getLastNDays,
         formatChartDate }                  from '../../utils/dateHelper'

// ── Design tokens matching home & login pages ──────────────────────────────
const C = {
  darkGreen:  '#0a3622',
  deepGreen:  '#052c14',
  gold:       '#c9a84c',
  goldLight:  '#f5e9c8',
  emerald:    '#10b981',
  bg:         '#fcfdfc',
}

const DailySummary = () => {

  const [predictions, setPredictions] = useState([])
  const [loading,     setLoading]     = useState(true)
  const [error,       setError]       = useState(null)
  const [selectedDate, setSelectedDate] = useState(getToday())

  useEffect(() => {
    const q = query(ref(db, 'predictions'), orderByChild('timestamp'))
    setLoading(true)
    const unsub = onValue(q, (snapshot) => {
      try {
        const data = snapshot.val()
        if (!data) { setPredictions([]); setLoading(false); return }
        const items = Object.entries(data).map(([key, val]) => ({
          id:          key,
          vfa:         parseFloat(val.vfa)         || 0,
          grade:       val.grade                   || 'A',
          pH:          parseFloat(val.pH)          || 0,
          turbidity:   parseFloat(val.turbidity)   || 0,
          temperature: parseFloat(val.temperature) || 0,
          farmer_id:   val.farmer_id               || '',
          timestamp:   val.timestamp               || '',
          date:        val.timestamp?.slice(0,10)  || '',
        }))
        setPredictions(items)
        setLoading(false)
        setError(null)
      } catch {
        setPredictions([]); setLoading(false)
      }
    }, () => {
      setError('Unable to reach the IoT stream.')
      setPredictions([]); setLoading(false)
    })
    return () => unsub()
  }, [])

  const todayData = predictions.filter(p => p.date === selectedDate)

  const dailyStats = {
    total:   todayData.length,
    gradeA:  todayData.filter(p => p.grade === 'A').length,
    gradeB:  todayData.filter(p => p.grade === 'B').length,
    gradeC:  todayData.filter(p => p.grade === 'C').length,
    avgVFA:  todayData.length > 0
      ? (todayData.reduce((s,p) => s + p.vfa, 0) / todayData.length).toFixed(4) : '0.0000',
    minVFA:  todayData.length > 0
      ? Math.min(...todayData.map(p => p.vfa)).toFixed(4) : '0.0000',
    maxVFA:  todayData.length > 0
      ? Math.max(...todayData.map(p => p.vfa)).toFixed(4) : '0.0000',
    rejectionRate: todayData.length > 0
      ? ((todayData.filter(p => p.grade === 'C').length / todayData.length) * 100).toFixed(1) : '0.0',
  }

  const pieData = [
    { name: 'Grade A', value: dailyStats.gradeA, color: getGradeColor('A') },
    { name: 'Grade B', value: dailyStats.gradeB, color: getGradeColor('B') },
    { name: 'Grade C', value: dailyStats.gradeC, color: getGradeColor('C') },
  ].filter(d => d.value > 0)

  const last7Days = getLastNDays(7).map(date => {
    const dayData = predictions.filter(p => p.date === date)
    return {
      date:   date.slice(5),
      total:  dayData.length,
      gradeA: dayData.filter(p => p.grade === 'A').length,
      gradeB: dayData.filter(p => p.grade === 'B').length,
      gradeC: dayData.filter(p => p.grade === 'C').length,
      avgVFA: dayData.length > 0
        ? parseFloat((dayData.reduce((s,p) => s + p.vfa, 0) / dayData.length).toFixed(4)) : 0,
    }
  })

  const farmerMap = {}
  todayData.forEach(p => {
    if (!farmerMap[p.farmer_id]) farmerMap[p.farmer_id] = { total:0, gradeA:0, gradeB:0, gradeC:0 }
    farmerMap[p.farmer_id].total++
    farmerMap[p.farmer_id][`grade${p.grade}`]++
  })
  const topFarmers = Object.entries(farmerMap)
    .map(([id, stats]) => ({ id, ...stats }))
    .sort((a,b) => b.total - a.total)
    .slice(0, 5)

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-12 h-12 border-4 border-[#0a3622] border-t-[#c9a84c] rounded-full animate-spin" />
          <p className="text-[#0a3622] text-xs font-black uppercase tracking-widest opacity-40">Loading Data Stream...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-2xl p-6 text-center">
        <p className="text-red-600 text-sm font-semibold">{error}</p>
      </div>
    )
  }

  return (
    <div className="space-y-6 pb-10">

      {/* ── Page Header ─────────────────────────────────────────────── */}
      <div className="bg-[#0a3622] rounded-2xl overflow-hidden shadow-[0_8px_40px_rgba(10,54,34,0.25)]">
        {/* Gold accent bar */}
        <div className="h-0.5 bg-[#c9a84c] w-full" />
        <div className="px-8 py-6 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div>
            <p className="text-[#c9a84c] text-[9px] font-black uppercase tracking-[0.4em] mb-1">
              Intelligence Summary
            </p>
            <h2 className="text-white text-2xl font-black uppercase tracking-tight">
              Daily Quality Report
            </h2>
          </div>

          <div className="flex items-center gap-3 bg-white/10 p-2 rounded-xl border border-white/10">
            <input
              type="date"
              value={selectedDate}
              max={getToday()}
              onChange={e => setSelectedDate(e.target.value)}
              className="bg-transparent text-white text-xs font-black uppercase tracking-widest px-4 py-2 focus:outline-none cursor-pointer"
            />
            <button
              onClick={() => setSelectedDate(getToday())}
              className="px-5 py-2 bg-[#c9a84c] text-[#052c14] text-[10px] font-black uppercase tracking-[0.2em] rounded-lg hover:bg-[#b8963d] active:scale-95 transition-all shadow-md"
            >
              TODAY
            </button>
          </div>
        </div>
      </div>

      {/* ── KPI Cards ─────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Units',     value: dailyStats.total,             sub: 'Batch Collections', accent: C.darkGreen, icon: '📋' },
          { label: 'Avg VFA',         value: dailyStats.avgVFA,            sub: 'VFA Composite',     accent: C.emerald,   icon: '📊' },
          { label: 'Rejection Rate',  value: `${dailyStats.rejectionRate}%`, sub: 'Grade C Variance', accent: '#ef4444',  icon: '📉' },
          { label: 'Active Alerts',   value: dailyStats.gradeC,            sub: 'Critical Events',   accent: '#f59e0b',   icon: '⚠️' },
        ].map((s, i) => (
          <div key={i} className="bg-white rounded-2xl border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-6 overflow-hidden relative group hover:shadow-[0_8px_30px_rgba(0,0,0,0.08)] transition-all duration-300">
            {/* Top accent line */}
            <div className="absolute top-0 left-0 right-0 h-0.5" style={{ backgroundColor: s.accent }} />
            <div className="flex items-start justify-between mb-4">
              <span className="text-[9px] font-black text-gray-400 uppercase tracking-[0.2em]">{s.label}</span>
              <span className="text-lg">{s.icon}</span>
            </div>
            <div className="text-3xl font-black tracking-tighter" style={{ color: s.accent }}>
              {s.value}
            </div>
            <p className="text-[8px] font-bold text-gray-300 uppercase tracking-widest mt-3">{s.sub}</p>
          </div>
        ))}
      </div>

      {/* ── Grade Distribution + Pie ─────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Grade bars */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-8">
          <div className="flex items-center justify-between mb-8">
            <div>
              <p className="text-[9px] font-black text-[#c9a84c] uppercase tracking-[0.3em] mb-1">Quality Analysis</p>
              <h4 className="text-sm font-black text-[#0a3622] uppercase tracking-wider">Grade Classification</h4>
            </div>
            <span className="text-[9px] font-black text-gray-300 uppercase tracking-widest bg-gray-50 px-3 py-1.5 rounded-full border border-gray-100">
              Day View
            </span>
          </div>

          <div className="space-y-6">
            {[
              { grade: 'A', count: dailyStats.gradeA, label: 'Superior Grade' },
              { grade: 'B', count: dailyStats.gradeB, label: 'Standard Grade' },
              { grade: 'C', count: dailyStats.gradeC, label: 'Critical Grade' },
            ].map(g => (
              <div key={g.grade}>
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-9 h-9 rounded-xl flex items-center justify-center text-sm font-black border"
                      style={{ color: getGradeColor(g.grade), backgroundColor: `${getGradeColor(g.grade)}15`, borderColor: `${getGradeColor(g.grade)}30` }}
                    >
                      {g.grade}
                    </div>
                    <div>
                      <p className="text-[10px] font-black text-[#0a3622] uppercase tracking-wider">{g.label}</p>
                      <p className="text-[8px] font-bold text-gray-300 uppercase tracking-widest">{g.count} units</p>
                    </div>
                  </div>
                  <span className="text-sm font-black text-[#0a3622]">
                    {dailyStats.total > 0 ? ((g.count / dailyStats.total) * 100).toFixed(1) : 0}%
                  </span>
                </div>
                <div className="bg-gray-100 rounded-full h-1.5 overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-1000 ease-out"
                    style={{
                      width: dailyStats.total > 0 ? `${(g.count / dailyStats.total) * 100}%` : '0%',
                      backgroundColor: getGradeColor(g.grade),
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          {/* VFA metrics */}
          <div className="mt-8 pt-6 border-t border-gray-100 grid grid-cols-3 gap-3">
            {[
              { label: 'Min VFA',  value: dailyStats.minVFA,  color: '#4CBB17' },
              { label: 'Avg VFA',  value: dailyStats.avgVFA,  color: C.emerald },
              { label: 'Max VFA',  value: dailyStats.maxVFA,  color: '#ef4444' },
            ].map((v, i) => (
              <div key={i} className="bg-gray-50 p-3 rounded-xl border border-gray-100">
                <p className="text-[8px] font-black text-gray-400 uppercase tracking-widest mb-1">{v.label}</p>
                <p className="font-black text-xs tabular-nums" style={{ color: v.color }}>{v.value}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Pie chart */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-8 flex flex-col">
          <div className="mb-6">
            <p className="text-[9px] font-black text-[#c9a84c] uppercase tracking-[0.3em] mb-1">Distribution</p>
            <h4 className="text-sm font-black text-[#0a3622] uppercase tracking-wider">Grade Breakdown</h4>
          </div>

          {pieData.length > 0 ? (
            <div className="flex-1 relative flex items-center justify-center">
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <defs>
                    {pieData.map((entry, index) => (
                      <linearGradient key={`grad-${index}`} id={`dgrad-${index}`} x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%"  stopColor={entry.color} stopOpacity={0.9}/>
                        <stop offset="95%" stopColor={entry.color} stopOpacity={0.3}/>
                      </linearGradient>
                    ))}
                  </defs>
                  <Pie
                    data={pieData}
                    cx="50%" cy="50%"
                    innerRadius={75} outerRadius={105}
                    paddingAngle={6}
                    dataKey="value"
                    stroke="none"
                  >
                    {pieData.map((entry, i) => (
                      <Cell key={i} fill={`url(#dgrad-${i})`} />
                    ))}
                  </Pie>
                  <Tooltip
                    content={({ active, payload }) => {
                      if (active && payload?.length) {
                        return (
                          <div className="bg-white p-4 border border-gray-200 rounded-xl shadow-lg">
                            <p className="text-[9px] font-black text-gray-400 uppercase tracking-widest mb-1">{payload[0].name}</p>
                            <div className="text-2xl font-black" style={{ color: payload[0].payload.color }}>
                              {payload[0].value} <span className="text-xs text-gray-400">units</span>
                            </div>
                          </div>
                        )
                      }
                      return null
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>

              {/* Center label */}
              <div className="absolute flex flex-col items-center justify-center pointer-events-none">
                <span className="text-[8px] font-black text-gray-400 uppercase tracking-widest">Total</span>
                <span className="text-4xl font-black text-[#0a3622]">{dailyStats.total}</span>
              </div>
            </div>
          ) : (
            <div className="flex-1 flex flex-col items-center justify-center opacity-20 h-48">
              <div className="w-10 h-10 rounded-full border-2 border-dashed border-gray-300 animate-spin mb-4" />
              <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">No Data</p>
            </div>
          )}

          <div className="flex flex-wrap justify-center gap-5 mt-4 pt-4 border-t border-gray-100">
            {pieData.map((d, i) => (
              <div key={i} className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor: d.color }} />
                <span className="text-[9px] font-black text-gray-400 uppercase tracking-widest">{d.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* ── 7-Day VFA Trend ─────────────────────────────────────────── */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-[9px] font-black text-[#c9a84c] uppercase tracking-[0.3em] mb-1">7-Day Cycle</p>
            <h4 className="text-sm font-black text-[#0a3622] uppercase tracking-wider">VFA Volatility Trend</h4>
          </div>
          <div className="flex items-center gap-2 bg-[#0a3622]/5 px-4 py-2 rounded-xl border border-[#0a3622]/10">
            <div className="w-2 h-2 rounded-full bg-[#c9a84c] animate-pulse" />
            <span className="text-[9px] font-black text-[#0a3622] uppercase tracking-widest">Live</span>
          </div>
        </div>

        <div className="h-70">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={last7Days} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="vfaFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#0a3622" stopOpacity={0.15}/>
                  <stop offset="95%" stopColor="#0a3622" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.04)" vertical={false} />
              <XAxis dataKey="date" tick={{ fontSize: 9, fill: '#9ca3af', fontWeight: 800 }} axisLine={false} tickLine={false} dy={12} />
              <YAxis domain={[0, 0.12]} tick={{ fontSize: 9, fill: '#9ca3af', fontWeight: 800 }} axisLine={false} tickLine={false} tickFormatter={v => v.toFixed(3)} />
              <Tooltip
                content={({ active, payload }) => {
                  if (active && payload?.length) {
                    return (
                      <div className="bg-white p-4 border border-gray-200 rounded-xl shadow-lg">
                        <p className="text-[9px] font-black text-gray-400 uppercase tracking-widest mb-2">{payload[0].payload.date}</p>
                        <div className="flex items-center gap-3">
                          <span className="text-2xl font-black text-[#0a3622]">{payload[0].value.toFixed(4)}</span>
                          <span className="text-[8px] font-black text-gray-400 uppercase tracking-widest">Avg VFA</span>
                        </div>
                      </div>
                    )
                  }
                  return null
                }}
              />
              <ReferenceLine y={0.05} stroke="#c9a84c" strokeDasharray="4 4" opacity={0.4} />
              <ReferenceLine y={0.08} stroke="#ef4444" strokeDasharray="4 4" opacity={0.3} />
              <Area type="monotone" dataKey="avgVFA" stroke="#0a3622" strokeWidth={3} fillOpacity={1} fill="url(#vfaFill)" animationDuration={1800} dot={{ fill: '#0a3622', r: 3 }} activeDot={{ fill: '#c9a84c', r: 5, stroke: '#0a3622', strokeWidth: 2 }} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="flex items-center gap-6 mt-4 pt-4 border-t border-gray-100">
          <div className="flex items-center gap-2">
            <div className="w-6 h-0.5 bg-[#c9a84c] opacity-60" style={{ backgroundImage: 'repeating-linear-gradient(90deg,#c9a84c 0,#c9a84c 4px,transparent 4px,transparent 8px)' }} />
            <span className="text-[8px] font-black text-gray-400 uppercase tracking-widest">Grade A Threshold (0.05)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-6 h-0.5 bg-red-400 opacity-60" style={{ backgroundImage: 'repeating-linear-gradient(90deg,#ef4444 0,#ef4444 4px,transparent 4px,transparent 8px)' }} />
            <span className="text-[8px] font-black text-gray-400 uppercase tracking-widest">Critical Threshold (0.08)</span>
          </div>
        </div>
      </div>

      {/* ── Grade Bar Chart + Top Farmers ─────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Grade stacked bar */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-8">
          <div className="mb-8">
            <p className="text-[9px] font-black text-[#c9a84c] uppercase tracking-[0.3em] mb-1">Weekly Overview</p>
            <h4 className="text-sm font-black text-[#0a3622] uppercase tracking-wider">Grade Distribution Flux</h4>
          </div>
          <div className="h-60">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={last7Days} margin={{ top: 0, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.04)" vertical={false} />
                <XAxis dataKey="date" tick={{ fontSize: 9, fill: '#9ca3af', fontWeight: 800 }} axisLine={false} tickLine={false} dy={10} />
                <YAxis hide />
                <Tooltip
                  cursor={{ fill: 'rgba(10,54,34,0.03)' }}
                  content={({ active, payload }) => {
                    if (active && payload?.length) {
                      return (
                        <div className="bg-white p-4 border border-gray-200 rounded-xl shadow-lg">
                          <p className="text-[9px] font-black text-gray-400 uppercase tracking-widest mb-3">{payload[0].payload.date}</p>
                          <div className="space-y-1.5">
                            <div className="flex items-center justify-between gap-6">
                              <span className="text-[10px] font-black uppercase" style={{ color: getGradeColor('A') }}>Grade A</span>
                              <span className="text-sm font-black text-[#0a3622]">{payload[0].payload.gradeA}</span>
                            </div>
                            <div className="flex items-center justify-between gap-6">
                              <span className="text-[10px] font-black uppercase" style={{ color: getGradeColor('B') }}>Grade B</span>
                              <span className="text-sm font-black text-[#0a3622]">{payload[0].payload.gradeB}</span>
                            </div>
                            <div className="flex items-center justify-between gap-6">
                              <span className="text-[10px] font-black uppercase" style={{ color: getGradeColor('C') }}>Grade C</span>
                              <span className="text-sm font-black text-[#0a3622]">{payload[0].payload.gradeC}</span>
                            </div>
                          </div>
                        </div>
                      )
                    }
                    return null
                  }}
                />
                <Bar dataKey="gradeA" stackId="a" fill={getGradeColor('A')} barSize={20} />
                <Bar dataKey="gradeB" stackId="a" fill={getGradeColor('B')} />
                <Bar dataKey="gradeC" stackId="a" fill={getGradeColor('C')} radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Top Farmers */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-[0_4px_20px_rgba(0,0,0,0.05)] p-8">
          <div className="mb-8">
            <p className="text-[9px] font-black text-[#c9a84c] uppercase tracking-[0.3em] mb-1">Performance Nodes</p>
            <h4 className="text-sm font-black text-[#0a3622] uppercase tracking-wider">Top Farmers</h4>
          </div>

          <div className="space-y-3">
            {topFarmers.length > 0 ? topFarmers.map((f, i) => (
              <div
                key={f.id}
                className="flex items-center justify-between p-4 rounded-xl bg-gray-50 border border-gray-100 hover:border-[#0a3622]/20 hover:bg-[#0a3622]/2 transition-all group"
              >
                <div className="flex items-center gap-4">
                  <div className="w-9 h-9 rounded-xl bg-[#0a3622] flex items-center justify-center text-[#c9a84c] text-[10px] font-black">
                    #{i + 1}
                  </div>
                  <div>
                    <p className="text-[10px] font-black text-[#0a3622] uppercase tracking-wider">{f.id}</p>
                    <p className="text-[8px] font-bold text-gray-400 uppercase tracking-widest mt-0.5">{f.total} batches</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  <span className="px-2.5 py-1 rounded-lg text-[10px] font-black" style={{ backgroundColor: `${getGradeColor('A')}15`, color: getGradeColor('A') }}>
                    {f.gradeA} A
                  </span>
                  <span className="px-2.5 py-1 rounded-lg text-[10px] font-black bg-red-50 text-red-500">
                    {f.gradeC} C
                  </span>
                </div>
              </div>
            )) : (
              <div className="flex flex-col items-center justify-center h-40 opacity-30">
                <p className="text-sm font-black text-[#0a3622] uppercase tracking-widest">Awaiting Data...</p>
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  )
}

export default DailySummary
