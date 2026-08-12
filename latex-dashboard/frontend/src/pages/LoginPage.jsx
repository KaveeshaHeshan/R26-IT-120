// src/pages/LoginPage.jsx

import { useEffect } from 'react'
import { Link } from 'react-router-dom'
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

      {/* ── NAVBAR ────────────────────────────────────────────────────── */}
      <nav className="w-full bg-[#0a3622] text-white px-8 py-3 flex items-center justify-between z-50 relative shadow-md">
        <div className="flex items-center gap-2">
          <img
            src={logoImg}
            alt="LatexGuard Logo"
            className="h-12 md:h-16 lg:h-20 w-auto object-contain drop-shadow-md transition-transform hover:scale-105"
          />
        </div>

        <div className="hidden md:flex items-center gap-10 text-sm font-medium tracking-wide">
          <a href="#" className="hover:text-teal-300 transition-colors">HOME</a>
          <a href="#" className="hover:text-teal-300 transition-colors">PRODUCTS</a>
          <a href="#" className="hover:text-teal-300 transition-colors">TEST PORTAL</a>
          <a href="#" className="hover:text-teal-300 transition-colors">CONTACT US</a>
        </div>

        <Link to="/">
          <button className="bg-[#e9eff1] hover:bg-white text-[#0a3622] px-8 py-2.5 rounded-full text-sm font-bold tracking-wide transition-all shadow-sm">
            BACK TO HOME
          </button>
        </Link>
      </nav>

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
