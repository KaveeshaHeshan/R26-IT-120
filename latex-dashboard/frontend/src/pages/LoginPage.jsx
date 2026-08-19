// src/pages/LoginPage.jsx

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import Login from '../components/auth/Login'
import logoImg from '../assets/logo_transparent.png'

const LoginPage = () => {

  useEffect(() => {
    document.title = 'Portal Login — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  return (
    <div className="min-h-screen flex flex-col overflow-hidden bg-white">

      {/* ── HEADER ────────────────────────────────────────────────────── */}
      <header className="w-full bg-[#0a3622] text-white px-8 py-3 flex items-center justify-between z-50 relative shadow-md">
        <div className="flex items-center gap-2">
          <img
            src={logoImg}
            alt="LatexGuard Logo"
            className="h-12 md:h-16 w-auto object-contain drop-shadow-md"
          />
        </div>
      </header>

      {/* ── MAIN HERO LAYOUT (centered login layout) ───────────────────────────── */}
      <div className="flex-1 flex items-center justify-center bg-[#fcfdfc] p-6">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
          className="w-full max-w-md"
        >
          <Login />
        </motion.div>
      </div>
    </div>
  )
}

export default LoginPage
