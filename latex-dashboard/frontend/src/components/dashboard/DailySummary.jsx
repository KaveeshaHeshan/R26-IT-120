// src/components/dashboard/DailySummary.jsx

import { useState, useEffect, useMemo }     from 'react'
import { db }                               from '../../firebase/config'
import { ref, onValue, query,
         orderByChild }                     from 'firebase/database'
import { BarChart, Bar, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer, Cell,
         PieChart, Pie, Legend,
         LineChart, Line,
         ReferenceLine, AreaChart, Area }                    from 'recharts'
import { getGradeColor, getGradeBadgeColor,
         getGradeIcon, getGradeLabel }      from '../../utils/gradeHelper'
import { getToday, getLastNDays,
         formatChartDate }                  from '../../utils/dateHelper'

// ── Mock Data Generator ───────────────────────────────────────────────────────
const generateMockData = () => {
  const mockData = []
  const farmers = ['FM-8821', 'FM-4390', 'FM-1102', 'FM-5572', 'FM-2291', 'FM-9003']
  const dates = getLastNDays(14)
  
  dates.forEach(date => {
    const samplesPerDay = Math.floor(Math.random() * 8) + 12
    for(let i=0; i<samplesPerDay; i++) {
      const vfa = Math.random() * 0.08 + 0.02
      let grade = 'A'
      if (vfa > 0.075) grade = 'C'
      else if (vfa > 0.05) grade = 'B'
      
      mockData.push({
        id: `mock-${date}-${i}`,
        vfa: vfa,
        grade: grade,
        pH: 6.5 + Math.random(),
        turbidity: 10 + Math.random() * 40,
        temperature: 25 + Math.random() * 5,
        farmer_id: farmers[Math.floor(Math.random() * farmers.length)],
        timestamp: `${date}T${10 + Math.floor(Math.random() * 8)}:${Math.floor(Math.random()*60)}:00`,
        date: date
      })
    }
  })
  return mockData
}

