// src/pages/LoginPage.jsx

import { useEffect } from 'react'
import { motion } from 'framer-motion'
import Login from '../components/auth/Login'
import BrandMark from '../components/ui/BrandMark'

const PILLS = [
  { color: '#7BE08F', label: 'Volume by district' },
  { color: '#E0A526', label: 'VFA grading' },
  { color: '#9CC9FF', label: 'Farmer activity' },
]

const LoginPage = () => {
  useEffect(() => {
    document.title = 'Sign in — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  return (
    <div className="flex flex-wrap min-h-screen font-[Figtree]">
      {/* Left panel */}
      <div className="flex-[1_1_480px] relative overflow-hidden bg-forest-900 flex flex-col justify-between gap-10 p-12 sm:p-14">
        <div className="relative z-10 self-start">
          <BrandMark variant="dark" size="lg" />
        </div>

        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          className="relative z-10 max-w-[520px]"
        >
          <h1 className="font-display text-5xl font-bold leading-[1.08] tracking-[-0.025em] text-white">
            From the tapping line to the final grade.
          </h1>
          <p className="mt-5 text-lg text-[#BFD3C5]">
            Track latex volume, farmer activity and VFA quality across every district in one place.
          </p>
        </motion.div>

        <div className="relative z-10 flex flex-wrap gap-2">
          {PILLS.map((p) => (
            <span
              key={p.label}
              className="inline-flex items-center gap-2 rounded-full bg-white/8 px-[14px] py-2 text-sm font-medium text-[#E3EEE6]"
            >
              <span className="w-2 h-2 rounded-full" style={{ background: p.color }} />
              {p.label}
            </span>
          ))}
        </div>

        {/* Decorative concentric circles + leaf outline, partly off-canvas */}
        <svg
          className="absolute -bottom-24 -right-24 w-[420px] h-[420px] pointer-events-none"
          viewBox="0 0 600 600"
          fill="none"
          aria-hidden="true"
        >
          <circle cx="300" cy="300" r="300" stroke="#1D4A32" strokeWidth="2" />
          <circle cx="300" cy="300" r="220" stroke="#1D4A32" strokeWidth="2" />
          <circle cx="300" cy="300" r="140" stroke="#1D4A32" strokeWidth="2" />
          <path
            d="M300 460 C300 400 300 340 300 300 C300 240 335 205 375 192"
            stroke="#2E6B47"
            strokeWidth="3"
            strokeLinecap="round"
            fill="none"
          />
          <path
            d="M300 340 C262 322 232 282 232 242 C272 252 300 282 300 340Z"
            fill="none"
            stroke="#3E8A5C"
            strokeWidth="3"
            strokeLinejoin="round"
          />
          <path
            d="M300 300 C338 280 368 242 368 202 C330 212 300 242 300 300Z"
            fill="none"
            stroke="#3E8A5C"
            strokeWidth="3"
            strokeLinejoin="round"
          />
        </svg>
      </div>

      {/* Right panel */}
      <div className="flex-[1_1_480px] flex items-center justify-center bg-white p-12 sm:p-8">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: 'easeOut' }}
          className="w-full max-w-[440px] flex flex-col gap-7"
        >
          <div>
            <h2 className="font-display text-[34px] font-bold text-[#11231A]">Sign in</h2>
            <p className="mt-1 text-base text-[#5A6B5F]">Factory reporting dashboard</p>
          </div>
          <Login />
        </motion.div>
      </div>
    </div>
  )
}

export default LoginPage
