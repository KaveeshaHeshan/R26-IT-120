// src/pages/LoginPage.jsx

import { useEffect }   from 'react'
import { useNavigate } from 'react-router-dom'
import Login           from '../components/auth/Login'
import rubberBg        from '../assets/rubberproject.png'

const LoginPage = () => {

  const navigate = useNavigate()

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Login — Latex VFA Dashboard'
    return () => { document.title = 'Latex VFA Dashboard' }
  }, [])

  // ── Already logged in check ─────────────────────────────────────────────────
  useEffect(() => {
    const token  = localStorage.getItem('token')
    const role   = localStorage.getItem('role')
    const userId = localStorage.getItem('user_id')

    if (token && role && userId) {
      if (role === 'manager' || role === 'admin') {
        navigate('/', { replace: true })
      } else if (role === 'qa_officer') {
        navigate('/alerts', { replace: true })
      }
    }
  }, []) // ← navigate dependency remove ✅

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div
      className="min-h-screen relative flex flex-col overflow-hidden"
      style={{
        backgroundImage:    `url(${rubberBg})`,
        backgroundSize:     'cover',
        backgroundPosition: 'center',
        backgroundAttachment: 'fixed',
        backgroundRepeat:   'no-repeat',
      }}
    >

      {/* ── Background Overlay ───────────────────────────────────────────── */}
      <div className="absolute inset-0 bg-black/10
                      pointer-events-none" />
      <div className="absolute inset-0 backdrop-blur-[0.5px]
                      pointer-events-none" />

      {/* ── Content Wrapper ──────────────────────────────────────────────── */}
      <div className="relative z-10 flex flex-col min-h-screen">

        {/* ── Top Banner ───────────────────────────────────────────────────── */}
        <div className="bg-black/20 backdrop-blur-md py-3 px-4
                        text-center border-b border-white/10 shadow-lg">
          <p className="text-[#C9A84C] text-[13px] font-bold
                        tracking-wider uppercase">
            🌿 IoT-Enabled Rubber Latex VFA Prediction System
            <span className="mx-2 opacity-30">|</span>
            Lalan Rubbers (Pvt) Ltd
            <span className="mx-2 opacity-30">|</span>
            R26-IT-120
          </p>
        </div>

        {/* ── Login Portal ─────────────────────────────────────────────────── */}
        <div className="flex-1 flex items-center justify-center p-6">
          <Login />
        </div>

        {/* ── Bottom Footer ────────────────────────────────────────────────── */}
        <div className="bg-white/90 backdrop-blur-lg border-t
                        border-gray-200 px-8 py-3 flex items-center
                        justify-between
                        shadow-[0_-5px_20px_rgba(0,0,0,0.05)]">
          <div className="flex items-center gap-3">
            <span className="w-2 h-2 bg-green-500 rounded-full
                             animate-pulse" />
            <p className="text-gray-700 font-bold text-[11px]
                          tracking-tight">
              AI MODEL ACTIVE · SENSOR NETWORK ONLINE
            </p>
          </div>
          <p className="text-gray-500 text-[11px] font-medium">
            Senarathna V K P K H · IT22167132 · SLIIT · 2026
          </p>
        </div>

      </div>
    </div>
  )
}

export default LoginPage