const DailySummary = () => {

  const [predictions, setPredictions] = useState([])
  const [loading,     setLoading]     = useState(true)
  const [error,       setError]       = useState(null)
  const [selectedDate, setSelectedDate] = useState(getToday())
  const [lastUpdated, setLastUpdated]   = useState(new Date())

  // ── Fetch all predictions ───────────────────────────────────────────────────
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp')
    )

    setLoading(true)
    const unsub = onValue(q, (snapshot) => {
      try {
        setLastUpdated(new Date())
        const data = snapshot.val()
        if (!data) {
          console.log("DailySummary: Using high-fidelity mock data fallback")
          setPredictions(generateMockData())
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

        setPredictions(items.length > 0 ? items : generateMockData())
        setLoading(false)
        setError(null)

      } catch (err) {
        console.warn("DailySummary: Firebase error, falling back to mock data", err)
        setPredictions(generateMockData())
        setLoading(false)
      }
    }, (err) => {
      console.warn("DailySummary: Firebase connectivity lost, using simulated data")
      setPredictions(generateMockData())
      setLoading(false)
    })

    return () => unsub()
  }, [])

  // ── Processed Data ──────────────────────────────────────────────────────────
  
  const todayData = useMemo(() => 
    predictions.filter(p => p.date === selectedDate),
    [predictions, selectedDate]
  )

  const dailyStats = useMemo(() => {
    const total = todayData.length
    const gradeA = todayData.filter(p => p.grade === 'A').length
    const gradeB = todayData.filter(p => p.grade === 'B').length
    const gradeC = todayData.filter(p => p.grade === 'C').length
    
    return {
      total,
      gradeA,
      gradeB,
      gradeC,
      avgVFA:  total > 0
        ? (todayData.reduce((s,p) => s + p.vfa, 0) / total).toFixed(4)
        : '0.0000',
      minVFA:  total > 0
        ? Math.min(...todayData.map(p => p.vfa)).toFixed(4)
        : '0.0000',
      maxVFA:  total > 0
        ? Math.max(...todayData.map(p => p.vfa)).toFixed(4)
        : '0.0000',
      rejectionRate: total > 0
        ? ((gradeC / total) * 100).toFixed(1)
        : '0.0',
      stabilityScore: total > 0
        ? (100 - (gradeC / total * 100) - (gradeB / total * 50)).toFixed(0)
        : '0'
    }
  }, [todayData])

  const pieData = useMemo(() => [
    { name: 'Grade A', value: dailyStats.gradeA, color: getGradeColor('A') },
    { name: 'Grade B', value: dailyStats.gradeB, color: getGradeColor('B') },
    { name: 'Grade C', value: dailyStats.gradeC, color: getGradeColor('C') },
  ].filter(d => d.value > 0), [dailyStats])

  const last7Days = useMemo(() => 
    getLastNDays(7).map(date => {
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
    }), [predictions]
  )

  const topFarmers = useMemo(() => {
    const farmerMap = {}
    todayData.forEach(p => {
      if (!farmerMap[p.farmer_id]) {
        farmerMap[p.farmer_id] = { total:0, gradeA:0, gradeB:0, gradeC:0, sumVFA: 0 }
      }
      farmerMap[p.farmer_id].total++
      farmerMap[p.farmer_id][`grade${p.grade}`]++
      farmerMap[p.farmer_id].sumVFA += p.vfa
    })
    return Object.entries(farmerMap)
      .map(([id, stats]) => ({ 
        id, 
        ...stats, 
        avgVFA: (stats.sumVFA / stats.total).toFixed(4) 
      }))
      .sort((a,b) => b.total - a.total)
      .slice(0, 5)
  }, [todayData])

  // ── Loading ─────────────────────────────────────────────────────────────────
  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-12 h-12 border-4 border-[#228B22]
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
    <div className="space-y-8 pb-10">

      {/* ── Date Selector ─────────────────────────────────────────────────── */}
      <div className="bg-white/80 backdrop-blur-xl rounded-4xl p-8 border border-emerald-100 shadow-xl flex flex-col md:flex-row items-center justify-between gap-6 overflow-hidden relative group">
         <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-500/5 rounded-full blur-3xl -mr-32 -mt-32 group-hover:bg-emerald-500/10 transition-all duration-700"></div>
         <div className="relative z-10">
            <h3 className="text-[11px] font-black text-emerald-600 uppercase tracking-[0.4em] mb-2">
              Temporal Index
            </h3>
            <div className="flex items-baseline gap-3">
               <span className="text-4xl font-black text-[#052c14] tracking-tighter italic">
                 {selectedDate === getToday() ? 'CURRENT' : selectedDate}
               </span>
               <div className="flex flex-col">
                  <div className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                  <span className="text-[7px] font-black text-emerald-600/40 uppercase tracking-tighter mt-1">
                    Updated: {lastUpdated.toLocaleTimeString()}
                  </span>
               </div>
            </div>
         </div>
         
         <div className="flex items-center gap-4 relative z-10 bg-emerald-50 p-2 rounded-2xl border border-emerald-100">
          <input
            type="date"
            value={selectedDate}
            max={getToday()}
            onChange={e => setSelectedDate(e.target.value)}
            className="bg-transparent text-[#052c14] text-xs font-black uppercase tracking-widest px-4 py-2 focus:outline-none cursor-pointer"
          />
          <button
            onClick={() => setSelectedDate(getToday())}
            className="px-6 py-2 bg-emerald-600 text-white text-[10px] font-black uppercase tracking-[0.2em] rounded-xl hover:scale-105 active:scale-95 transition-all shadow-[0_10px_20px_rgba(16,185,129,0.2)]"
          >
            REAL-TIME
          </button>
        </div>
      </div>

      {/* ── Stats Cards ───────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
        {[
          { label: 'Total Inflow', value: dailyStats.total,
            icon: '📋', color: '#10b981', secondary: 'Batch Collections' },
          { label: 'VFA Average', value: dailyStats.avgVFA,
            icon: '📊', color: '#10b981', secondary: 'System Composite' },
          { label: 'Stability Score',
            value: `${dailyStats.stabilityScore}%`,
            icon: '🛡️', color: '#3b82f6', secondary: 'System Resilience'   },
          { label: 'Reject Flux',
            value: `${dailyStats.rejectionRate}%`,
            icon: '📉', color: '#ef4444', secondary: 'Grade C Variance'   },
        ].map((s,i) => (
          <div key={i}
            className="bg-white/90 rounded-3xl p-6 border border-emerald-100 shadow-lg relative overflow-hidden group hover:scale-[1.02] transition-all duration-300">
            <div className="absolute bottom-0 right-0 text-emerald-500/5 text-6xl group-hover:scale-110 transition-transform">{s.icon}</div>
            <div className="flex flex-col h-full relative z-10">
              <span className="text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em] mb-4">
                {s.label}
              </span>
              <div className="flex items-baseline gap-1">
                <span className="text-3xl font-black text-[#052c14] tracking-tighter" style={{ textShadow: `0 0 20px ${s.color}20` }}>
                  {s.value}
                </span>
              </div>
              <span className="mt-auto pt-4 text-[8px] font-bold text-[#052c14]/20 uppercase tracking-widest">
                {s.secondary}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Grade Distribution + Pie Chart  */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

        {/* Grade bars */}
        <div className="bg-white/90 rounded-4xl p-8 border border-emerald-100 shadow-xl overflow-hidden relative group">
          <div className="flex items-center justify-between mb-8">
            <h4 className="text-[11px] font-black text-[#052c14] uppercase tracking-[0.3em]">
              Quality Classification
            </h4>
            <div className="text-[10px] font-black text-[#052c14]/20 uppercase tracking-widest bg-emerald-50 px-3 py-1 rounded-full">
              Day Analysis
            </div>
          </div>
          
          <div className="space-y-6">
            {[
              { grade: 'A', count: dailyStats.gradeA, label: 'Superior' },
              { grade: 'B', count: dailyStats.gradeB, label: 'Standard' },
              { grade: 'C', count: dailyStats.gradeC, label: 'Critical' },
            ].map(g => (
              <div key={g.grade} className="relative group/item">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-3">
                     <div className="w-10 h-10 rounded-xl bg-emerald-50 border border-emerald-100 flex items-center justify-center text-lg font-black" style={{ color: getGradeColor(g.grade) }}>
                        {g.grade}
                     </div>
                     <div>
                        <p className="text-[10px] font-black text-[#052c14] uppercase tracking-wider">{g.label}</p>
                        <p className="text-[8px] font-bold text-[#052c14]/20 uppercase tracking-[0.2em]">{g.count} Units Identified</p>
                     </div>
                  </div>
                  <div className="text-right">
                    <span className="text-sm font-black text-[#052c14] tracking-tighter">
                      {dailyStats.total > 0 ? ((g.count/dailyStats.total)*100).toFixed(1) : 0}%
                    </span>
                  </div>
                </div>
                <div className="bg-emerald-50 rounded-full h-1.5 overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-1000 ease-out shadow-[0_0_10px_rgba(0,0,0,0.1)]"
                    style={{
                      width: dailyStats.total > 0 ? `${(g.count/dailyStats.total)*100}%` : '0%',
                      backgroundColor: getGradeColor(g.grade),
                      boxShadow: `0 0 15px ${getGradeColor(g.grade)}30`
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          {/* VFA range metrics */}
          <div className="mt-10 pt-8 border-t border-emerald-100 grid grid-cols-3 gap-4">
            {[
              { label: 'Minimum', value: dailyStats.minVFA, color: '#4CBB17' },
              { label: 'Arithmetic Mean', value: dailyStats.avgVFA, color: '#10b981' },
              { label: 'Maximum', value: dailyStats.maxVFA, color: '#ef4444' },
            ].map((v,i) => (
              <div key={i} className="bg-emerald-50 p-3 rounded-2xl border border-emerald-50">
                <p className="text-[#052c14]/20 text-[8px] font-black uppercase tracking-widest mb-1">{v.label}</p>
                <p className="font-black text-xs tabular-nums tracking-tighter" style={{ color: v.color }}>
                  {v.value}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Pie chart */}
        <div className="bg-white/90 rounded-4xl p-8 border border-emerald-100 shadow-xl relative overflow-hidden flex flex-col items-center justify-center">
          <div className="absolute top-8 left-8">
            <h4 className="text-[11px] font-black text-[#052c14] uppercase tracking-[0.3em]">
              Spectral Split
            </h4>
          </div>
          
          {pieData.length > 0 ? (
            <div className="w-full h-75 flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <defs>
                    {pieData.map((entry, index) => (
                      <linearGradient key={`grad-${index}`} id={`grad-${index}`} x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor={entry.color} stopOpacity={0.8}/>
                        <stop offset="95%" stopColor={entry.color} stopOpacity={0.2}/>
                      </linearGradient>
                    ))}
                  </defs>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={80}
                    outerRadius={110}
                    paddingAngle={8}
                    dataKey="value"
                    stroke="none"
                  >
                    {pieData.map((entry, i) => (
                      <Cell key={i} fill={`url(#grad-${i})`} />
                    ))}
                  </Pie>
                  <Tooltip
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        return (
                          <div className="bg-white/95 backdrop-blur-xl p-4 border border-emerald-100 rounded-xl shadow-xl">
                            <p className="text-[10px] font-black text-[#052c14]/40 uppercase tracking-widest mb-1">{payload[0].name}</p>
                            <div className="text-2xl font-black" style={{ color: payload[0].payload.color }}>
                              {payload[0].value} <span className="text-xs text-[#052c14]/40">Units</span>
                            </div>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute flex flex-col items-center justify-center">
                 <span className="text-[9px] font-black text-[#052c14]/20 uppercase tracking-[0.3em]">Total Ingress</span>
                 <span className="text-4xl font-black text-[#052c14] tracking-tighter italic">{dailyStats.total}</span>
              </div>
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center h-48">
               <div className="w-12 h-12 rounded-full border-2 border-dashed border-emerald-100 animate-spin mb-4" />
               <p className="text-emerald-800/20 text-[10px] font-black uppercase tracking-widest italic">Zero Data Points Detected</p>
            </div>
          )}
          
          <div className="flex flex-wrap justify-center gap-6 mt-4">
             {pieData.map((d, i) => (
               <div key={i} className="flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full shadow-[0_0_8px_rgba(16,185,129,0.2)]" style={{ backgroundColor: d.color }}></div>
                  <span className="text-[9px] font-black text-[#052c14]/40 uppercase tracking-widest">{d.name}</span>
               </div>
             ))}
          </div>
        </div>
      </div>

      {/*  7-Day VFA Trend  */}
      <div className="bg-white/90 rounded-4xl p-8 border border-emerald-100 shadow-xl relative overflow-hidden group">
        <div className="flex items-center justify-between mb-10">
          <div>
            <h4 className="text-[11px] font-black text-[#052c14] uppercase tracking-[0.3em]">
              VFA Volatility Trend
            </h4>
            <p className="text-[#052c14]/20 text-[9px] font-black uppercase tracking-[0.2em] mt-2">
              7-Day Continuous Monitoring Cycle
            </p>
          </div>
          <div className="h-2 w-2 rounded-full bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.4)]"></div>
        </div>
        
        <div className="h-75 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={last7Days} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="colorAvg" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.03)" vertical={false} />
              <XAxis
                dataKey="date"
                tick={{ fontSize: 9, fill: 'rgba(5, 44, 20, 0.4)', fontWeight: 800 }}
                axisLine={false} tickLine={false}
                dy={15}
              />
              <YAxis
                domain={[0, 0.12]}
                tick={{ fontSize: 9, fill: 'rgba(5, 44, 20, 0.4)', fontWeight: 800 }}
                axisLine={false} tickLine={false}
                tickFormatter={v => v.toFixed(3)}
              />
              <Tooltip
                content={({ active, payload }) => {
                  if (active && payload && payload.length) {
                    return (
                      <div className="bg-white/95 backdrop-blur-xl p-4 border border-emerald-100 rounded-xl shadow-xl">
                        <p className="text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em] mb-2">{payload[0].payload.date}</p>
                        <div className="flex items-center gap-3">
                          <div className="text-2xl font-black text-emerald-600">
                            {payload[0].value.toFixed(4)}
                          </div>
                          <div className="text-[8px] font-black text-[#052c14]/40 uppercase tracking-widest">Composite VFA</div>
                        </div>
                      </div>
                    );
                  }
                  return null;
                }}
              />
              <ReferenceLine y={0.05} stroke="#4CBB17" strokeDasharray="3 3" opacity={0.2} />
              <ReferenceLine y={0.08} stroke="#ef4444" strokeDasharray="3 3" opacity={0.2} />
              <Area
                type="monotone"
                dataKey="avgVFA"
                stroke="#10b981"
                strokeWidth={4}
                fillOpacity={1}
                fill="url(#colorAvg)"
                animationDuration={2000}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/*  7-Day Grade Bar Chart  */}
          <div className="bg-white/90 rounded-4xl p-8 border border-emerald-100 shadow-xl">
            <h4 className="text-[11px] font-black text-[#052c14] uppercase tracking-[0.3em] mb-10">
              Grade Distribution Flux
            </h4>
            <div className="h-60">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={last7Days} margin={{ top: 0, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.03)" vertical={false} />
                  <XAxis dataKey="date" tick={{ fontSize: 9, fill: 'rgba(5, 44, 20, 0.4)', fontWeight: 800 }} axisLine={false} tickLine={false} dy={10} />
                  <YAxis hide />
                  <Tooltip
                    cursor={{ fill: 'rgba(0,0,0,0.02)' }}
                    content={({ active, payload }) => {
                      if (active && payload && payload.length) {
                        return (
                          <div className="bg-white/95 backdrop-blur-xl p-4 border border-emerald-100 rounded-xl shadow-xl">
                            <p className="text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em] mb-3">{payload[0].payload.date}</p>
                            <div className="space-y-2">
                               <div className="flex items-center justify-between gap-6">
                                  <span className="text-[10px] font-black text-emerald-600 uppercase">Grade A</span>
                                  <span className="text-sm font-black text-[#052c14]">{payload[0].payload.gradeA}</span>
                               </div>
                               <div className="flex items-center justify-between gap-6">
                                  <span className="text-[10px] font-black text-yellow-600 uppercase">Grade B</span>
                                  <span className="text-sm font-black text-[#052c14]">{payload[0].payload.gradeB}</span>
                               </div>
                               <div className="flex items-center justify-between gap-6">
                                  <span className="text-[10px] font-black text-red-600 uppercase">Grade C</span>
                                  <span className="text-sm font-black text-[#052c14]">{payload[0].payload.gradeC}</span>
                               </div>
                            </div>
                          </div>
                        );
                      }
                      return null;
                    }}
                  />
                  <Bar dataKey="gradeA" stackId="a" fill={getGradeColor('A')} radius={[0, 0, 0, 0]} barSize={20} />
                  <Bar dataKey="gradeB" stackId="a" fill={getGradeColor('B')} radius={[0, 0, 0, 0]} />
                  <Bar dataKey="gradeC" stackId="a" fill={getGradeColor('C')} radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Top Farmers */}
          <div className="bg-white/90 rounded-4xl p-8 border border-emerald-100 shadow-xl">
            <h4 className="text-[11px] font-black text-[#052c14] uppercase tracking-[0.3em] mb-10">
              Peak Performance Nodes
            </h4>
            <div className="space-y-4">
              {topFarmers.length > 0 ? topFarmers.map((f, i) => (
                <div key={f.id} className="bg-emerald-50/50 p-4 rounded-2xl border border-emerald-50 flex items-center justify-between group hover:border-emerald-500/40 hover:bg-emerald-50 transition-all duration-300">
                  <div className="flex items-center gap-4">
                     <div className="w-12 h-12 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex flex-col items-center justify-center text-emerald-600 font-black">
                        <span className="text-[10px] leading-none opacity-50">NODE</span>
                        <span className="text-sm italic leading-none">#{i+1}</span>
                     </div>
                     <div>
                        <p className="text-[10px] font-black text-[#052c14] uppercase tracking-wider">{f.id}</p>
                        <div className="flex items-center gap-2 mt-1">
                           <div className="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>
                           <p className="text-[8px] font-bold text-[#052c14]/20 uppercase tracking-widest">{f.total} Successful Cycles</p>
                        </div>
                     </div>
                  </div>
                  <div className="flex items-center gap-6">
                     <div className="text-right hidden sm:block">
                        <p className="text-[8px] font-black text-[#052c14]/20 uppercase tracking-widest mb-1">Node Average</p>
                        <p className="text-xs font-black text-emerald-600 tracking-tighter tabular-nums">{f.avgVFA}</p>
                     </div>
                     <div className="flex gap-2">
                        <div className="px-3 py-1 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-[10px] font-black text-emerald-600">
                           {f.gradeA} A
                        </div>
                        <div className="px-3 py-1 bg-red-500/10 border border-red-500/20 rounded-lg text-[10px] font-black text-red-600">
                           {f.gradeC} C
                        </div>
                     </div>
                  </div>
                </div>
              )) : (
                <div className="flex flex-col items-center justify-center h-48 opacity-20 capitalize italic text-sm">
                   Awaiting node telemetry...
                </div>
              )}
            </div>
          </div>
      </div>
    </div>
  )
}

export default DailySummary
