// src/pages/DailySummaryPage.jsx

import { useEffect } from 'react'
import DailySummary from '../components/dashboard/DailySummary'
import { ROLES } from '../constants/roles'

const DailySummaryPage = () => {

  const role = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Intelligence Summary — Latex VFA Dashboard'
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
        <p className="text-[#052c14]/70 text-xs font-bold uppercase tracking-widest max-w-xs leading-relaxed">
          The intelligence summary is restricted to authorized analytical personnel only.
        </p>
        <p className="text-[#052c14]/60 text-[10px] font-black mt-6 px-4 py-2 border border-emerald-100 rounded-lg uppercase tracking-widest">
          Permission Token Required: Manager/QA/Admin
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
          <div className="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center border border-emerald-100 shadow-xl">
             <span className="text-2xl">📊</span>
          </div>
          <div>
            <h1 className="text-2xl font-black text-[#052c14] tracking-tighter uppercase leading-none">
              Intelligence Summary
            </h1>
            <p className="text-[#052c14]/70 text-[9px] mt-2 uppercase tracking-[0.3em] font-black flex items-center gap-2">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"></span>
              Daily Yield Metrics • Statistical Grade Distribution
            </p>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <div className="bg-emerald-50 px-5 py-2.5 rounded-2xl border border-emerald-100 shadow-inner flex items-center gap-3">
             <span className="text-emerald-500 text-lg">📅</span>
             <span className="text-[#052c14] text-[10px] font-black uppercase tracking-widest">
               {new Date().toLocaleDateString('en-US', {
                  month: 'short',
                  day: 'numeric',
                  year: 'numeric',
                })}
             </span>
          </div>
          <div className="hidden md:block w-[1px] h-8 bg-emerald-100 mx-2"></div>
          <div className="hidden md:flex flex-col items-end">
            <span className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-widest mb-1">Authenticated Node</span>
            <span className="text-[#052c14]/60 text-[10px] font-mono font-bold">{userId?.slice(0, 12)}</span>
          </div>
        </div>
      </div>

      {/* ── Content ──────────────────────────────────────────────────────────── */}
      <div className="flex-1 p-10 overflow-x-hidden max-w-[1600px] mx-auto w-full">
        <DailySummary />
      </div>

      {/* ── Footer ───────────────────────────────────────────────────────────── */}
      <div className="bg-emerald-50/30 border-t border-emerald-100/50
                      px-10 py-8 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-4">
           <div className="w-2 h-2 rounded-full bg-emerald-500/20"></div>
           <p className="text-[#052c14]/60 text-[9px] font-black uppercase tracking-[0.2em]">
             Statistical Modeling • VFA Aggregate v1.2 • Secure Lattice
           </p>
        </div>
        <div className="flex items-center gap-4">
           <span className="text-[#052c14]/70 text-[9px] font-bold tracking-widest bg-white border border-emerald-100 px-4 py-1.5 rounded-full shadow-sm">
             METRIC SYNC: NOMINAL
           </span>
           <p className="text-[#052c14]/75 text-[9px] font-black tracking-widest">
             © 2026 LATEXGUARD CORE
           </p>
        </div>
      </div>

    </div>
  )
}

export default DailySummaryPage
