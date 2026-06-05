// src/pages/LoginPage.jsx

import { useEffect } from 'react'
import Login from '../components/auth/Login'
import rubberBg from '../assets/rubberproject.png'

const LoginPage = () => {

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Terminal Login — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div
      className="min-h-screen relative flex flex-col overflow-hidden bg-white"
    >
      {/* ── Background Layer with subtle image blend ───────────────────────── */}
      <div 
        className="absolute inset-0 opacity-40 grayscale"
        style={{
          backgroundImage: `url(${rubberBg})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundAttachment: 'fixed',
        }}
      />

      {/* ── Gradient Overlay ───────────────────────────────────────────── */}
      <div className="absolute inset-0 bg-gradient-to-br from-white/95 via-white/80 to-emerald-500/10 pointer-events-none" />

      {/* ── Content Wrapper ──────────────────────────────────────────────── */}
      <div className="relative z-10 flex flex-col min-h-screen">
        
        {/* Simple Brand Header */}
        <div className="p-10 flex items-center justify-between">
           <div className="flex items-center gap-4">
              <div className="w-1 h-6 bg-emerald-600"></div>
              <p className="text-[10px] font-black uppercase tracking-[0.5em] text-[#052c14]">L-GUARD v2.4</p>
           </div>
           <div className="text-[9px] font-black uppercase tracking-widest text-[#052c14]/30 px-4 py-1.5 border border-emerald-100 rounded-full">
              Region: South Asia Core
           </div>
        </div>

        {/* ── Login Portal ─────────────────────────────────────────────────── */}
        <div className="flex-1 flex items-center justify-center p-6 sm:p-12">
          <Login />
        </div>

        {/* Simple Footer */}
        <div className="p-10 flex items-center justify-center">
            <p className="text-[9px] font-black uppercase tracking-[0.4em] text-[#052c14]/20 flex items-center gap-4">
               <span>Secure Access</span>
               <span className="w-1 h-1 bg-emerald-200 rounded-full"></span>
               <span>Biometric Encrypted</span>
               <span className="w-1 h-1 bg-emerald-200 rounded-full"></span>
               <span>Audit Logged</span>
            </p>
        </div>
      </div>
    </div>
  )
}

export default LoginPage
