// src/pages/LiveMonitorPage.jsx

import { useEffect }                    from 'react'
import LiveMonitor                      from '../components/dashboard/LiveMonitor'
import { ROLES }                        from '../constants/roles'

const LiveMonitorPage = () => {

  const role   = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Live Monitor — Latex VFA Dashboard'
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
        <div className="text-6xl mb-4">🔒</div>
        <h2 className="text-2xl font-bold text-[#1F3864] mb-2">
          Access Denied
        </h2>
        <p className="text-gray-500 text-sm">
          You do not have permission to view Live Monitor.
        </p>
        <p className="text-gray-400 text-xs mt-1">
          Required role: Manager or Admin
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
          <h1 className="text-xl font-bold text-[#1F3864] flex items-center gap-2">
            📡 Live Monitor
          </h1>
          <p className="text-gray-500 text-sm mt-0.5">
            Real-time VFA prediction at latex collection points
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
          <span className="text-green-600 text-xs font-medium">
            Live
          </span>
          <span className="text-gray-400 text-xs">
            · {userId}
          </span>
        </div>
      </div>

      {/* ── Content ──────────────────────────────────────────────────────────── */}
      <div className="flex-1 p-6">
        <LiveMonitor />
      </div>

      {/* ── Footer ───────────────────────────────────────────────────────────── */}
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

export default LiveMonitorPage