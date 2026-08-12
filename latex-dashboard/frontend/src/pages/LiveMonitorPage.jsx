// src/pages/LiveMonitorPage.jsx

import { useEffect } from 'react'
import LiveMonitor from '../components/dashboard/LiveMonitor'
import { ROLES } from '../constants/roles'

const LiveMonitorPage = () => {

  const role = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Live Signal — Latex VFA Dashboard'
    return () => {
      document.title = 'Latex VFA Dashboard'
    }
  }, [])

  // ── Access check ────────────────────────────────────────────────────────────
  const allowedRoles = [ROLES.MANAGER, ROLES.ADMIN]
  if (!allowedRoles.includes(role)) {
    return (
      <div className="flex flex-col items-center justify-center
                      min-h-[60vh] text-center px-4">
        <div className="text-6xl mb-8 filter grayscale opacity-20">🔒</div>
        <h2 className="text-2xl font-black text-[#052c14] mb-4 tracking-[0.2em] uppercase">
          Access Denied
        </h2>
        <p className="text-[#052c14]/70 text-xs font-bold uppercase tracking-widest max-w-xs leading-relaxed">
          The real-time telemetry stream is restricted to secure terminal operators only.
        </p>
        <p className="text-[#052c14]/60 text-[10px] font-black mt-6 px-4 py-2 border border-emerald-100 rounded-lg uppercase tracking-widest">
          Permission Token Required: Admin/Manager
        </p>
      </div>
    )
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="flex flex-col min-h-screen bg-white">

      {/* ── Page Header ──────────────────────────────────────────────────────── */}
      <div className="bg-white/80 backdrop-blur-xl border-b border-emerald-100
                      px-10 py-8 flex items-center justify-between shadow-sm sticky top-0 z-50">
        <div className="flex items-center gap-6">
          <div className="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center border border-emerald-100 shadow-xl overflow-hidden relative">
             <div className="absolute inset-0 bg-emerald-500/5 animate-pulse"></div>
             <span className="text-2xl relative z-10">📡</span>
          </div>
          <div>
            <h1 className="text-2xl font-black text-[#052c14] tracking-tighter uppercase leading-none">
              Live Telemetry
            </h1>
            <p className="text-[#052c14]/70 text-[9px] mt-2 uppercase tracking-[0.3em] font-black flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shadow-[0_0_10px_rgba(16,185,129,0.8)]"></span>
              Synchronized Local Sockets • Active Stream
            </p>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <div className="bg-white px-5 py-2.5 rounded-2xl border border-emerald-100 shadow-sm flex items-center gap-3">
             <span className="text-[10px] font-black text-[#052c14]/80 uppercase tracking-widest">Signal Strength</span>
             <div className="flex gap-[2px]">
                <div className="w-1 h-3 bg-emerald-500 rounded-[1px]"></div>
                <div className="w-1 h-3 bg-emerald-500 rounded-[1px]"></div>
                <div className="w-1 h-3 bg-emerald-500 rounded-[1px]"></div>
                <div className="w-1 h-3 bg-emerald-200 rounded-[1px]"></div>
             </div>
          </div>
          <div className="hidden md:flex flex-col items-end border-l border-emerald-100 pl-6 ml-2">
            <span className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-widest mb-1">Authenticated Node</span>
            <span className="text-[#052c14]/60 text-[10px] font-mono font-bold">{userId?.slice(0, 12)}</span>
          </div>
        </div>
      </div>

      {/* ── Content ──────────────────────────────────────────────────────────── */}
      <div className="flex-1 p-10 overflow-x-hidden max-w-[1600px] mx-auto w-full">
        <LiveMonitor />
      </div>

      {/* ── Footer ───────────────────────────────────────────────────────────── */}
      <div className="bg-emerald-50/30 border-t border-emerald-100/50
                      px-10 py-8 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-4">
           <div className="w-2 h-2 rounded-full bg-emerald-500/20"></div>
           <p className="text-[#052c14]/60 text-[9px] font-black uppercase tracking-[0.2em]">
             WebSocket Engine • Sub-1s Latency • Secure Lattice
           </p>
        </div>
        <div className="flex items-center gap-4">
           <span className="text-[#052c14]/70 text-[9px] font-bold tracking-widest bg-white border border-emerald-100 px-4 py-1.5 rounded-full shadow-sm">
             STATUS: TRANSMITTING
           </span>
           <p className="text-[#052c14]/75 text-[9px] font-black tracking-widest">
             © 2026 LATEXGUARD CORE
           </p>
        </div>
      </div>

    </div>
  )
}

export default LiveMonitorPage
