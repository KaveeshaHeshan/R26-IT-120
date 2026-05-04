// src/components/auth/Login.jsx

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { getGradeIcon } from '../../utils/gradeHelper'

const Login = () => {

  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const [error,    setError]    = useState('')
  const [loading,  setLoading]  = useState(false)
  const navigate = useNavigate()

  // ── Handle Login ────────────────────────────────────────────────────────────
  const handleLogin = async () => {
    if (!email || !password) {
      setError('Please enter email and password.')
      return
    }

    setLoading(true)
    setError('')

    try {
      // M2 Security API auth endpoint
      const res = await axios.post(
        `${import.meta.env.VITE_API_BASE_URL}/auth/login`,
        { email, password },
        { headers: { 'Content-Type': 'application/json' } }
      )

      // Store JWT + role + user info
      localStorage.setItem('token',   res.data.token)
      localStorage.setItem('role',    res.data.role)
      localStorage.setItem('user_id', res.data.user_id)
      localStorage.setItem('name',    res.data.name)

      // Role based redirect
      switch (res.data.role) {
        case 'manager':
          navigate('/')
          break
        case 'qa_officer':
          navigate('/alerts')
          break
        case 'admin':
          navigate('/')
          break
        default:
          navigate('/unauthorized')
      }

    } catch (err) {
      if (err.response?.status === 401) {
        setError('Invalid email or password.')
      } else if (err.response?.status === 403) {
        setError('Access denied. Contact administrator.')
      } else {
        setError('Server error. Please try again.')
      }
    }

    setLoading(false)
  }

  // ── Handle Enter key ────────────────────────────────────────────────────────
  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleLogin()
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#F4F6F9]
                    flex items-center justify-center px-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 w-full max-w-md">

        {/* ── Header ─────────────────────────────────────────────────────── */}
        <div className="text-center mb-8">
          <div className="text-5xl mb-3">🌿</div>
          <h1 className="text-2xl font-bold text-[#1F3864]">
            Latex VFA Dashboard
          </h1>
          <p className="text-gray-500 text-sm mt-1">
            Lalan Rubbers (Pvt) Ltd
          </p>
          <div className="flex justify-center gap-3 mt-3">
            <span className="text-xs bg-green-100 text-green-700
                             px-2 py-1 rounded-full">
              {getGradeIcon('A')} Grade A
            </span>
            <span className="text-xs bg-yellow-100 text-yellow-700
                             px-2 py-1 rounded-full">
              {getGradeIcon('B')} Grade B
            </span>
            <span className="text-xs bg-red-100 text-red-700
                             px-2 py-1 rounded-full">
              {getGradeIcon('C')} Grade C
            </span>
          </div>
        </div>

        {/* ── Form ───────────────────────────────────────────────────────── */}
        <div className="space-y-4">

          {/* Email */}
          <div>
            <label className="block text-sm font-medium
                               text-gray-700 mb-1">
              Email
            </label>
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              onKeyDown={handleKeyDown}
              className="w-full px-4 py-2.5 border border-gray-300
                         rounded-lg text-sm focus:outline-none
                         focus:ring-2 focus:ring-[#1F3864]
                         focus:border-transparent transition"
            />
          </div>

          {/* Password */}
          <div>
            <label className="block text-sm font-medium
                               text-gray-700 mb-1">
              Password
            </label>
            <input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              onKeyDown={handleKeyDown}
              className="w-full px-4 py-2.5 border border-gray-300
                         rounded-lg text-sm focus:outline-none
                         focus:ring-2 focus:ring-[#1F3864]
                         focus:border-transparent transition"
            />
          </div>

          {/* Error message */}
          {error && (
            <div className="bg-red-50 border border-red-300
                            rounded-lg px-4 py-2.5">
              <p className="text-red-600 text-sm text-center">
                ⚠️ {error}
              </p>
            </div>
          )}

          {/* Login button */}
          <button
            onClick={handleLogin}
            disabled={loading}
            className="w-full bg-[#1F3864] text-white py-2.5
                       rounded-lg font-medium text-sm
                       hover:bg-[#162a4a] active:bg-[#0f1e35]
                       transition disabled:opacity-50
                       disabled:cursor-not-allowed mt-2"
          >
            {loading
              ? <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4 text-white"
                       fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12"
                            r="10" stroke="currentColor" strokeWidth="4"/>
                    <path className="opacity-75" fill="currentColor"
                          d="M4 12a8 8 0 018-8v8z"/>
                  </svg>
                  Logging in...
                </span>
              : 'Login'
            }
          </button>
        </div>

        {/* ── Role info ──────────────────────────────────────────────────── */}
        <div className="mt-6 p-3 bg-[#F4F6F9] rounded-lg">
          <p className="text-xs text-gray-500 text-center font-medium mb-2">
            Access Levels
          </p>
          <div className="space-y-1 text-xs text-gray-500">
            <div className="flex justify-between">
              <span>🏭 Factory Manager</span>
              <span>All views</span>
            </div>
            <div className="flex justify-between">
              <span>🔬 QA Officer</span>
              <span>Alerts + Summary</span>
            </div>
            <div className="flex justify-between">
              <span>⚙️ Admin</span>
              <span>Full access</span>
            </div>
          </div>
        </div>

        {/* ── Footer ─────────────────────────────────────────────────────── */}
        <p className="text-center text-xs text-gray-400 mt-5">
          R26-IT-120 · SLIIT · 2026
        </p>

      </div>
    </div>
  )
}

export default Login