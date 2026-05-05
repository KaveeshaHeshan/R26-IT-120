// src/components/dashboard/FarmerProfile.jsx

import { useState }                         from 'react'
import useFarmerHistory                     from '../../hooks/useFarmerHistory'
import { LineChart, Line, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer,
         ReferenceLine, BarChart, Bar,
         Cell }                             from 'recharts'
import { getGradeColor, getGradeBadgeColor,
         getGradeIcon, getGradeLabel }      from '../../utils/gradeHelper'
import { formatDateReadable, formatDate }   from '../../utils/dateHelper'

const FarmerProfile = () => {

  const [selectedFarmer, setSelectedFarmer] = useState('')
  const [filterGrade,    setFilterGrade]    = useState('')

  const {
    history,
    farmerStats,
    allFarmers,
    loading,
    error,
    getQualityTrend,
    getTrendLabel,
    getTrendColor,
    filterByGrade,
  } = useFarmerHistory(selectedFarmer, 30)

  const filteredHistory = filterByGrade(filterGrade)

  // ── Trend icon ──────────────────────────────────────────────────────────────
  const trendIcon = () => {
    const t = getQualityTrend()
    if (t === 'improving')  return '📈'
    if (t === 'degrading')  return '📉'
    return '➡️'
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">

      {/* ── Farmer Selector ───────────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm p-5
                      border border-gray-100">
        <h3 className="text-base font-bold text-[#1F3864] mb-4">
          👨‍🌾 Select Farmer
        </h3>
        <div className="flex flex-col md:flex-row gap-3">

          {/* Farmer dropdown */}
          <select
            value={selectedFarmer}
            onChange={e => setSelectedFarmer(e.target.value)}
            className="flex-1 px-4 py-2.5 border border-gray-300
                       rounded-xl text-sm focus:outline-none
                       focus:ring-2 focus:ring-[#1F3864]
                       bg-white text-gray-700"
          >
            <option value="">-- Select Farmer ID --</option>
            {allFarmers.map(f => (
              <option key={f.id} value={f.id}>
                {f.label}
              </option>
            ))}
          </select>

          {/* Grade filter */}
          <select
            value={filterGrade}
            onChange={e => setFilterGrade(e.target.value)}
            className="w-full md:w-48 px-4 py-2.5 border border-gray-300
                       rounded-xl text-sm focus:outline-none
                       focus:ring-2 focus:ring-[#1F3864]
                       bg-white text-gray-700"
          >
            <option value="">All Grades</option>
            <option value="A">Grade A only</option>
            <option value="B">Grade B only</option>
            <option value="C">Grade C only</option>
          </select>

          {/* Clear button */}
          {selectedFarmer && (
            <button
              onClick={() => {
                setSelectedFarmer('')
                setFilterGrade('')
              }}
              className="px-4 py-2.5 bg-gray-100 text-gray-600
                         rounded-xl text-sm hover:bg-gray-200 transition"
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {/* ── No farmer selected ────────────────────────────────────────────── */}
      {!selectedFarmer && (
        <div className="flex flex-col items-center justify-center
                        min-h-[40vh] text-center px-4">
          <div className="text-6xl mb-4">👨‍🌾</div>
          <h3 className="text-xl font-bold text-[#1F3864] mb-2">
            Select a Farmer
          </h3>
          <p className="text-gray-500 text-sm">
            Choose a farmer ID to view VFA quality history and trends
          </p>
        </div>
      )}

      {/* ── Loading ───────────────────────────────────────────────────────── */}
      {selectedFarmer && loading && (
        <div className="flex items-center justify-center min-h-[30vh]">
          <div className="w-10 h-10 border-4 border-[#1F3864]
                          border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* ── Error ─────────────────────────────────────────────────────────── */}
      {error && (
        <div className="bg-red-50 border border-red-200
                        rounded-xl p-4 text-center">
          <p className="text-red-600 text-sm">{error}</p>
        </div>
      )}

      {/* ── Farmer Stats ──────────────────────────────────────────────────── */}
      {selectedFarmer && !loading && farmerStats && (
        <>

          {/* Stats cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              {
                label: 'Total Sessions',
                value: farmerStats.total,
                icon:  '📋',
                color: 'text-[#1F3864]',
                bg:    'bg-blue-50',
              },
              {
                label: 'Average VFA',
                value: farmerStats.avgVFA,
                icon:  '📊',
                color: `text-[${getGradeColor(
                  parseFloat(farmerStats.avgVFA) < 0.05 ? 'A'
                  : parseFloat(farmerStats.avgVFA) < 0.08 ? 'B' : 'C'
                )}]`,
                bg: 'bg-green-50',
              },
              {
                label: 'Best VFA',
                value: farmerStats.minVFA,
                icon:  '✅',
                color: 'text-green-700',
                bg:    'bg-green-50',
              },
              {
                label: 'Worst VFA',
                value: farmerStats.maxVFA,
                icon:  '⚠️',
                color: farmerStats.hasAlerts
                  ? 'text-red-700'
                  : 'text-yellow-700',
                bg: farmerStats.hasAlerts
                  ? 'bg-red-50'
                  : 'bg-yellow-50',
              },
            ].map((s, i) => (
              <div key={i}
                className={`${s.bg} rounded-xl p-4
                             border border-gray-100 shadow-sm`}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-gray-500 text-xs font-medium">
                    {s.label}
                  </span>
                  <span className="text-lg">{s.icon}</span>
                </div>
                <p className={`text-2xl font-bold ${s.color}`}>
                  {s.value}
                </p>
              </div>
            ))}
          </div>

          {/* Grade summary + trend */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

            {/* Grade distribution */}
            <div className="bg-white rounded-xl shadow-sm p-5
                            border border-gray-100">
              <h4 className="text-sm font-bold text-[#1F3864] mb-4">
                Grade Distribution
              </h4>
              <div className="space-y-3">
                {[
                  { grade: 'A', count: farmerStats.gradeA,
                    pct: farmerStats.gradeAPercent },
                  { grade: 'B', count: farmerStats.gradeB,
                    pct: farmerStats.gradeBPercent },
                  { grade: 'C', count: farmerStats.gradeC,
                    pct: farmerStats.gradeCPercent },
                ].map(g => (
                  <div key={g.grade}>
                    <div className="flex items-center
                                    justify-between mb-1">
                      <div className="flex items-center gap-2">
                        <span className={`text-xs font-bold px-2
                                          py-0.5 rounded-lg
                                          ${getGradeBadgeColor(g.grade)}`}>
                          {getGradeIcon(g.grade)} {g.grade}
                        </span>
                        <span className="text-gray-500 text-xs">
                          {g.count} sessions
                        </span>
                      </div>
                      <span className="text-xs font-medium text-gray-600">
                        {g.pct}%
                      </span>
                    </div>
                    <div className="bg-gray-100 rounded-full h-2">
                      <div
                        className="h-2 rounded-full transition-all"
                        style={{
                          width: `${g.pct}%`,
                          backgroundColor: getGradeColor(g.grade)
                        }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quality trend */}
            <div className="bg-white rounded-xl shadow-sm p-5
                            border border-gray-100">
              <h4 className="text-sm font-bold text-[#1F3864] mb-4">
                Quality Trend
              </h4>
              <div className="flex flex-col items-center
                              justify-center h-32 gap-3">
                <div className="text-5xl">
                  {trendIcon()}
                </div>
                <p
                  className="text-xl font-bold"
                  style={{ color: getTrendColor() }}
                >
                  {getTrendLabel()}
                </p>
                <p className="text-gray-400 text-xs text-center">
                  Based on last 5 vs previous 5 sessions
                </p>
              </div>

              {/* Latest info */}
              <div className="mt-4 p-3 bg-[#F4F6F9] rounded-lg">
                <div className="flex justify-between text-xs">
                  <span className="text-gray-500">Latest Grade:</span>
                  <span className={`font-bold
                    ${getGradeBadgeColor(farmerStats.latestGrade)
                      .split(' ')[1]}`}>
                    {getGradeIcon(farmerStats.latestGrade)}{' '}
                    {farmerStats.latestGrade}
                  </span>
                </div>
                <div className="flex justify-between text-xs mt-1">
                  <span className="text-gray-500">Latest VFA:</span>
                  <span className="font-bold text-[#1F3864]">
                    {farmerStats.latestVFA}
                  </span>
                </div>
                <div className="flex justify-between text-xs mt-1">
                  <span className="text-gray-500">Last session:</span>
                  <span className="text-gray-600">
                    {farmerStats.latestDate}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* VFA history chart */}
          <div className="bg-white rounded-xl shadow-sm p-5
                          border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h4 className="text-base font-bold text-[#1F3864]">
                  VFA History — {selectedFarmer}
                </h4>
                <p className="text-gray-400 text-xs mt-0.5">
                  Last {filteredHistory.length} sessions
                </p>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={260}>
              <LineChart
                data={filteredHistory}
                margin={{ top:5, right:20, left:0, bottom:5 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize:10, fill:'#9CA3AF' }}
                  axisLine={false} tickLine={false}
                />
                <YAxis
                  domain={[0, 0.12]}
                  tick={{ fontSize:10, fill:'#9CA3AF' }}
                  axisLine={false} tickLine={false}
                  tickFormatter={v => v.toFixed(3)}
                />
                <Tooltip
                  contentStyle={{
                    background: '#1F3864', border: 'none',
                    borderRadius: '8px', color: 'white',
                    fontSize: '12px',
                  }}
                  formatter={(val) => [val.toFixed(4), 'VFA']}
                />
                <ReferenceLine y={0.05} stroke="#C9A84C"
                  strokeDasharray="5 5" strokeWidth={1.5} />
                <ReferenceLine y={0.08} stroke="#C00000"
                  strokeDasharray="5 5" strokeWidth={1.5} />
                <Line
                  type="monotone" dataKey="vfa"
                  stroke="#1F3864" strokeWidth={2.5}
                  dot={{ fill: '#1F3864', r: 4, strokeWidth: 0 }}
                  activeDot={{ r: 6, fill: '#C9A84C' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Grade bar chart */}
          <div className="bg-white rounded-xl shadow-sm p-5
                          border border-gray-100">
            <h4 className="text-base font-bold text-[#1F3864] mb-4">
              VFA per Session
            </h4>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart
                data={filteredHistory}
                margin={{ top:5, right:20, left:0, bottom:5 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize:10, fill:'#9CA3AF' }}
                  axisLine={false} tickLine={false}
                />
                <YAxis
                  domain={[0, 0.12]}
                  tick={{ fontSize:10, fill:'#9CA3AF' }}
                  axisLine={false} tickLine={false}
                  tickFormatter={v => v.toFixed(3)}
                />
                <Tooltip
                  contentStyle={{
                    background: '#1F3864', border: 'none',
                    borderRadius: '8px', color: 'white',
                    fontSize: '12px',
                  }}
                  formatter={(val) => [val.toFixed(4), 'VFA']}
                />
                <Bar dataKey="vfa" radius={[4,4,0,0]}>
                  {filteredHistory.map((item, i) => (
                    <Cell
                      key={i}
                      fill={getGradeColor(item.grade)}
                    />
                  ))}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Session history table */}
          <div className="bg-white rounded-xl shadow-sm
                          border border-gray-100 overflow-hidden">
            <div className="px-5 py-4 border-b border-gray-100
                            flex items-center justify-between">
              <h4 className="text-base font-bold text-[#1F3864]">
                Session History
              </h4>
              <span className="text-gray-400 text-xs">
                {filteredHistory.length} records
              </span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-[#F4F6F9]">
                  <tr>
                    {['Date','Time','VFA','pH',
                      'Turbidity','Temp','Grade'].map(h => (
                      <th key={h}
                        className="px-4 py-3 text-left text-xs
                                   font-semibold text-gray-500 uppercase">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {[...filteredHistory].reverse().map((item, i) => (
                    <tr key={item.id}
                      className={i % 2 === 0
                        ? 'bg-white hover:bg-[#F4F6F9]'
                        : 'bg-gray-50 hover:bg-[#F4F6F9]'
                      }>
                      <td className="px-4 py-3 text-gray-600 text-xs">
                        {item.date}
                      </td>
                      <td className="px-4 py-3 text-gray-600 text-xs">
                        {item.time}
                      </td>
                      <td className="px-4 py-3 font-bold text-xs"
                        style={{ color: getGradeColor(item.grade) }}>
                        {item.vfa.toFixed(4)}
                      </td>
                      <td className="px-4 py-3 text-gray-600 text-xs">
                        {item.pH.toFixed(2)}
                      </td>
                      <td className="px-4 py-3 text-gray-600 text-xs">
                        {item.turbidity.toFixed(1)}
                      </td>
                      <td className="px-4 py-3 text-gray-600 text-xs">
                        {item.temperature.toFixed(1)}°C
                      </td>
                      <td className="px-4 py-3">
                        <span className={`text-xs font-bold px-2
                                          py-1 rounded-lg
                                          ${getGradeBadgeColor(item.grade)}`}>
                          {getGradeIcon(item.grade)} {item.grade}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

        </>
      )}

      {/* ── No history ────────────────────────────────────────────────────── */}
      {selectedFarmer && !loading && !farmerStats && (
        <div className="flex flex-col items-center justify-center
                        min-h-[30vh] text-center">
          <div className="text-5xl mb-3">📭</div>
          <p className="text-gray-500 text-sm">
            No history found for {selectedFarmer}
          </p>
        </div>
      )}

    </div>
  )
}

export default FarmerProfile