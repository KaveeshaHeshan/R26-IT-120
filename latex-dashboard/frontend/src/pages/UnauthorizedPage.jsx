// src/pages/UnauthorizedPage.jsx

import { useEffect }    from 'react'
import { useNavigate }  from 'react-router-dom'
import { getRoleLabel } from '../constants/roles'

const UnauthorizedPage = () => {

  const navigate = useNavigate()
  const role     = localStorage.getItem('role')
  const userId   = localStorage.getItem('user_id')

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Access Denied — Latex VFA Dashboard'
    return () => { document.title = 'Latex VFA Dashboard' }
  }, [])

  // ── Go back to correct page ─────────────────────────────────────────────────
  const handleGoBack = () => {
    if (role === 'manager' || role === 'admin') {
      navigate('/')
    } else if (role === 'qa_officer') {
      navigate('/alerts')
    } else {
      navigate('/login')
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  const handleLogout = () => {
    localStorage.clear()
    navigate('/login')
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#F4F6F9]
                    flex items-center justify-center px-4">
      <div className="bg-white rounded-2xl shadow-xl
                      p-10 w-full max-w-md text-center">

        {/* ── Icon ─────────────────────────────────────────────────────────── */}
        <div className="text-7xl mb-4">🔒</div>

        {/* ── Title ────────────────────────────────────────────────────────── */}
        <h1 className="text-2xl font-bold text-[#1F3864] mb-2">
          Access Denied
        </h1>

        {/* ── Message ──────────────────────────────────────────────────────── */}
        <p className="text-gray-500 text-sm mb-1">
          You do not have permission to view this page.
        </p>

        {/* ── Current role ─────────────────────────────────────────────────── */}
        {role && (
          <div className="inline-flex items-center gap-2
                          bg-[#F4F6F9] px-3 py-1.5
                          rounded-full mb-6 mt-2">
            <span className="text-gray-400 text-xs">
              Logged in as:
            </span>
            <span className="text-[#1F3864] text-xs font-semibold">
              {userId}
            </span>
            <span className="text-[#C9A84C] text-xs">
              · {getRoleLabel(role)}
            </span>
          </div>
        )}

        {/* ── Access level info ────────────────────────────────────────────── */}
        <div className="bg-[#F4F6F9] rounded-xl p-4 mb-6 text-left">
          <p className="text-xs font-semibold text-gray-600 mb-3">
            Dashboard Access Levels:
          </p>
          <div className="space-y-2.5">

            {/* Manager */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-base">🏭</span>
                <span className="text-xs text-gray-600 font-medium">
                  Factory Manager
                </span>
              </div>
              <div className="flex gap-1">
                {['Live', 'Farmer', 'Alerts', 'Summary'].map(v => (
                  <span key={v}
                    className="bg-green-100 text-green-700
                               text-xs px-1.5 py-0.5 rounded">
                    {v}
                  </span>
                ))}
              </div>
            </div>

            {/* QA Officer */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-base">🔬</span>
                <span className="text-xs text-gray-600 font-medium">
                  QA Officer
                </span>
              </div>
              <div className="flex gap-1">
                {['Alerts', 'Summary'].map(v => (
                  <span key={v}
                    className="bg-yellow-100 text-yellow-700
                               text-xs px-1.5 py-0.5 rounded">
                    {v}
                  </span>
                ))}
              </div>
            </div>

            {/* Admin */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-base">⚙️</span>
                <span className="text-xs text-gray-600 font-medium">
                  Admin
                </span>
              </div>
              <div className="flex gap-1">
                {['Live', 'Farmer', 'Alerts', 'Summary'].map(v => (
                  <span key={v}
                    className="bg-blue-100 text-blue-700
                               text-xs px-1.5 py-0.5 rounded">
                    {v}
                  </span>
                ))}
              </div>
            </div>

          </div>
        </div>

        {/* ── Buttons ──────────────────────────────────────────────────────── */}
        <div className="flex gap-3">
          <button
            onClick={handleGoBack}
            className="flex-1 bg-[#1F3864] text-white text-sm
                       font-medium py-2.5 rounded-xl
                       hover:bg-[#162a4a] active:bg-[#0f1e35]
                       transition"
          >
            Go to Dashboard
          </button>
          <button
            onClick={handleLogout}
            className="flex-1 bg-gray-100 text-gray-700 text-sm
                       font-medium py-2.5 rounded-xl
                       hover:bg-gray-200 active:bg-gray-300
                       transition"
          >
            Logout
          </button>
        </div>

        {/* ── Footer ───────────────────────────────────────────────────────── */}
        <p className="text-gray-400 text-xs mt-6">
          R26-IT-120 · SLIIT · 2026
        </p>

      </div>
    </div>
  )
}

export default UnauthorizedPage