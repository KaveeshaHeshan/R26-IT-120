// src/components/dashboard/Alerts.jsx

import { useState }                         from 'react'
import useAlerts                            from '../../hooks/useAlerts'
import { getGradeColor }                    from '../../utils/gradeHelper'
import { timeAgo }                          from '../../utils/dateHelper'

const Alerts = () => {

  const [filterSeverity, setFilterSeverity] = useState('')
  const [filterFarmer,   setFilterFarmer]   = useState('')
  const [filterDate,     setFilterDate]     = useState('')

  const {
    alerts,
    unreadCount,
    loading,
    error,
    latestAlert,
    alertStats,
    markAsRead,
    markAllAsRead,
    filterBySeverity,
    filterByDate,
  } = useAlerts(100)

  // Apply filters 
  let filtered = alerts
  if (filterSeverity) filtered = filterBySeverity(filterSeverity)
  if (filterFarmer)   filtered = filtered.filter(a =>
    a.farmer_id.toLowerCase().includes(filterFarmer.toLowerCase()))
  if (filterDate)     filtered = filtered.filter(a => a.date === filterDate)

  // Render 
  return (
    <div className="space-y-6">

      {/* ── Stats Row ─────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-6">
        {[
          { label: 'Total Alerts',  value: alertStats.total,
            icon: '🔔', color: 'text-[#052c14]', border: 'border-emerald-100' },
          { label: 'Unread',        value: alertStats.unread,
            icon: '📬', color: 'text-emerald-600', border: 'border-emerald-200' },
          { label: 'Critical',      value: alertStats.critical,
            icon: '🔴', color: 'text-red-600', border: 'border-red-100' },
          { label: 'High Range',    value: alertStats.high,
            icon: '🟠', color: 'text-orange-600', border: 'border-orange-100' },
          { label: 'Today',         value: alertStats.today,
            icon: '📅', color: 'text-emerald-500', border: 'border-emerald-300' },
        ].map((s, i) => (
          <div key={i}
            className={`bg-white/90 rounded-[1.5rem] p-6 border shadow-xl relative overflow-hidden group hover:bg-emerald-50 transition-all`}>
            <div className="absolute top-0 right-0 w-16 h-16 bg-emerald-500/5 blur-2xl rounded-full group-hover:bg-emerald-500/10 transition-colors"></div>
            <div className="flex items-center justify-between mb-4 relative z-10">
              <span className="text-[#052c14]/70 text-[9px] font-black uppercase tracking-[0.2em]">
                {s.label}
              </span>
              <span className="text-xl filter grayscale group-hover:grayscale-0 transition-all">{s.icon}</span>
            </div>
            <p className={`text-3xl font-black ${s.color} tracking-tighter relative z-10`}>
              {s.value}
            </p>
          </div>
        ))}
      </div>

      {/* ── Latest Alert Banner ────────────────────────────────────────── */}
      {latestAlert && (
        <div className="bg-red-50/80 backdrop-blur-md rounded-[2rem] p-6 border border-red-100
                        flex flex-col md:flex-row items-center justify-between gap-6 shadow-xl relative overflow-hidden animate-pulse-slow">
          <div className="absolute -left-10 -top-10 w-48 h-48 bg-red-500/5 blur-3xl rounded-full"></div>
          <div className="flex items-center gap-6 relative z-10">
            <div className="w-16 h-16 bg-white rounded-2xl flex items-center justify-center border border-red-100 shadow-xl group-hover:rotate-12 transition-transform">
              <span className="text-3xl">⚠️</span>
            </div>
            <div>
              <h4 className="text-[#052c14] font-black text-xs uppercase tracking-[0.2em] mb-1">
                Immediate Action Required
              </h4>
              <p className="text-[#052c14]/75 text-[10px] font-bold uppercase tracking-widest leading-relaxed">
                ID: <span className="text-red-600 font-black">{latestAlert.farmer_id}</span> • 
                VFA Peak: <span className="text-red-600 font-black">{latestAlert.vfa?.toFixed(4)}</span> • 
                <span className="ml-2 bg-white px-2 py-0.5 rounded border border-red-50">{timeAgo(latestAlert.timestamp)}</span>
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4 relative z-10 w-full md:w-auto">
            <span className="flex-1 md:flex-none text-center bg-red-600 text-white text-[9px]
                             font-black px-6 py-3 rounded-xl shadow-lg uppercase tracking-[0.25em]">
              {latestAlert.severity?.toUpperCase()} ALERT
            </span>
            <button
               onClick={() => markAsRead(latestAlert.id)}
               className="px-6 py-3 bg-white hover:bg-red-50 border border-red-100 text-red-600 text-[9px] font-black rounded-xl transition-all uppercase tracking-[0.2em] shadow-md active:scale-95"
            >
               Acknowledge
            </button>
          </div>
        </div>
      )}

      {/* ── Filters + Actions ─────────────────────────────────────────── */}
      <div className="bg-white/90 rounded-[2rem] shadow-xl p-8 border border-emerald-100 relative overflow-hidden group">
         <div className="absolute top-0 left-0 w-full h-[2px] bg-gradient-to-r from-transparent via-emerald-500 to-transparent opacity-30"></div>
        <div className="flex flex-col md:flex-row gap-6 items-end justify-between">

          {/* Filters */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full md:w-auto flex-1">
            <div className="space-y-2">
               <label className="text-[9px] font-black text-[#052c14]/60 uppercase tracking-[0.2em] ml-2">Priority Tier</label>
               <select
                  value={filterSeverity}
                  onChange={e => setFilterSeverity(e.target.value)}
                  className="w-full px-5 py-4 bg-emerald-50 border border-emerald-100 rounded-2xl
                             text-[#052c14] text-[10px] font-black tracking-widest focus:outline-none focus:border-emerald-500/50 focus:ring-4 focus:ring-emerald-500/5 transition-all cursor-pointer appearance-none shadow-inner"
               >
                  <option value="" className="bg-white font-black">ALL PRIORITY LEVELS</option>
                  <option value="critical" className="bg-white font-black">🔴 CRITICAL ONLY</option>
                  <option value="high" className="bg-white font-black">🟠 HIGH SEVERITY</option>
                  <option value="medium" className="bg-white font-black">🟡 MEDIUM ALERTS</option>
               </select>
            </div>

            <div className="space-y-2">
               <label className="text-[9px] font-black text-[#052c14]/60 uppercase tracking-[0.2em] ml-2">Registry Search</label>
               <input
                type="text"
                placeholder="UID/LABEL..."
                value={filterFarmer}
                onChange={e => setFilterFarmer(e.target.value)}
                className="w-full px-5 py-4 bg-emerald-50 border border-emerald-100 rounded-2xl
                           text-[#052c14] text-[10px] font-black tracking-widest focus:outline-none focus:border-emerald-500/50 focus:ring-4 focus:ring-emerald-500/5 transition-all shadow-inner"
              />
            </div>

            <div className="space-y-2">
               <label className="text-[9px] font-black text-[#052c14]/60 uppercase tracking-[0.2em] ml-2">Log Date</label>
               <input
                  type="date"
                  value={filterDate}
                  onChange={e => setFilterDate(e.target.value)}
                  className="w-full px-5 py-4 bg-emerald-50 border border-emerald-100 rounded-2xl
                             text-[#052c14] text-[10px] font-black tracking-widest focus:outline-none focus:border-emerald-500/50 focus:ring-4 focus:ring-emerald-500/5 transition-all cursor-pointer shadow-inner"
               />
            </div>
          </div>

          {/* Mark all read */}
          <div className="flex items-center gap-4 w-full md:w-auto">
             {(filterSeverity || filterFarmer || filterDate) && (
                <button
                  onClick={() => {
                    setFilterSeverity('')
                    setFilterFarmer('')
                    setFilterDate('')
                  }}
                  className="px-6 py-4 text-[#052c14]/70 hover:text-red-500 text-[10px] font-black uppercase tracking-widest transition-colors"
                >
                  Reset Terminal
                </button>
              )}
              {unreadCount > 0 && (
                <button
                  onClick={markAllAsRead}
                  className="flex-1 md:w-48 px-6 py-4 bg-emerald-600 text-white rounded-2xl 
                             text-[10px] font-black uppercase tracking-[0.2em] shadow-lg
                             hover:bg-emerald-700 transition-all active:scale-95 border-b-4 border-emerald-900/20"
                >
                  Clear {unreadCount} Queue
                </button>
              )}
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between px-2">
          <p className="text-[#052c14]/70 text-[9px] font-black uppercase tracking-[0.3em]">
              Showing {filtered.length} Indexed Anomalies
          </p>
          <div className="w-1/2 h-[1px] bg-gradient-to-r from-emerald-100 to-transparent"></div>
      </div>

      {/* ── Loading ───────────────────────────────────────────────────── */}
      {loading && (
        <div className="flex flex-col items-center justify-center min-h-[30vh] gap-6">
          <div className="w-12 h-12 border-4 border-emerald-500
                          border-t-transparent rounded-full animate-spin shadow-[0_0_20px_rgba(16,185,129,0.1)]" />
          <p className="text-[#052c14]/70 text-[10px] font-black uppercase tracking-[0.3em] animate-pulse">Synchronizing Intelligence...</p>
        </div>
      )}

      {/* ── Error ──────────────────────────────────────────────────────── */}
      {error && (
        <div className="bg-red-50 border border-red-100
                        rounded-2xl p-6 text-center shadow-xl">
          <p className="text-red-600 text-xs font-black uppercase tracking-widest">{error}</p>
        </div>
      )}

      {/* ── No Alerts ─────────────────────────────────────────────────── */}
      {!loading && filtered.length === 0 && (
        <div className="flex flex-col items-center justify-center
                        min-h-[45vh] text-center bg-white/60 backdrop-blur-md rounded-[2.5rem] border border-emerald-100 shadow-xl relative overflow-hidden group">
           <div className="absolute inset-0 bg-gradient-to-br from-emerald-50/50 to-transparent opacity-50"></div>
          <div className="w-24 h-24 bg-white rounded-[2rem] flex items-center justify-center mb-8 border border-emerald-100 shadow-xl group-hover:scale-110 transition-transform duration-500">
            <span className="text-5xl">✅</span>
          </div>
          <h3 className="text-xl font-black text-[#052c14] mb-4 tracking-[0.2em] uppercase">
            Nominal Status
          </h3>
          <p className="text-[#052c14]/70 text-xs font-bold leading-relaxed max-w-sm uppercase tracking-widest">
            All systems calibrated. No critical Grade C deviations detected in the current registry subset.
          </p>
        </div>
      )}

      {/* ── Alerts List ───────────────────────────────────────────────── */}
      {!loading && filtered.length > 0 && (
        <div className="grid grid-cols-1 gap-6">
          {filtered.map((alert) => (
            <div
              key={alert.id}
              className={`group bg-white/90 backdrop-blur-md rounded-[2rem] p-8 border transition-all hover:shadow-2xl hover:bg-white
                          ${alert.read ? 'border-emerald-50/50 opacity-60' : 'border-red-100 shadow-xl relative'}`}
            >
              {!alert.read && (
                <div className="absolute -top-[1px] -left-[1px] w-24 h-24 pointer-events-none">
                  <div className="absolute top-0 left-0 w-3 h-3 bg-red-500 rounded-full m-8 animate-ping"></div>
                  <div className="absolute top-0 left-0 w-3 h-3 bg-red-500 rounded-full m-8"></div>
                </div>
              )}

              <div className="flex flex-col md:flex-row items-start justify-between gap-8 relative z-10">
                
                <div className="flex-1 w-full">
                  <div className="flex flex-wrap items-center gap-4 mb-6">
                    <span className="bg-[#052c14] text-white text-[9px] font-black px-4 py-1.5 rounded-lg uppercase tracking-[0.2em] shadow-lg">
                      {alert.farmer_id}
                    </span>
                    <span className={`text-[9px] font-black uppercase tracking-[0.2em] px-3 py-1.5 rounded-lg border shadow-sm
                                    ${alert.severity === 'critical' ? 'bg-red-50 border-red-100 text-red-600' : 
                                      alert.severity === 'high' ? 'bg-orange-50 border-orange-100 text-orange-600' : 
                                      'bg-yellow-50 border-yellow-100 text-yellow-600'}`}>
                      {alert.severity} PRIORITY
                    </span>
                    <span className="text-[#052c14]/60 text-[10px] font-black uppercase tracking-[0.2em] ml-auto">
                      {timeAgo(alert.timestamp)}
                    </span>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                    <div className="bg-emerald-50/40 p-5 rounded-2xl border border-emerald-100 relative group/stat hover:bg-white transition-all">
                      <p className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-widest mb-1 pb-1 border-b border-emerald-100/30">VFA Dynamic</p>
                      <p className="text-2xl font-black mt-2" style={{ color: getGradeColor(alert.grade) }}>
                        {alert.vfa?.toFixed(4)}
                      </p>
                    </div>
                    <div className="bg-emerald-50/40 p-5 rounded-2xl border border-emerald-100 relative group/stat hover:bg-white transition-all">
                      <p className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-widest mb-1 pb-1 border-b border-emerald-100/30">Rank Assignment</p>
                      <p className="text-2xl font-black text-[#052c14] mt-2">
                         {alert.grade}
                      </p>
                    </div>
                    <div className="bg-emerald-50/40 p-5 rounded-2xl border border-emerald-100 relative group/stat hover:bg-white transition-all">
                      <p className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-widest mb-1 pb-1 border-b border-emerald-100/30">pH Balance</p>
                      <p className="text-2xl font-black text-[#052c14]/80 mt-2">
                        {alert.pH?.toFixed(2)}
                      </p>
                    </div>
                    <div className="bg-emerald-50/40 p-5 rounded-2xl border border-emerald-100 relative group/stat hover:bg-white transition-all">
                      <p className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-widest mb-1 pb-1 border-b border-emerald-100/30">Thermal Data</p>
                      <p className="text-2xl font-black text-[#052c14]/80 mt-2">
                        {alert.temperature?.toFixed(1)}°C
                      </p>
                    </div>
                  </div>
                </div>

                <div className="flex flex-row md:flex-col items-center justify-between md:justify-center gap-6 w-full md:w-48 self-stretch border-t md:border-t-0 md:border-l border-emerald-100 pt-6 md:pt-0 md:pl-6">
                   <div className="text-center">
                      <p className="text-[#052c14]/60 text-[8px] font-black tracking-widest uppercase mb-1">Batch Key</p>
                      <p className="text-[#052c14]/60 text-[10px] font-mono tracking-tighter">{alert.sample_id?.slice(-12)}</p>
                   </div>
                   {!alert.read && (
                    <button
                      onClick={() => markAsRead(alert.id)}
                      className="flex-1 md:w-full py-4 bg-white hover:bg-emerald-600 hover:text-white border border-emerald-100 text-[#052c14] 
                                text-[10px] font-black uppercase tracking-[0.2em] rounded-2xl transition-all shadow-xl active:scale-95 group-hover:bg-emerald-50"
                    >
                      Acknowledge
                    </button>
                  )}
                  {alert.read && (
                     <div className="flex items-center gap-2 text-emerald-500">
                        <span className="text-xs font-black uppercase tracking-widest">Validated</span>
                        <span>✅</span>
                     </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

    </div>
  )
}

export default Alerts
