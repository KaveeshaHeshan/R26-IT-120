// src/components/auth/Login.jsx

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { auth, db } from '../../firebase/config'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { ref, get } from 'firebase/database'

const Login = () => {
  const [email, setEmail]       = useState('')
  const [password, setPassword] = useState('')
  const [error, setError]       = useState('')
  const [loading, setLoading]   = useState(false)
  const navigate = useNavigate()

  const handleLogin = async () => {
    if (!email || !password) {
      setError('Please enter your email and password.')
      return
    }
    setLoading(true)
    setError('')
    try {
      const cred = await signInWithEmailAndPassword(auth, email, password)
      const uid = cred.user.uid
      const snap = await get(ref(db, `roles/${uid}`))
      const roleData = snap.val()
      if (!roleData) {
        setError('Identity not registered. Contact Hub.')
        setLoading(false)
        return
      }
      const token = await cred.user.getIdToken()
      localStorage.setItem('token', token)
      localStorage.setItem('uid', uid)
      localStorage.setItem('role', roleData.role)
      localStorage.setItem('user_id', roleData.user_id)
      localStorage.setItem('name', roleData.name)
      if (['manager', 'qa_officer', 'admin'].includes(roleData.role)) {
        navigate('/summary')
      } else {
        navigate('/unauthorized')
      }
    } catch (err) {
      switch (err.code) {
        case 'auth/invalid-credential':
        case 'auth/wrong-password':
        case 'auth/user-not-found':
          setError('Invalid email or password.')
          break
        case 'auth/too-many-requests':
          setError('Too many attempts. Please try again later.')
          break
        default:
          setError('Login failed. Please try again.')
      }
    }
    setLoading(false)
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleLogin()
  }

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="bg-white rounded-2xl shadow-[0_8px_40px_rgba(0,0,0,0.12)] overflow-hidden border border-gray-100">

        {/* Card Header */}
        <div className="bg-[#0a3622] px-8 py-5 flex items-center gap-3">
          <span className="text-[#c9a84c] text-lg font-black uppercase tracking-widest">LATEX GUARD</span>
          <span className="text-white text-lg font-black uppercase tracking-widest">PORTAL LOGIN</span>
        </div>
        {/* Gold accent divider */}
        <div className="h-0.5 bg-[#c9a84c] w-full" />

        {/* Card Body */}
        <div className="px-8 py-8 space-y-5">

          {/* Email */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut', delay: 0.1 }}
          >
            <input
              id="login-email"
              type="email"
              placeholder="EMAIL / USERNAME"
              value={email}
              onChange={e => setEmail(e.target.value)}
              onKeyDown={handleKeyDown}
              className="block w-full px-5 py-3.5 text-sm font-semibold tracking-wide placeholder:text-gray-400 placeholder:uppercase placeholder:tracking-wider bg-white border-2 border-gray-200 rounded-xl focus:outline-none focus:border-[#0a3622] transition-all"
            />
          </motion.div>

          {/* Password */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut', delay: 0.2 }}
          >
            <input
              id="login-password"
              type="password"
              placeholder="PASSWORD"
              value={password}
              onChange={e => setPassword(e.target.value)}
              onKeyDown={handleKeyDown}
              className="block w-full px-5 py-3.5 text-sm font-semibold tracking-wide placeholder:text-gray-400 placeholder:uppercase placeholder:tracking-wider bg-white border-2 border-gray-200 rounded-xl focus:outline-none focus:border-[#0a3622] transition-all"
            />
          </motion.div>

          {/* Error */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 flex items-center gap-2">
              <span className="text-red-500 text-sm">⚠️</span>
              <p className="text-xs font-semibold text-red-600">{error}</p>
            </div>
          )}

          {/* Login Button */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, ease: 'easeOut', delay: 0.3 }}
          >
            <button
              id="login-submit"
              onClick={handleLogin}
              disabled={loading}
              className="w-full bg-[#0a3622] hover:bg-[#072618] text-white py-3.5 rounded-xl text-sm font-black uppercase tracking-widest transition-all shadow-md hover:shadow-lg disabled:opacity-60 active:scale-[0.98]"
            >
              {loading ? (
                <div className="flex items-center justify-center gap-2">
                  <div className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
                  <span>Logging in...</span>
                </div>
              ) : 'LOGIN'}
            </button>
          </motion.div>

          {/* Links */}
          <div className="pt-2 border-t border-gray-100">
            <div className="text-center space-y-2 pt-2">
              <p className="text-sm text-gray-500 hover:text-gray-700 cursor-pointer transition-colors">Forgot Password?</p>
              <p className="text-sm text-gray-500 hover:text-gray-700 cursor-pointer transition-colors">Request Access (Contact Us)</p>
              <p className="text-sm font-black text-gray-800 hover:text-[#0a3622] cursor-pointer transition-colors tracking-wider uppercase pt-1">Learn More</p>
            </div>
          </div>

        </div>
      </div>
    </div>
  )
}

export default Login
