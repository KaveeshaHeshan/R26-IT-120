// src/pages/LoginPage.jsx

import { useEffect } from 'react'
import { Link } from 'react-router-dom'
import { motion } from 'framer-motion'
import Login from '../components/auth/Login'
import rubberBg from '../assets/rubberproject.png'
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

      {/* ── MAIN SPLIT LAYOUT ──────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col lg:flex-row min-h-0">

        {/* Left — Background image with overlay text */}
        <div className="relative lg:w-1/2 h-64 lg:h-auto overflow-hidden">
          <img
            src={rubberBg}
            alt="Rubber plantation"
            className="w-full h-full object-cover object-center"
          />
          {/* Dark green gradient overlay */}
          <div className="absolute inset-0 bg-linear-to-r from-[#0a3622]/85 via-[#0a3622]/50 to-transparent" />
          {/* Text overlay */}
          <div className="absolute bottom-16 left-10 pr-8">
            <p className="text-[#c9a84c] text-xs font-bold uppercase tracking-[0.3em] mb-3 drop-shadow-md">
              Smart Quality Protection
            </p>
            <h2 className="text-4xl lg:text-5xl font-black text-[#c9a84c] leading-tight uppercase tracking-wide drop-shadow-lg">
              SECURE <br /> PORTAL
            </h2>
            <h2 className="text-4xl lg:text-5xl font-black text-white leading-tight uppercase tracking-wide drop-shadow-lg">
              ACCESS
            </h2>
          </div>
        </div>

        {/* Right — Login card */}
        <div className="lg:w-1/2 flex items-center justify-center bg-linear-to-br from-[#f0f4f4] to-[#f8fafa] px-6 py-12">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: 'easeOut' }}
            className="w-full"
          >
            <Login />
          </motion.div>
        </div>

      </div>
    </div>
  )
}

export default LoginPage
