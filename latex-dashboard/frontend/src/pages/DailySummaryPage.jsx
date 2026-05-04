// src/pages/DailySummaryPage.jsx

import { useEffect }  from 'react'
import DailySummary   from '../components/dashboard/DailySummary'
import { ROLES }      from '../constants/roles'

const DailySummaryPage = () => {

  const role   = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Daily Summary — Latex VFA Dashboard'
    return () => { document.title = 'Latex VFA Dashboard' }
  }, [])

  // ── Access check ────────────────────────────────────────────────────────────
  const allowedRoles = [ROLES.MANAGER, ROLES.QA_OFFICER, ROLES.ADMIN]
  if (!allowedRoles.includes(role)) {
    return (
      <div className="flex flex-col items-center justify-center
                      min-h-[60vh] text-center px-4">
        <div className="text-6xl mb-4">🔒</div>
        <h2 className="text-2xl font-bold text-[#1F3864] mb-2">
          Access Denied
        </h2>
        <p className="text-gray-500 text-sm">
          You do not have permission to view Daily Summary.
        </p>
        <p className="text-gray-400 text-xs mt-1">
          Required role: Manager, QA Officer or Admin
        </p>
      </div>
    )
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="flex flex-col min-h-screen bg-[#F4F6F9]">

      {/* ── Page Header ──────────────────────────────────────────────────────── */}
      <div className="bg-white border-b border-gray-200
                      px-6 py-4 flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold text-[#1F3864]
                         flex items-center gap-2">
            📊 Daily Summary
          </h1>
          <p className="text-gray-500 text-sm mt-0.5">
            Factory collection statistics and grade distribution
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-[#1F3864] text-xs font-medium
                           bg-blue-50 px-3 py-1 rounded-full
                           border border-blue-200">
            📅 {new Date().toLocaleDateString('en-US', {
              weekday: 'long',
              year:    'numeric',
              month:   'long',
              day:     'numeric',
            })}
          </span>
          <span className="text-gray-400 text-xs">
            · {userId}
          </span>
        </div>
      </div>

      {/* ── Content ──────────────────────────────────────────────────────────── */}
      <div className="flex-1 p-6">
        <DailySummary />
      </div>

      {/*  Footer  */}
      <div className="bg-white border-t border-gray-200
                      px-6 py-3 flex items-center justify-between">
        <p className="text-gray-400 text-xs">
          IoT Sensor Device + ML Model + KPI Dashboard
        </p>
        <p className="text-gray-400 text-xs">
          R26-IT-120 · SLIIT · 2026
        </p>
      </div>

    </div>
  )
}

export default DailySummaryPage