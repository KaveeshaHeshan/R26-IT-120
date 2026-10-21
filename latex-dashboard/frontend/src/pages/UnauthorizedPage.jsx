// src/pages/UnauthorizedPage.jsx

import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { getRoleLabel } from '../constants/roles'

const UnauthorizedPage = () => {
  const navigate = useNavigate()
  const role = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')

  useEffect(() => {
    document.title = 'Access denied — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  const handleGoBack = () => {
    if (['manager', 'qa_officer', 'admin'].includes(role)) navigate('/overview')
    else navigate('/login')
  }

  const handleLogout = () => {
    localStorage.clear()
    navigate('/login')
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4 bg-bg">
      <div className="bg-surface rounded-xl border border-border shadow-sm p-10 w-full max-w-md text-center">
        <div className="w-14 h-14 rounded-xl bg-slate-100 flex items-center justify-center mx-auto mb-6 text-2xl">
          🔒
        </div>
        <h1 className="text-xl font-semibold text-ink mb-2">Access denied</h1>
        <p className="text-sm text-muted mb-6">
          Your account doesn&apos;t have permission to view this page.
        </p>

        {role && (
          <div className="bg-slate-50 border border-border rounded-lg p-4 mb-6 text-sm">
            <span className="font-mono text-muted">{userId?.slice(0, 16)}</span>
            <span className="mx-2 text-faint">·</span>
            <span className="text-ink">{getRoleLabel(role)}</span>
          </div>
        )}

        <div className="grid grid-cols-2 gap-3">
          <button
            onClick={handleLogout}
            className="px-4 py-2.5 rounded-lg border border-border text-sm font-medium text-muted hover:bg-red-50 hover:text-red-600 hover:border-red-200 transition-colors"
          >
            Sign out
          </button>
          <button
            onClick={handleGoBack}
            className="px-4 py-2.5 rounded-lg bg-brand text-white text-sm font-medium hover:bg-brand-dark transition"
          >
            Go back
          </button>
        </div>
      </div>
    </div>
  )
}

export default UnauthorizedPage
