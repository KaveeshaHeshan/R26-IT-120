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
         ReferenceLine }                    from 'recharts'
import { getGradeColor, getGradeBadgeColor,
         getGradeIcon }                     from '../../utils/gradeHelper'
import { getToday, getLastNDays,
         formatChartDate }                  from '../../utils/dateHelper'

const DailySummary = () => {

  const [predictions, setPredictions] = useState([])
  const [loading,     setLoading]     = useState(true)
  const [error,       setError]       = useState(null)
  const [selectedDate, setSelectedDate] = useState(getToday())

  // ── Fetch all predictions ───────────────────────────────────────────────────
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp')
    )

    const unsub = onValue(q, (snapshot) => {
      try {
        const data = snapshot.val()
        if (!data) {
          setPredictions([])
          setLoading(false)
          return
        }

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

      } catch (err) {
        setError('Failed to load data: ' + err.message)
        setLoading(false)
      }
    }, (err) => {
      setError('Firebase error: ' + err.message)
      setLoading(false)
    })

    return () => unsub()
  }, [])

  // ── Filter by selected date ─────────────────────────────────────────────────
  const todayData = predictions.filter(p => p.date === selectedDate)

  // ── Daily stats ─────────────────────────────────────────────────────────────
  const dailyStats = {
    total:   todayData.length,
    gradeA:  todayData.filter(p => p.grade === 'A').length,
    gradeB:  todayData.filter(p => p.grade === 'B').length,
    gradeC:  todayData.filter(p => p.grade === 'C').length,
    avgVFA:  todayData.length > 0
      ? (todayData.reduce((s,p) => s + p.vfa, 0) / todayData.length).toFixed(4)
      : '0.0000',
    minVFA:  todayData.length > 0
      ? Math.min(...todayData.map(p => p.vfa)).toFixed(4)
      : '0.0000',
    maxVFA:  todayData.length > 0
      ? Math.max(...todayData.map(p => p.vfa)).toFixed(4)
      : '0.0000',
    rejectionRate: todayData.length > 0
      ? ((todayData.filter(p => p.grade === 'C').length /
          todayData.length) * 100).toFixed(1)
      : '0.0',
  }

  // ── Pie chart data ──────────────────────────────────────────────────────────
  const pieData = [
    { name: 'Grade A', value: dailyStats.gradeA, color: getGradeColor('A') },
    { name: 'Grade B', value: dailyStats.gradeB, color: getGradeColor('B') },
    { name: 'Grade C', value: dailyStats.gradeC, color: getGradeColor('C') },
  ].filter(d => d.value > 0)

  // ── Last 7 days trend ───────────────────────────────────────────────────────
  const last7Days = getLastNDays(7).map(date => {
    const dayData = predictions.filter(p => p.date === date)
    return {
      date:    date.slice(5),
      total:   dayData.length,
      gradeA:  dayData.filter(p => p.grade === 'A').length,
      gradeB:  dayData.filter(p => p.grade === 'B').length,
      gradeC:  dayData.filter(p => p.grade === 'C').length,
      avgVFA:  dayData.length > 0
        ? parseFloat(
            (dayData.reduce((s,p) => s + p.vfa, 0) /
             dayData.length).toFixed(4)
          )
        : 0,
    }
  })

  // ── Top farmers ─────────────────────────────────────────────────────────────
  const farmerMap = {}
  todayData.forEach(p => {
    if (!farmerMap[p.farmer_id]) {
      farmerMap[p.farmer_id] = { total:0, gradeA:0, gradeB:0, gradeC:0 }
    }
    farmerMap[p.farmer_id].total++
    farmerMap[p.farmer_id][`grade${p.grade}`]++
  })
  const topFarmers = Object.entries(farmerMap)
    .map(([id, stats]) => ({ id, ...stats }))
    .sort((a,b) => b.total - a.total)
    .slice(0, 5)

  // ── Loading ─────────────────────────────────────────────────────────────────
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-12 h-12 border-4 border-[#1F3864]
                        border-t-transparent rounded-full animate-spin" />
      </div>
    )
  }

  // ── Error ───────────────────────────────────────────────────────────────────
  if (error) {
    return (
      <div className="bg-red-50 border border-red-200
                      rounded-xl p-6 text-center">
        <p className="text-red-600">{error}</p>
      </div>
    )
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">

      {/* ── Date Selector ─────────────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm p-4
                      border border-gray-100
                      flex items-center justify-between">
        <h3 className="text-base font-bold text-[#1F3864]">
          📅 Select Date
        </h3>
        <div className="flex items-center gap-3">
          <input
            type="date"
            value={selectedDate}
            max={getToday()}
            onChange={e => setSelectedDate(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg
                       text-sm focus:outline-none
                       focus:ring-2 focus:ring-[#1F3864]"
          />
          <button
            onClick={() => setSelectedDate(getToday())}
            className="px-3 py-2 bg-[#1F3864] text-white
                       text-xs font-medium rounded-lg
                       hover:bg-[#162a4a] transition"
          >
            Today
          </button>
        </div>
      </div>

      {/* ── Stats Cards ───────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Collections', value: dailyStats.total,
            icon: '📋', bg: 'bg-blue-50',   color: 'text-[#1F3864]' },
          { label: 'Average VFA',       value: dailyStats.avgVFA,
            icon: '📊', bg: 'bg-green-50',  color: 'text-green-700' },
          { label: 'Rejection Rate',
            value: `${dailyStats.rejectionRate}%`,
            icon: '❌', bg: 'bg-red-50',    color: 'text-red-700'   },
          { label: 'Grade C Alerts',    value: dailyStats.gradeC,
            icon: '⚠️', bg: 'bg-orange-50', color: 'text-orange-700'},
        ].map((s,i) => (
          <div key={i}
            className={`${s.bg} rounded-xl p-4
                         border border-gray-100 shadow-sm`}>
            <div className="flex items-center justify-between mb-2">
              <span className="text-gray-500 text-xs font-medium">
                {s.label}
              </span>
              <span className="text-lg">{s.icon}</span>
            </div>
            <p className={`text-3xl font-bold ${s.color}`}>
              {s.value}
            </p>
          </div>
        ))}
      </div>

      {/* ── Grade Distribution + Pie Chart ────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

        {/* Grade bars */}
        <div className="bg-white rounded-xl shadow-sm p-5
                        border border-gray-100">
          <h4 className="text-sm font-bold text-[#1F3864] mb-4">
            Grade Distribution
          </h4>
          <div className="space-y-4">
            {[
              { grade: 'A', count: dailyStats.gradeA },
              { grade: 'B', count: dailyStats.gradeB },
              { grade: 'C', count: dailyStats.gradeC },
            ].map(g => (
              <div key={g.grade}>
                <div className="flex items-center justify-between mb-1.5">
                  <span className={`text-xs font-bold px-2 py-0.5
                                    rounded-lg
                                    ${getGradeBadgeColor(g.grade)}`}>
                    {getGradeIcon(g.grade)} Grade {g.grade}
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-gray-700">
                      {g.count}
                    </span>
                    <span className="text-xs text-gray-400">
                      ({dailyStats.total > 0
                        ? ((g.count/dailyStats.total)*100).toFixed(1)
                        : 0}%)
                    </span>
                  </div>
                </div>
                <div className="bg-gray-100 rounded-full h-3">
                  <div
                    className="h-3 rounded-full transition-all duration-500"
                    style={{
                      width: dailyStats.total > 0
                        ? `${(g.count/dailyStats.total)*100}%`
                        : '0%',
                      backgroundColor: getGradeColor(g.grade)
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          {/* VFA range */}
          <div className="mt-4 pt-4 border-t border-gray-100
                          grid grid-cols-3 gap-2 text-center">
            {[
              { label: 'Min VFA', value: dailyStats.minVFA,
                color: 'text-green-700' },
              { label: 'Avg VFA', value: dailyStats.avgVFA,
                color: 'text-[#1F3864]' },
              { label: 'Max VFA', value: dailyStats.maxVFA,
                color: 'text-red-700' },
            ].map((v,i) => (
              <div key={i}>
                <p className="text-gray-400 text-xs mb-1">{v.label}</p>
                <p className={`font-bold text-sm ${v.color}`}>
                  {v.value}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Pie chart */}
        <div className="bg-white rounded-xl shadow-sm p-5
                        border border-gray-100">
          <h4 className="text-sm font-bold text-[#1F3864] mb-4">
            Grade Breakdown
          </h4>
          {pieData.length > 0 ? (
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={55}
                  outerRadius={85}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {pieData.map((entry, i) => (
                    <Cell key={i} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: '#1F3864', border: 'none',
                    borderRadius: '8px', color: 'white',
                    fontSize: '12px',
                  }}
                  formatter={(val, name) => [
                    `${val} (${((val/dailyStats.total)*100).toFixed(1)}%)`,
                    name
                  ]}
                />
                <Legend
                  iconType="circle"
                  iconSize={10}
                  formatter={(val) => (
                    <span style={{ fontSize: '12px', color: '#444' }}>
                      {val}
                    </span>
                  )}
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-48">
              <p className="text-gray-400 text-sm">No data for selected date</p>
            </div>
          )}
        </div>
      </div>

      {/* ── 7-Day VFA Trend ───────────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm p-5
                      border border-gray-100">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h4 className="text-base font-bold text-[#1F3864]">
              7-Day Average VFA Trend
            </h4>
            <p className="text-gray-400 text-xs mt-0.5">
              Daily average VFA over last 7 days
            </p>
          </div>
        </div>
        <ResponsiveContainer width="100%" height={240}>
          <LineChart
            data={last7Days}
            margin={{ top:5, right:20, left:0, bottom:5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
            <XAxis
              dataKey="date"
              tick={{ fontSize:11, fill:'#9CA3AF' }}
              axisLine={false} tickLine={false}
            />
            <YAxis
              domain={[0, 0.12]}
              tick={{ fontSize:11, fill:'#9CA3AF' }}
              axisLine={false} tickLine={false}
              tickFormatter={v => v.toFixed(3)}
            />
            <Tooltip
              contentStyle={{
                background: '#1F3864', border: 'none',
                borderRadius: '8px', color: 'white',
                fontSize: '12px',
              }}
              formatter={(val) => [val.toFixed(4), 'Avg VFA']}
            />
            <ReferenceLine y={0.05} stroke="#C9A84C"
              strokeDasharray="5 5" strokeWidth={1.5} />
            <ReferenceLine y={0.08} stroke="#C00000"
              strokeDasharray="5 5" strokeWidth={1.5} />
            <Line
              type="monotone" dataKey="avgVFA"
              stroke="#1F3864" strokeWidth={2.5}
              dot={{ fill: '#1F3864', r: 5, strokeWidth: 0 }}
              activeDot={{ r: 7, fill: '#C9A84C' }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* ── 7-Day Grade Bar Chart ─────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm p-5
                      border border-gray-100">
        <h4 className="text-base font-bold text-[#1F3864] mb-4">
          7-Day Grade Distribution
        </h4>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart
            data={last7Days}
            margin={{ top:5, right:20, left:0, bottom:5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
            <XAxis
              dataKey="date"
              tick={{ fontSize:11, fill:'#9CA3AF' }}
              axisLine={false} tickLine={false}
            />
            <YAxis
              tick={{ fontSize:11, fill:'#9CA3AF' }}
              axisLine={false} tickLine={false}
            />
            <Tooltip
              contentStyle={{
                background: '#1F3864', border: 'none',
                borderRadius: '8px', color: 'white',
                fontSize: '12px',
              }}
            />
            <Legend
              iconType="circle" iconSize={10}
              formatter={(val) => (
                <span style={{ fontSize:'12px', color:'#444' }}>
                  {val}
                </span>
              )}
            />
            <Bar dataKey="gradeA" name="Grade A"
              fill={getGradeColor('A')} radius={[3,3,0,0]} />
            <Bar dataKey="gradeB" name="Grade B"
              fill={getGradeColor('B')} radius={[3,3,0,0]} />
            <Bar dataKey="gradeC" name="Grade C"
              fill={getGradeColor('C')} radius={[3,3,0,0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* ── Top Farmers Table ─────────────────────────────────────────────── */}
      {topFarmers.length > 0 && (
        <div className="bg-white rounded-xl shadow-sm
                        border border-gray-100 overflow-hidden">
          <div className="px-5 py-4 border-b border-gray-100">
            <h4 className="text-base font-bold text-[#1F3864]">
              Top Farmers — {selectedDate}
            </h4>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-[#F4F6F9]">
                <tr>
                  {['Farmer ID','Total','Grade A',
                    'Grade B','Grade C','Status'].map(h => (
                    <th key={h}
                      className="px-4 py-3 text-left text-xs
                                 font-semibold text-gray-500 uppercase">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {topFarmers.map((f, i) => (
                  <tr key={f.id}
                    className={i % 2 === 0
                      ? 'bg-white hover:bg-[#F4F6F9]'
                      : 'bg-gray-50 hover:bg-[#F4F6F9]'
                    }>
                    <td className="px-4 py-3 font-semibold
                                   text-[#1F3864] text-sm">
                      {f.id}
                    </td>
                    <td className="px-4 py-3 text-gray-700
                                   font-bold text-sm">
                      {f.total}
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-xs font-bold
                                       text-green-700">
                        {f.gradeA}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-xs font-bold
                                       text-yellow-700">
                        {f.gradeB}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className="text-xs font-bold
                                       text-red-700">
                        {f.gradeC}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-bold px-2
                                        py-1 rounded-lg
                                        ${f.gradeC > 0
                                          ? 'bg-red-100 text-red-700'
                                          : 'bg-green-100 text-green-700'
                                        }`}>
                        {f.gradeC > 0 ? '⚠️ Has Alerts' : '✅ Good'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

    </div>
  )
}

export default DailySummary