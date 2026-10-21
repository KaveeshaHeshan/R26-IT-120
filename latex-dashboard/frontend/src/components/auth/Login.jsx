// src/components/auth/Login.jsx

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { LuMail, LuLock, LuEye, LuEyeOff, LuArrowRight, LuShieldCheck } from 'react-icons/lu'
import { auth, db } from '../../firebase/config'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { ref, get } from 'firebase/database'

const Login = () => {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
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
        setError('Identity not registered. Contact your administrator.')
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
        navigate('/overview')
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

  const fieldClass =
    'flex items-center gap-3 h-[54px] rounded-[14px] border border-[#DDE4D8] bg-white px-4 focus-within:border-brand-500 focus-within:ring-2 focus-within:ring-brand-500/20 transition'
  const inputClass =
    'flex-1 min-w-0 bg-transparent border-0 outline-none text-base font-medium text-[#11231A] placeholder:text-[#8FA093]'

  return (
    <div className="flex flex-col gap-5">
      <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4, delay: 0.05 }}>
        <label htmlFor="login-email" className="block text-sm font-semibold text-[#11231A] mb-1.5">
          Email
        </label>
        <div className={fieldClass}>
          <LuMail size={20} className="text-[#8FA093] shrink-0" />
          <input
            id="login-email"
            type="email"
            placeholder="name@company.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            onKeyDown={handleKeyDown}
            className={inputClass}
          />
        </div>
      </motion.div>

      <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4, delay: 0.1 }}>
        <label htmlFor="login-password" className="block text-sm font-semibold text-[#11231A] mb-1.5">
          Password
        </label>
        <div className={fieldClass}>
          <LuLock size={20} className="text-[#8FA093] shrink-0" />
          <input
            id="login-password"
            type={showPassword ? 'text' : 'password'}
            placeholder="Enter your password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onKeyDown={handleKeyDown}
            className={inputClass}
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            className="shrink-0 w-11 h-11 -mr-2 rounded-[10px] flex items-center justify-center text-[#8FA093] hover:bg-[#F7FAF4] transition-colors"
          >
            {showPassword ? <LuEyeOff size={20} /> : <LuEye size={20} />}
          </button>
        </div>
      </motion.div>

      {error && <p className="text-sm font-medium text-[#B42318]">{error}</p>}

      <button
        id="login-submit"
        onClick={handleLogin}
        disabled={loading}
        className="w-full h-14 rounded-[14px] bg-brand-600 text-white text-base font-bold flex items-center justify-center gap-2 transition disabled:opacity-60"
        style={{ boxShadow: '0 6px 16px rgba(19,138,67,0.28)' }}
      >
        {loading ? (
          'Signing in…'
        ) : (
          <>
            Sign in <LuArrowRight size={18} />
          </>
        )}
      </button>

      <div className="flex items-center gap-2 rounded-[14px] border border-[#DDE4D8] bg-white px-4 py-[14px] text-sm text-[#5A6B5F]">
        <LuShieldCheck size={18} className="text-[#5A6B5F] shrink-0" />
        Access is provisioned by your administrator.
      </div>
    </div>
  )
}

export default Login
