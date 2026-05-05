// src/pages/LoginPage.jsx

import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import Login from '../components/auth/Login'

const LoginPage = () => {

  const navigate = useNavigate()

  // ── Page title ──────────────────────────────────────────────────────────────
  useEffect(() => {
    document.title = 'Login — Latex VFA Dashboard'
    return () => { document.title = 'Latex VFA Dashboard' }
  }, [])

  // ── Already logged in check ─────────────────────────────────────────────────
  useEffect(() => {
    const token = localStorage.getItem('token')
    const role  = localStorage.getItem('role')
    const userId = localStorage.getItem('user_id')

    if (token && role && userId) {
      // Redirect based on role
      if (role === 'manager' || role === 'admin') {
        navigate('/', { replace: true })
      } else if (role === 'qa_officer') {
        navigate('/alerts', { replace: true })
      }
    }
  }, [navigate])

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#F4F6F9]">

      {/* ── Top Banner ───────────────────────────────────────────────────────── */}
      <div className="bg-[#1F3864] py-2 px-4 text-center">
        <p className="text-[#C9A84C] text-xs font-medium">
          🌿 IoT-Enabled Rubber Latex VFA Prediction System
          · Lalan Rubbers (Pvt) Ltd · R26-IT-120
        </p>
      </div>

      {/* ── Login Component ──────────────────────────────────────────────────── */}
      <Login />

      {/* ── Bottom Info ──────────────────────────────────────────────────────── */}
      <div className="fixed bottom-0 left-0 right-0
                      bg-white border-t border-gray-200
                      px-6 py-2 flex items-center justify-between">
        <p className="text-gray-400 text-xs">
          IoT Sensor Device + ML Model + KPI Dashboard
        </p>
        <p className="text-gray-400 text-xs">
          Senarathna V K P K H · IT22167132 · SLIIT · 2026
        </p>
      </div>

    </div>
  )
}

export default LoginPage