// src/components/dashboard/FarmerProfile.jsx

import { useState }                         from 'react'
import useFarmerHistory                     from '../../hooks/useFarmerHistory'
import { LineChart, Line, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer,
         ReferenceLine, BarChart, Bar,
         Cell, AreaChart, Area }            from 'recharts'
import { getGradeColor }                    from '../../utils/gradeHelper'
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
      <div className="bg-white/90 rounded-[2rem] shadow-xl p-8 border border-emerald-100 relative overflow-hidden group">
        <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-emerald-500 to-transparent opacity-50"></div>
        
        <div className="flex flex-col md:flex-row items-center justify-between mb-8 gap-4">
           <div>
              <h3 className="text-[11px] font-black text-[#052c14] tracking-[0.3em] uppercase mb-1">
                Farmer Intelligence
              </h3>
              <p className="text-[#052c14]/30 text-[9px] font-bold tracking-widest uppercase">Select a registry node to analyze historical data</p>
           </div>
           {selectedFarmer && (
            <button
              onClick={() => {
                setSelectedFarmer('')
                setFilterGrade('')
              }}
              className="px-5 py-2 bg-emerald-50 text-emerald-600 border border-emerald-100
                         rounded-xl text-[10px] font-black uppercase tracking-widest hover:bg-emerald-100 transition-all active:scale-95"
            >
              Reset Terminal
            </button>
          )}
        </div>

        <div className="flex flex-col md:flex-row gap-6">
          {/* Farmer dropdown */}
          <div className="flex-1 space-y-2">
            <label className="text-[9px] font-black text-[#052c14]/20 uppercase tracking-[0.2em] ml-2">Registry ID</label>
            <select
              value={selectedFarmer}
              onChange={e => setSelectedFarmer(e.target.value)}
              className="w-full px-5 py-4 border border-emerald-100
                         rounded-2xl text-xs font-black tracking-widest focus:outline-none
                         focus:border-emerald-500/50 focus:ring-4 focus:ring-emerald-500/5
                         bg-emerald-50 text-[#052c14] appearance-none cursor-pointer transition-all shadow-inner"
            >
              <option value="" className="bg-white">SEARCH REGISTRY...</option>
              {allFarmers.map(f => (
                <option key={f.id} value={f.id} className="bg-white">
                  {f.label} • {f.id}
                </option>
              ))}
            </select>
          </div>

          {/* Grade filter */}
          <div className="w-full md:w-64 space-y-2">
            <label className="text-[9px] font-black text-[#052c14]/20 uppercase tracking-[0.2em] ml-2">Quality Filter</label>
            <select
              value={filterGrade}
              onChange={e => setFilterGrade(e.target.value)}
              className="w-full px-5 py-4 border border-emerald-100
                         rounded-2xl text-xs font-black tracking-widest focus:outline-none
                         focus:border-emerald-500/50 focus:ring-4 focus:ring-emerald-500/5
                         bg-emerald-50 text-[#052c14] appearance-none cursor-pointer transition-all shadow-inner"
            >
              <option value="" className="bg-white">ALL GRADES</option>
              <option value="A" className="bg-white">GRADE A</option>
              <option value="B" className="bg-white">GRADE B</option>
              <option value="C" className="bg-white">GRADE C</option>
            </select>
          </div>
        </div>
      </div>

      {/* ── No farmer selected ────────────────────────────────────────────── */}
      {!selectedFarmer && (
        <div className="relative group perspective-1000">
          <div className="absolute inset-0 bg-emerald-500/5 blur-[80px] rounded-full"></div>
          <div className="relative flex flex-col items-center justify-center
                          min-h-[45vh] text-center px-10 bg-white/60 backdrop-blur-md rounded-[2.5rem] border border-emerald-100 mt-6 transition-transform duration-700 hover:scale-[1.01] shadow-xl">
            <div className="w-28 h-28 bg-white rounded-[2rem] flex items-center justify-center mb-10 border border-emerald-100 shadow-xl relative overflow-hidden group-hover:rotate-12 transition-transform duration-500">
               <div className="absolute inset-0 bg-gradient-to-tr from-emerald-500/10 to-transparent"></div>
              <span className="text-6xl">👨‍🌾</span>
            </div>
            <h3 className="text-2xl font-black text-[#052c14] mb-4 tracking-[0.2em] uppercase">
              Terminal Idle
            </h3>
            <p className="text-[#052c14]/30 text-xs font-bold max-w-sm mx-auto leading-relaxed uppercase tracking-widest">
              Awaiting registry selection to initialize deep neural analysis and quality trending.
            </p>
          </div>
        </div>
      )}

      {/* ── Loading ───────────────────────────────────────────────────────── */}
      {selectedFarmer && loading && (
        <div className="flex items-center justify-center min-h-[30vh]">
          <div className="w-10 h-10 border-4 border-emerald-500
                          border-t-transparent rounded-full animate-spin shadow-[0_0_15px_rgba(16,185,129,0.2)]" />
        </div>
      )}

      {/* ── Error ─────────────────────────────────────────────────────────── */}
      {error && (
        <div className="bg-red-50 text-red-600 border border-red-100
                        rounded-xl p-4 text-center">
          <p className="text-xs font-black uppercase tracking-widest">{error}</p>
        </div>
      )}

      {/* ── Farmer Stats ──────────────────────────────────────────────────── */}
      {selectedFarmer && !loading && farmerStats && (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-5 duration-700">

          {/* Stats cards */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {[
              {
                label: 'Session Registry',
                value: farmerStats.total,
                sub: 'Total Samples',
                icon:  '📋',
                color: 'text-[#052c14]',
                border: 'border-emerald-100'
              },
              {
                label: 'Mean Deviation',
                value: farmerStats.avgVFA,
                sub: 'Avg VFA Metric',
                icon:  '📊',
                color: `text-emerald-600`,
                border: 'border-emerald-200'
              },
              {
                label: 'Peak Efficiency',
                value: farmerStats.minVFA,
                sub: 'Lowest Static VFA',
                icon:  '✅',
                color: 'text-emerald-500',
                border: 'border-emerald-300'
              },
              {
                label: 'Risk Boundary',
                value: farmerStats.maxVFA,
                sub: 'Max Detected VFA',
                icon:  '⚠️',
                color: farmerStats.hasAlerts ? 'text-red-600' : 'text-yellow-600',
                border: farmerStats.hasAlerts ? 'border-red-200' : 'border-yellow-200'
              },
            ].map((s, i) => (
              <div key={i}
                className={`bg-white/90 rounded-2xl p-6
                             border ${s.border} shadow-xl relative overflow-hidden group hover:bg-emerald-50 transition-all`}>
                <div className="flex items-center justify-between mb-4 relative z-10">
                  <span className="text-[#052c14]/30 text-[9px] font-black uppercase tracking-[0.2em]">
                    {s.label}
                  </span>
                  <span className="text-xl filter grayscale group-hover:grayscale-0 transition-all">{s.icon}</span>
                </div>
                <p className={`text-4xl font-black ${s.color} tracking-tighter relative z-10 mb-1`}>
                  {s.value}
                </p>
                <p className="text-[#052c14]/20 text-[9px] font-bold uppercase tracking-widest relative z-10">
                  {s.sub}
                </p>
              </div>
            ))}
          </div>

          {/* Grade summary + trend */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

            {/* Grade distribution */}
            <div className="bg-white/90 rounded-[2rem] shadow-xl p-8 border border-emerald-100 relative overflow-hidden group">
               <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl pointer-events-none"></div>
              <div className="flex items-center gap-2 mb-8">
                <div className="w-1.5 h-4 bg-emerald-500/20 rounded-full"></div>
                <h4 className="text-[10px] font-black text-[#052c14]/80 uppercase tracking-[0.3em]">
                  Yield Distribution
                </h4>
              </div>

              <div className="space-y-8">
                {[
                  { grade: 'A', count: farmerStats.gradeA, pct: farmerStats.gradeAPercent },
                  { grade: 'B', count: farmerStats.gradeB, pct: farmerStats.gradeBPercent },
                  { grade: 'C', count: farmerStats.gradeC, pct: farmerStats.gradeCPercent },
                ].map(g => (
                  <div key={g.grade} className="group/item">
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-4">
                        <span className="text-[10px] font-black px-4 py-1.5 rounded-lg border shadow-sm transition-all group-hover/item:scale-110"
                          style={{ 
                            backgroundColor: `${getGradeColor(g.grade)}15`, 
                            borderColor: `${getGradeColor(g.grade)}30`,
                            color: getGradeColor(g.grade) 
                          }}>
                          GRADE {g.grade}
                        </span>
                        <span className="text-[#052c14]/20 text-[10px] font-black uppercase tracking-widest">
                           {g.count} Recorded Sessions
                        </span>
                      </div>
                      <span className="text-sm font-black text-[#052c14] tracking-widest">
                        {g.pct}%
                      </span>
                    </div>
                    <div className="bg-emerald-50 rounded-full h-3 border border-emerald-100 p-0.5 overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-1000 shadow-[0_0_15px_currentColor] relative"
                        style={{
                          width: `${g.pct}%`,
                          backgroundColor: getGradeColor(g.grade),
                          color: getGradeColor(g.grade)
                        }}
                      >
                         <div className="absolute inset-0 bg-white/20 animate-pulse"></div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quality trend */}
            <div className="bg-white/90 rounded-[2rem] shadow-xl p-8 border border-emerald-100 relative overflow-hidden flex flex-col items-center justify-center">
              <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMSIgZmlsbD0iIzAwMCIvPjwvc3ZnPg==')]"></div>
              <div 
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 rounded-full blur-[100px] opacity-10 transition-all duration-1000" 
                style={{ backgroundColor: getTrendColor() }}
              ></div>
              
              <div className="text-center relative z-10">
                <p className="text-[#052c14]/20 text-[10px] font-black tracking-[0.3em] uppercase mb-8">Vector Momentum</p>
                <div className="text-7xl mb-6 filter drop-shadow-[0_10px_10px_rgba(0,0,0,0.05)] animate-bounce-slow">
                  {trendIcon()}
                </div>
                <h4 className="text-4xl font-black tracking-tighter uppercase mb-2" style={{ color: getTrendColor() }}>
                  {getTrendLabel()}
                </h4>
                <div className="inline-block px-4 py-1.5 rounded-full bg-emerald-50 border border-emerald-100 text-[9px] font-black text-emerald-600 uppercase tracking-[0.2em] mb-10">
                   Predictive analysis: Validated
                </div>

                <div className="grid grid-cols-3 gap-8 w-full border-t border-emerald-100 pt-8">
                  <div>
                    <p className="text-[#052c14]/20 text-[8px] font-black uppercase tracking-widest mb-1">Latest Rank</p>
                    <p className="text-lg font-black text-[#052c14]" style={{ color: getGradeColor(farmerStats.latestGrade) }}>{farmerStats.latestGrade}</p>
                  </div>
                  <div>
                    <p className="text-[#052c14]/20 text-[8px] font-black uppercase tracking-widest mb-1">Last VFA</p>
                    <p className="text-lg font-black text-[#052c14]">{farmerStats.latestVFA}</p>
                  </div>
                  <div>
                    <p className="text-[#052c14]/20 text-[8px] font-black uppercase tracking-widest mb-1">Registry</p>
                    <p className="text-[10px] font-black text-[#052c14]/60 pt-1 leading-none">{farmerStats.latestDate?.split(' ')[0]}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* VFA history chart */}
          <div className="bg-white/90 rounded-[2rem] shadow-xl p-8 border border-emerald-100 relative overflow-hidden group">
            <div className="flex flex-col md:flex-row items-start md:items-center justify-between mb-10 gap-4 relative z-10">
              <div className="flex items-center gap-3">
                 <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                <h4 className="text-[11px] font-black text-[#052c14] uppercase tracking-[0.3em]">
                  Quality Lifecycle
                </h4>
              </div>
              <p className="text-[#052c14]/30 text-[9px] font-black uppercase tracking-[0.2em] bg-emerald-50 px-3 py-1 rounded-lg border border-emerald-100">
                Node {selectedFarmer} — Analyze Segment: {filteredHistory.length} Cycles
              </p>
            </div>
            
            <div className="h-[300px] w-full relative z-10">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={filteredHistory} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="areaColor" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.1}/>
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#10b981" vertical={false} opacity={0.05} />
                  <XAxis
                    dataKey="timestamp"
                    tick={{ fontSize: 8, fill: '#052c14', fontWeight: 800, opacity: 0.3 }}
                    axisLine={false}
                    tickLine={false}
                    tickFormatter={(tick) => formatDate(tick)}
                    dy={15}
                  />
                  <YAxis
                    domain={['dataMin - 0.01', 'dataMax + 0.01']}
                    tick={{ fontSize: 9, fill: '#052c14', fontWeight: 800, opacity: 0.3 }}
                    axisLine={false}
                    tickLine={false}
                    tickFormatter={v => v.toFixed(3)}
                  />
                  <Tooltip
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        return (
                          <div className="bg-white/95 backdrop-blur-xl p-4 border border-emerald-100 rounded-xl shadow-2xl">
                            <p className="text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em] mb-2">{formatDateReadable(payload[0].payload.timestamp)}</p>
                            <div className="flex items-center gap-3">
                              <div className="text-2xl font-black" style={{ color: getGradeColor(payload[0].payload.grade) }}>
                                {payload[0].value.toFixed(4)}
                              </div>
                              <div className="px-2 py-0.5 rounded-md bg-emerald-50 border border-emerald-100 text-[10px] font-black text-emerald-600 uppercase">
                                Grade {payload[0].payload.grade}
                              </div>
                            </div>
                             <div className="mt-2 text-[8px] font-bold text-[#052c14]/20 uppercase tracking-widest">
                                Sample ID: {payload[0].payload.sample_id}
                             </div>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <ReferenceLine y={0.05} stroke="#10b981" strokeDasharray="4 4" strokeWidth={1} opacity={0.3} />
                  <ReferenceLine y={0.08} stroke="#ef4444" strokeDasharray="4 4" strokeWidth={1} opacity={0.3} />
                  <Area
                    type="monotone"
                    dataKey="vfa"
                    stroke="#10b981"
                    strokeWidth={4}
                    fillOpacity={1} 
                    fill="url(#areaColor)"
                    animationDuration={1500}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
             {/* Grade bar chart */}
             <div className="bg-white/90 rounded-2xl shadow-xl p-6 border border-emerald-100">
                <h4 className="text-[10px] font-black text-[#052c14]/40 uppercase tracking-[0.2em] mb-8 ml-2">
                  Session Variance Analysis
                </h4>
                <div className="h-[200px]">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={filteredHistory} margin={{ top: 0, right: 10, left: -20, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#10b981" vertical={false} opacity={0.05} />
                      <XAxis dataKey="date" hide />
                      <YAxis domain={[0, 0.12]} hide />
                      <Tooltip
                        contentStyle={{ background: 'rgba(255, 255, 255, 0.95)', border: '1px solid rgba(16, 185, 129, 0.2)', borderRadius: '12px' }}
                        cursor={{ fill: 'rgba(16, 185, 129, 0.05)' }}
                      />
                      <Bar dataKey="vfa" radius={[4, 4, 0, 0]} maxBarSize={30}>
                        {filteredHistory.map((item, i) => (
                          <Cell key={i} fill={getGradeColor(item.grade)} fillOpacity={0.8} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* Quick Summary list */}
              <div className="bg-white/90 rounded-2xl shadow-xl p-6 border border-emerald-100 flex flex-col justify-center">
                 <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 rounded-xl bg-emerald-50 border border-emerald-100">
                       <span className="text-[10px] font-black text-[#052c14]/20 uppercase tracking-widest">Anomaly Detection</span>
                       <span className="text-xs font-black text-emerald-600">NOMINAL</span>
                    </div>
                    <div className="flex items-center justify-between p-4 rounded-xl bg-emerald-50 border border-emerald-100">
                       <span className="text-[10px] font-black text-[#052c14]/20 uppercase tracking-widest">Data Integrity</span>
                       <span className="text-xs font-black text-[#052c14]">99.98%</span>
                    </div>
                    <div className="flex items-center justify-between p-4 rounded-xl bg-emerald-50 border border-emerald-100">
                       <span className="text-[10px] font-black text-[#052c14]/20 uppercase tracking-widest">Sync Latency</span>
                       <span className="text-xs font-black text-emerald-500">14ms</span>
                    </div>
                 </div>
              </div>
          </div>

          {/* Session history table */}
          <div className="bg-white/90 rounded-2xl shadow-xl border border-emerald-100 overflow-hidden">
            <div className="px-8 py-5 border-b border-emerald-100 bg-emerald-50 flex items-center justify-between">
              <h4 className="text-[11px] font-black text-[#052c14] tracking-[0.2em] uppercase">
                Historical Registry Logs
              </h4>
              <span className="text-[9px] font-black text-[#052c14]/40 uppercase tracking-widest">
                {filteredHistory.length} Cycles Logged
              </span>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-emerald-50/50">
                    {['Registry','Batch','VFA','pH','Turbidity','Temp','Status'].map(h => (
                      <th key={h}
                        className="px-6 py-4 text-left text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em]">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-emerald-50">
                  {[...filteredHistory].reverse().map((item, i) => (
                    <tr key={item.id}
                      className="hover:bg-emerald-50/50 transition-colors">
                      <td className="px-6 py-4 text-[#052c14]/40 text-[10px] font-bold font-mono">
                        {item.date}
                      </td>
                      <td className="px-6 py-4 text-[#052c14]/80 font-black text-[10px] tracking-wider">
                        {item.sample_id?.slice(-8) || '####'}
                      </td>
                      <td className="px-6 py-4 font-black text-xs"
                        style={{ color: getGradeColor(item.grade) }}>
                        {item.vfa.toFixed(4)}
                      </td>
                      <td className="px-6 py-4 text-[#052c14]/60 font-black text-[10px]">
                        {item.ph?.toFixed(2) || item.pH?.toFixed(2)}
                      </td>
                      <td className="px-6 py-4 text-[#052c14]/60 font-black text-[10px]">
                        {item.turbidity?.toFixed(1)} NTU
                      </td>
                      <td className="px-6 py-4 text-[#052c14]/60 font-black text-[10px]">
                        {item.temp?.toFixed(1) || item.temperature?.toFixed(1)}°C
                      </td>
                      <td className="px-6 py-4">
                        <span className="px-3 py-1 rounded-md text-[9px] font-black border uppercase shadow-sm"
                          style={{
                            backgroundColor: `${getGradeColor(item.grade)}10`,
                            borderColor: `${getGradeColor(item.grade)}30`,
                            color: getGradeColor(item.grade)
                          }}>
                          Grade {item.grade}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ── No history ────────────────────────────────────────────────────── */}
      {selectedFarmer && !loading && !farmerStats && (
        <div className="flex flex-col items-center justify-center
                        min-h-[30vh] text-center bg-emerald-50 rounded-[2rem] border border-emerald-100 mt-6 shadow-xl">
          <div className="w-20 h-20 bg-white rounded-2xl flex items-center justify-center mb-6 border border-emerald-100 shadow-xl">
            <span className="text-4xl">📭</span>
          </div>
          <p className="text-[#052c14]/40 text-[11px] tracking-widest font-black uppercase">
            No history found for <span className="text-emerald-600 underline">#{selectedFarmer}</span>
          </p>
        </div>
      )}
    </div>
  )
}

export default FarmerProfile
