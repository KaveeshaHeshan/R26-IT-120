// src/pages/AlertsPage.jsx

import { useEffect } from 'react'
import Alerts from '../components/dashboard/Alerts'
import { ROLES } from '../constants/roles'

const AlertsPage = () => {

  const role = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Alerts — Latex VFA Dashboard'
    return () => { document.title = 'Latex VFA Dashboard' }
  }, [])

  // ── Access check ────────────────────────────────────────────────────────────
  const allowedRoles = [ROLES.MANAGER, ROLES.QA_OFFICER, ROLES.ADMIN]
  if (!allowedRoles.includes(role)) {
    return (
      <div className="flex flex-col items-center justify-center
                      min-h-[60vh] text-center px-4">
        <div className="text-6xl mb-8 filter grayscale opacity-20">🔒</div>
        <h2 className="text-2xl font-black text-[#052c14] mb-4 tracking-[0.2em] uppercase">
          Access Denied
        </h2>
        <p className="text-[#052c14]/30 text-xs font-bold uppercase tracking-widest max-w-xs leading-relaxed">
          The security layer has intercepted an unauthorized request to access critical logs.
        </p>
        <p className="text-[#052c14]/20 text-[10px] font-black mt-6 px-4 py-2 border border-emerald-100 rounded-lg uppercase tracking-widest">
          Permission Token Required: Manager/Admin
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
          <div className="w-14 h-14 bg-red-50 rounded-2xl flex items-center justify-center border border-red-100 shadow-xl">
             <span className="text-2xl">🔔</span>
          </div>
          <div>
            <h1 className="text-2xl font-black text-[#052c14] tracking-tighter uppercase leading-none">
              Alerts Center
            </h1>
            <p className="text-[#052c14]/30 text-[9px] mt-2 uppercase tracking-[0.3em] font-black flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"></span>
              Anomaly Detection Active • Batch Scrutiny Enabled
            </p>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <div className="hidden md:flex flex-col items-end">
            <span className="text-[#052c14]/20 text-[8px] font-black uppercase tracking-widest mb-1">Authenticated Session</span>
            <span className="text-[#052c14]/60 text-[10px] font-mono font-bold">NODE-{userId?.slice(0, 12)}</span>
          </div>
          <div className="w-10 h-10 border border-emerald-100 rounded-full flex items-center justify-center bg-emerald-50 shadow-inner">
             <span className="text-[10px] font-black text-emerald-600">QA</span>
          </div>
        </div>
      </div>

      {/* ── Content ──────────────────────────────────────────────────────────── */}
      <div className="flex-1 p-10 overflow-x-hidden max-w-[1600px] mx-auto w-full">
        <Alerts />
      </div>

      {/* ── Footer ───────────────────────────────────────────────────────────── */}
      <div className="bg-emerald-50/30 border-t border-emerald-100/50
                      px-10 py-8 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-4">
           <div className="w-2 h-2 rounded-full bg-emerald-500/20"></div>
           <p className="text-[#052c14]/20 text-[9px] font-black uppercase tracking-[0.2em]">
             Cloud Infrastructure • VFA Engine v2.4 • Emerald Guard
           </p>
        </div>
        <div className="flex items-center gap-4">
           <span className="text-[#052c14]/30 text-[9px] font-bold tracking-widest bg-white border border-emerald-100 px-3 py-1 rounded-full shadow-sm">
             STATUS: OPERATIONAL
           </span>
           <p className="text-[#052c14]/40 text-[9px] font-black tracking-widest">
             © 2026 LATEXGUARD CORE
           </p>
        </div>
      </div>

    </div>
  )
}

export default AlertsPage
