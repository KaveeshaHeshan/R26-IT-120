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
    if (['manager', 'qa_officer', 'admin'].includes(role)) {
      navigate('/summary')
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
    <div className="min-h-screen flex items-center justify-center px-4 bg-white relative overflow-hidden">
      
      {/* Background Decor */}
      <div className="absolute top-0 left-0 w-full h-full opacity-[0.03] pointer-events-none">
        <div className="absolute top-[-10%] right-[-10%] w-[60%] h-[60%] bg-emerald-500 rounded-full blur-[120px]"></div>
        <div className="absolute bottom-[-10%] left-[-10%] w-[60%] h-[60%] bg-emerald-500 rounded-full blur-[120px]"></div>
      </div>

      <div className="bg-white/90 backdrop-blur-xl rounded-[3rem] shadow-2xl border border-emerald-100
                      p-12 w-full max-w-lg text-center relative z-10 transition-all hover:shadow-emerald-500/5">

        {/* ── Icon ─────────────────────────────────────────────────────────── */}
        <div className="w-24 h-24 bg-emerald-50 rounded-[2rem] flex items-center justify-center mx-auto mb-10 border border-emerald-100 shadow-xl relative">
          <div className="absolute inset-0 bg-red-500/5 animate-pulse rounded-[2rem]"></div>
          <span className="text-5xl relative z-10">🔒</span>
        </div>

        {/* ── Title ────────────────────────────────────────────────────────── */}
        <h1 className="text-3xl font-black text-[#052c14] mb-4 tracking-[0.2em] uppercase leading-none">
          Access Intercepted
        </h1>

        {/* ── Message ──────────────────────────────────────────────────────── */}
        <p className="text-[#052c14]/70 text-xs font-bold uppercase tracking-[0.2em] mb-10 max-w-xs mx-auto leading-relaxed">
          The security layer has denied access to this terminal node based on your current authorization token.
        </p>

        {/* ── Current role ─────────────────────────────────────────────────── */}
        {role && (
          <div className="bg-emerald-50/50 border border-emerald-100/50 rounded-2xl p-6 mb-10 shadow-inner">
            <p className="text-[#052c14]/60 text-[8px] font-black uppercase tracking-[0.3em] mb-3">Identity Node Information</p>
            <div className="flex items-center justify-center gap-4">
              <span className="text-[10px] font-mono font-black text-[#052c14]/75">{userId?.slice(0, 16)}</span>
              <div className="w-1 h-3 bg-emerald-200"></div>
              <span className="text-[10px] font-black text-emerald-600 uppercase tracking-widest">{getRoleLabel(role)}</span>
            </div>
          </div>
        )}

        {/* ── Action Buttons ───────────────────────────────────────────────── */}
        <div className="grid grid-cols-2 gap-6">
          <button
            onClick={handleLogout}
            className="px-8 py-5 bg-white hover:bg-red-50 text-red-600 border border-red-100 
                       text-[10px] font-black uppercase tracking-[0.2em] rounded-2xl transition-all shadow-lg active:scale-95"
          >
            Terminal Logout
          </button>
          <button
            onClick={handleGoBack}
            className="px-8 py-5 bg-emerald-600 hover:bg-emerald-700 text-white 
                       text-[10px] font-black uppercase tracking-[0.25em] rounded-2xl transition-all shadow-xl active:scale-95"
          >
            Re-Route Session
          </button>
        </div>

        <div className="mt-12 flex items-center justify-center gap-4">
          <div className="w-12 h-[1px] bg-emerald-100"></div>
          <p className="text-[#052c14]/60 text-[9px] font-black uppercase tracking-[0.3em]">
             Lattice Secure Node 403
          </p>
          <div className="w-12 h-[1px] bg-emerald-100"></div>
        </div>
      </div>
    </div>
  )
}

export default UnauthorizedPage
