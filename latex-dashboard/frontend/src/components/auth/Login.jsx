// src/components/auth/Login.jsx

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
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
      setError('Required: Email and Cipher.')
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

      if (['manager', 'admin'].includes(roleData.role)) {
        navigate('/')
      } else if (roleData.role === 'qa_officer') {
        navigate('/alerts')
      } else {
        navigate('/unauthorized')
      }
    } catch (err) {
      switch (err.code) {
        case 'auth/invalid-credential':
        case 'auth/wrong-password':
        case 'auth/user-not-found':
          setError('Verification failed. Invalid ID.')
          break
        case 'auth/too-many-requests':
          setError('Rate limit reached. Session throttled.')
          break
        default:
          setError('Terminal error. Sync failed.')
      }
    }

    setLoading(false)
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleLogin()
  }

  return (
    <div className="w-full max-w-sm mx-auto">
      <div className="overflow-hidden rounded-[3rem] border border-emerald-100 bg-white/90 shadow-[0_40px_100px_-20px_rgba(5,44,20,0.1)] backdrop-blur-2xl">
        <div className="border-b border-emerald-50 px-8 py-8">
          <div className="flex items-center gap-5">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-600 text-white shadow-lg shadow-emerald-600/20">
              <span className="text-xl">🌿</span>
            </div>
            <div>
              <p className="text-xl font-black tracking-tighter text-[#052c14] uppercase">LatexGuard</p>
              <p className="text-[9px] font-black uppercase tracking-[0.3em] text-emerald-600/60 mt-0.5">
                Secure Lattice Portal
              </p>
            </div>
          </div>
        </div>

        <div className="px-8 py-10">
          <div className="mb-8 space-y-3">
            <h2 className="text-2xl font-black tracking-[0.05em] text-[#052c14] uppercase">
              Identity Sync
            </h2>
            <p className="text-[11px] leading-relaxed font-bold uppercase tracking-widest text-[#052c14]/40">
              Inject credentials into the terminal to begin secure monitoring of VFA vectors.
            </p>
          </div>

          <div className="space-y-6">
            <div className="space-y-2">
              <label className="text-[9px] font-black uppercase tracking-[0.2em] text-[#052c14]/20 ml-2">Registry Email</label>
              <input
                type="email"
                placeholder="OPERATOR@SYSTEM.CORE"
                value={email}
                onChange={e => setEmail(e.target.value)}
                onKeyDown={handleKeyDown}
                className="block w-full px-5 py-4 text-[10px] font-black tracking-widest uppercase placeholder:text-[#052c14]/10 bg-emerald-50/50 border border-emerald-100 rounded-2xl focus:outline-none focus:ring-4 focus:ring-emerald-500/5 focus:border-emerald-500/50 transition-all shadow-inner"
              />
            </div>

            <div className="space-y-2">
              <label className="text-[9px] font-black uppercase tracking-[0.2em] text-[#052c14]/20 ml-2">Access Cipher</label>
              <input
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                onKeyDown={handleKeyDown}
                className="block w-full px-5 py-4 text-[10px] font-black tracking-[0.4em] bg-emerald-50/50 border border-emerald-100 rounded-2xl focus:outline-none focus:ring-4 focus:ring-emerald-500/5 focus:border-emerald-500/50 transition-all shadow-inner"
              />
            </div>

            {error && (
              <div className="bg-red-50 border border-red-100 rounded-xl p-3 flex items-center gap-3 animate-shake">
                <span className="text-red-500">⚠️</span>
                <p className="text-[9px] font-black uppercase tracking-widest text-red-600">
                  {error}
                </p>
              </div>
            )}

            <button
              onClick={handleLogin}
              disabled={loading}
              className="w-full relative group"
            >
              <div className="absolute -inset-1 bg-emerald-600 rounded-2xl blur opacity-20 group-hover:opacity-40 transition-opacity"></div>
              <div className="relative flex h-14 items-center justify-center rounded-2xl bg-emerald-600 text-white shadow-xl transition-all active:scale-[0.98] disabled:opacity-50 disabled:active:scale-100">
                {loading ? (
                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-white/20 border-t-white" />
                ) : (
                  <span className="text-[10px] font-black uppercase tracking-[0.3em]">
                    Initialize Session
                  </span>
                )}
              </div>
            </button>
          </div>
        </div>

        <div className="border-t border-emerald-50 bg-emerald-50/20 px-8 py-5 text-center">
          <p className="text-[8px] font-black uppercase tracking-[0.3em] text-[#052c14]/20">
            Node-to-Hub Encryption Level: Level 7 Active
          </p>
        </div>
      </div>
    </div>
  )
}

export default Login
