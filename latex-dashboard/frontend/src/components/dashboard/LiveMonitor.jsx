// src/components/dashboard/LiveMonitor.jsx

import { useState, useEffect }              from 'react'
import { db }                               from '../../firebase/config'
import { ref, onValue, query,
         orderByChild, limitToLast }        from 'firebase/database'
import { LineChart, Line, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer,
         ReferenceLine }                    from 'recharts'
import { getGradeColor, getGradeBg,
         getGradeBadgeColor, getGradeIcon,
         getGradeLabel, getVFAStatus,
         getVFAStatusColor }                from '../../utils/gradeHelper'
import { formatShortTime, timeAgo }         from '../../utils/dateHelper'

const LiveMonitor = () => {

  const [latest,   setLatest]   = useState(null)
  const [history,  setHistory]  = useState([])
  const [loading,  setLoading]  = useState(true)
  const [error,    setError]    = useState(null)

  // ── Firebase real-time listener ─────────────────────────────────────────────
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp'),
      limitToLast(20)
    )

    const unsub = onValue(q, (snapshot) => {
      try {
        const data = snapshot.val()
        if (!data) {
          // No data — show empty state, no mock fallback
          setLatest(null)
          setHistory([])
          setLoading(false)
          return
        }

        const items = Object.entries(data)
          .map(([key, val]) => ({
            id:          key,
            vfa:         parseFloat(val.vfa)         || 0,
            grade:       val.grade                   || 'A',
            pH:          parseFloat(val.pH)          || 0,
            turbidity:   parseFloat(val.turbidity)   || 0,
            temperature: parseFloat(val.temperature) || 0,
            farmer_id:   val.farmer_id               || '',
            device_id:   val.device_id               || '',
            sample_id:   val.sample_id               || '',
            timestamp:   val.timestamp               || '',
            time:        val.timestamp?.slice(11,16) || '',
          }))
          .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))

        setLatest(items[items.length - 1])
        setHistory(items)
        setLoading(false)
        setError(null)

      } catch (err) {
        console.error('Firebase read error:', err)
        setError('Failed to connect to data stream.')
        setLatest(null)
        setHistory([])
        setLoading(false)
      }
    }, (err) => {
      console.error('Firebase listener error:', err)
      setError('Unable to reach the IoT stream. Check your connection.')
      setLatest(null)
      setHistory([])
      setLoading(false)
    })

    return () => unsub()
  }, [])

  // ── Loading ─────────────────────────────────────────────────────────────────
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4">
        <div className="w-12 h-12 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-[#052c14]/40 text-sm tracking-wide font-black uppercase tracking-[0.2em]">
          Connecting to IoT stream...
        </p>
      </div>
    )
  }

  // ── Error ────────────────────────────────────────────────────────────────────
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-4 text-center px-4">
        <div className="text-5xl mb-2">⚠️</div>
        <h3 className="text-lg font-black text-[#052c14] uppercase tracking-widest">Connection Error</h3>
        <p className="text-[#052c14]/40 text-xs font-bold uppercase tracking-widest max-w-xs">{error}</p>
      </div>
    )
  }

  // ── Empty State ──────────────────────────────────────────────────────────────
  if (!latest || history.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-6 text-center px-4">
        <div className="w-24 h-24 bg-emerald-50 rounded-3xl flex items-center justify-center border border-emerald-100 shadow-inner">
          <span className="text-4xl">📡</span>
        </div>
        <div>
          <h3 className="text-xl font-black text-[#052c14] uppercase tracking-widest mb-3">
            Awaiting IoT Data
          </h3>
          <p className="text-[#052c14]/40 text-xs font-bold uppercase tracking-widest max-w-sm leading-relaxed">
            No sensor readings received yet. Once your IoT device starts transmitting, live data will appear here automatically.
          </p>
        </div>
        <div className="flex items-center gap-2 bg-emerald-50 px-5 py-2.5 rounded-full border border-emerald-100">
          <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span className="text-[10px] font-black text-[#052c14]/50 uppercase tracking-widest">Stream Active — Listening for signals</span>
        </div>
      </div>
    )
  }

  // ── Render (real data) ──────────────────────────────────────────────────────
  return (
    <div className="space-y-6">

      {/* ── VFA + Grade Display ───────────────────────────────────────────── */}
      <div className="bg-white/90 rounded-[2rem] p-10 text-center border border-emerald-100 relative overflow-hidden shadow-xl group">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(16,185,129,0.05),transparent_70%)] pointer-events-none"></div>
        <div className="absolute top-0 left-0 w-full h-1" style={{ backgroundColor: getGradeColor(latest.grade) }}></div>
        <div className="absolute -top-32 -right-32 w-80 h-80 rounded-full blur-[100px] opacity-10" style={{ backgroundColor: getGradeColor(latest.grade) }}></div>
        <div className="absolute -bottom-32 -left-32 w-80 h-80 rounded-full blur-[100px] opacity-10" style={{ backgroundColor: getGradeColor(latest.grade) }}></div>

        <div className="flex flex-col items-center relative z-10">
          <div className="flex items-center gap-3 mb-6">
            <div className="flex items-center gap-1.5 bg-emerald-50 px-3 py-1.5 rounded-full border border-emerald-100">
              <div className="w-2 h-2 rounded-full animate-pulse" style={{ backgroundColor: getGradeColor(latest.grade) }} />
              <span className="text-[#052c14] text-[10px] font-black uppercase tracking-[0.2em]">Live Stream Active</span>
            </div>
          </div>

          <div className="relative mb-2">
            <div className="text-[10rem] font-black leading-none tracking-tighter transition-all duration-500 group-hover:scale-[1.02]"
              style={{ color: getGradeColor(latest.grade) }}>
              {latest.vfa.toFixed(4)}
            </div>
            <div className="absolute -right-12 bottom-4 text-[#052c14]/10 text-xs font-black uppercase tracking-widest rotate-90">Units / VFA</div>
          </div>

          <div className="flex flex-col items-center gap-6 mt-4">
            <div className="inline-flex items-center px-8 py-3 rounded-2xl bg-white border border-emerald-100 shadow-lg">
              <span className="text-3xl mr-3">{getGradeIcon(latest.grade)}</span>
              <div className="text-left">
                <div className="text-[10px] font-black text-[#052c14]/30 uppercase tracking-widest mb-0.5">Classification</div>
                <div className="text-2xl font-black text-[#052c14] leading-none">Grade {latest.grade}</div>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="px-5 py-2 rounded-xl bg-emerald-50 border border-emerald-50">
                <p className="text-[9px] font-black text-[#052c14]/20 uppercase tracking-widest mb-1 text-center">Safety Rating</p>
                <p className="text-xs font-black uppercase tracking-wide text-center" style={{ color: getVFAStatusColor(latest.vfa) }}>
                  {getVFAStatus(latest.vfa)}
                </p>
              </div>
            </div>
          </div>

          <p className="text-[#052c14]/40 text-[10px] font-bold uppercase tracking-[0.3em] mt-10">
            Detected: {latest.timestamp?.split('T')[1]?.slice(0, 8)} • ID: {latest.sample_id}
          </p>
        </div>
      </div>

      {/* ── Sensor Readings ───────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* pH */}
        <div className="bg-white/90 rounded-2xl p-6 border border-emerald-100 shadow-xl relative overflow-hidden group hover:bg-emerald-50 transition-all">
          <div className="flex items-center justify-between mb-6 relative z-10">
            <div>
              <p className="text-[#052c14]/30 text-[9px] font-black uppercase tracking-widest mb-1">Stability Index</p>
              <h4 className="text-[#052c14] text-xs font-black uppercase tracking-widest">pH Spectrum</h4>
            </div>
            <div className="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center border border-blue-500/20 group-hover:scale-110 transition-transform">
              <span className="text-blue-600 text-lg">🧪</span>
            </div>
          </div>
          <p className="text-4xl font-black text-[#052c14] tracking-tighter relative z-10">{latest.pH.toFixed(2)}</p>
          <div className="mt-6 space-y-2 relative z-10">
            <div className="flex justify-between text-[9px] font-black uppercase tracking-widest text-[#052c14]/20">
              <span>Basic</span><span>Acidic</span>
            </div>
            <div className="bg-emerald-50 rounded-full h-2 border border-emerald-100 overflow-hidden">
              <div className="bg-gradient-to-r from-blue-600 to-blue-300 h-full rounded-full transition-all duration-1000"
                style={{ width: `${(latest.pH / 14) * 100}%` }} />
            </div>
            <p className="text-[10px] font-bold text-[#052c14]/40 text-center tracking-wide pt-1 italic">Optimal range: 6.8 — 7.2</p>
          </div>
        </div>

        {/* Turbidity */}
        <div className="bg-white/90 rounded-2xl p-6 border border-emerald-100 shadow-xl relative overflow-hidden group hover:bg-emerald-50 transition-all">
          <div className="flex items-center justify-between mb-6 relative z-10">
            <div>
              <p className="text-[#052c14]/30 text-[9px] font-black uppercase tracking-widest mb-1">Clarity Metric</p>
              <h4 className="text-[#052c14] text-xs font-black uppercase tracking-widest">Turbidity</h4>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center border border-emerald-500/20 group-hover:scale-110 transition-transform">
              <span className="text-emerald-600 text-lg">💧</span>
            </div>
          </div>
          <p className="text-4xl font-black text-[#052c14] tracking-tighter relative z-10">
            {latest.turbidity.toFixed(1)} <span className="text-base text-[#052c14]/30 font-bold ml-1">NTU</span>
          </p>
          <div className="mt-6 space-y-2 relative z-10">
            <div className="flex justify-between text-[9px] font-black uppercase tracking-widest text-[#052c14]/20">
              <span>Pure</span><span>Dense</span>
            </div>
            <div className="bg-emerald-50 rounded-full h-2 border border-emerald-100 overflow-hidden">
              <div className="bg-gradient-to-r from-emerald-600 to-emerald-400 h-full rounded-full transition-all duration-1000"
                style={{ width: `${Math.min((latest.turbidity / 150) * 100, 100)}%` }} />
            </div>
          </div>
        </div>

        {/* Temperature */}
        <div className="bg-white/90 rounded-2xl p-6 border border-emerald-100 shadow-xl relative overflow-hidden group hover:bg-emerald-50 transition-all">
          <div className="flex items-center justify-between mb-6 relative z-10">
            <div>
              <p className="text-[#052c14]/30 text-[9px] font-black uppercase tracking-widest mb-1">Thermal State</p>
              <h4 className="text-[#052c14] text-xs font-black uppercase tracking-widest">Ambient Temp</h4>
            </div>
            <div className="w-10 h-10 rounded-xl bg-orange-500/10 flex items-center justify-center border border-orange-500/20 group-hover:scale-110 transition-transform">
              <span className="text-orange-600 text-lg">🌡️</span>
            </div>
          </div>
          <p className="text-4xl font-black text-[#052c14] tracking-tighter relative z-10">
            {latest.temperature.toFixed(1)}<span className="text-base text-[#052c14]/30 font-bold ml-1">°C</span>
          </p>
          <div className="mt-6 space-y-2 relative z-10">
            <div className="flex justify-between text-[9px] font-black uppercase tracking-widest text-[#052c14]/20">
              <span>Cool</span><span>Hot</span>
            </div>
            <div className="bg-emerald-50 rounded-full h-2 border border-emerald-100 overflow-hidden">
              <div className="bg-gradient-to-r from-orange-600 to-red-400 h-full rounded-full transition-all duration-1000"
                style={{ width: `${Math.max(0, Math.min(((latest.temperature - 15) / 25) * 100, 100))}%` }} />
            </div>
            <p className="text-[10px] font-bold text-[#052c14]/40 text-center tracking-wide pt-1 italic">Sensor variation: ±0.1°C</p>
          </div>
        </div>
      </div>

      {/* ── Sample Info ───────────────────────────────────────────────────── */}
      <div className="bg-emerald-50 rounded-2xl p-6 border border-emerald-100 shadow-inner grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Network Node', value: latest.farmer_id  || '—' },
          { label: 'D-Link ID',    value: latest.device_id  || '—' },
          { label: 'Batch UID',    value: latest.sample_id  || '—' },
          { label: 'Capture Time', value: formatShortTime(latest.timestamp) },
        ].map((item, i) => (
          <div key={i} className="flex flex-col items-center justify-center border-r last:border-0 border-emerald-100">
            <p className="text-[#052c14]/20 text-[9px] font-black uppercase tracking-[0.2em] mb-2">{item.label}</p>
            <p className="text-[#052c14] text-[11px] font-mono font-black tracking-widest bg-white px-3 py-1.5 rounded-lg border border-emerald-100 shadow-sm">
              {item.value}
            </p>
          </div>
        ))}
      </div>

      {/* ── VFA Trend Chart ───────────────────────────────────────────────── */}
      <div className="bg-white/90 rounded-2xl shadow-xl p-8 border border-emerald-100 relative">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between mb-10 gap-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <div className="w-1.5 h-4 bg-emerald-500 rounded-full"></div>
              <h3 className="text-sm font-black text-[#052c14] tracking-[0.2em] uppercase">VFA Dynamic Trend</h3>
            </div>
            <p className="text-[#052c14]/30 text-[10px] font-bold tracking-widest uppercase ml-3">
              Real-time variance analysis ({history.length} samples)
            </p>
          </div>
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-[#4CBB17]" />
              <span className="text-[9px] font-black text-[#052c14]/40 uppercase tracking-widest">Safe Level</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 rounded-full bg-red-500" />
              <span className="text-[9px] font-black text-[#052c14]/40 uppercase tracking-widest">Critical</span>
            </div>
          </div>
        </div>

        <div className="h-[320px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={history} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.03)" vertical={false} />
              <XAxis dataKey="time" tick={{ fontSize: 9, fill: 'rgba(5,44,20,0.4)', fontWeight: 800 }} axisLine={false} tickLine={false} dy={15} />
              <YAxis domain={[0, 0.12]} tick={{ fontSize: 9, fill: 'rgba(5,44,20,0.4)', fontWeight: 800 }} axisLine={false} tickLine={false} tickFormatter={v => v.toFixed(3)} />
              <Tooltip content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  return (
                    <div className="bg-white/95 backdrop-blur-xl p-4 border border-emerald-100 rounded-xl shadow-xl">
                      <p className="text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em] mb-2">{payload[0].payload.timestamp?.split('T')[1]?.slice(0, 8)}</p>
                      <div className="flex items-center gap-3">
                        <div className="text-2xl font-black" style={{ color: getGradeColor(payload[0].payload.grade) }}>{payload[0].value.toFixed(4)}</div>
                        <div className="px-2 py-0.5 rounded-md bg-emerald-50 border border-emerald-100 text-[10px] font-black text-emerald-600 uppercase">Grade {payload[0].payload.grade}</div>
                      </div>
                    </div>
                  )
                }
                return null
              }} />
              <ReferenceLine y={0.05} stroke="#4CBB17" strokeDasharray="4 4" strokeWidth={1} />
              <ReferenceLine y={0.08} stroke="#ef4444" strokeDasharray="4 4" strokeWidth={1} />
              <Line type="monotone" dataKey="vfa" stroke="#10b981" strokeWidth={4} dot={{ fill: '#10b981', r: 0 }} activeDot={{ r: 6, fill: '#fff', stroke: '#10b981', strokeWidth: 3 }} animationDuration={1500} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* ── Recent Readings Table ─────────────────────────────────────────── */}
      <div className="bg-white/90 rounded-2xl shadow-xl border border-emerald-100 overflow-hidden">
        <div className="px-8 py-5 border-b border-emerald-50 bg-emerald-50/50 flex items-center justify-between">
          <h3 className="text-[11px] font-black text-[#052c14]/80 tracking-[0.2em] uppercase">System Telemetry Logs</h3>
          <span className="text-[9px] font-black text-[#052c14]/20 uppercase tracking-widest italic">Auto-refreshing every 60s</span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-emerald-50">
                {['Registry Time','Node','VFA Metric','pH','Turbidity','Thermal','Grade'].map(h => (
                  <th key={h} className="px-6 py-4 text-left text-[9px] font-black text-[#052c14]/30 uppercase tracking-[0.2em]">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-emerald-50">
              {[...history].reverse().slice(0, 10).map((item) => (
                <tr key={item.id} className="hover:bg-emerald-50/30 transition-colors">
                  <td className="px-6 py-4 text-[#052c14]/40 text-[10px] font-bold font-mono">{item.time}</td>
                  <td className="px-6 py-4 text-[#052c14]/80 font-black text-[10px] tracking-wider uppercase">{item.farmer_id}</td>
                  <td className="px-6 py-4 font-black text-xs" style={{ color: getGradeColor(item.grade) }}>{item.vfa.toFixed(4)}</td>
                  <td className="px-6 py-4 text-[#052c14]/60 text-[10px] font-bold">{item.pH.toFixed(2)}</td>
                  <td className="px-6 py-4 text-[#052c14]/60 text-[10px] font-bold">{item.turbidity.toFixed(1)} <span className="text-[8px] opacity-40">NTU</span></td>
                  <td className="px-6 py-4 text-[#052c14]/60 text-[10px] font-bold">{item.temperature.toFixed(1)}°C</td>
                  <td className="px-6 py-4">
                    <span className="text-[8px] font-black px-2 py-1 rounded-md border uppercase tracking-widest shadow-sm"
                      style={{ backgroundColor: `${getGradeColor(item.grade)}20`, borderColor: `${getGradeColor(item.grade)}40`, color: getGradeColor(item.grade) }}>
                      {item.grade}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  )
}

export default LiveMonitor