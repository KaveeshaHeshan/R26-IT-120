// src/components/auth/Login.jsx

import { useState }                     from 'react'
import { useNavigate }                  from 'react-router-dom'
import { auth, db }                     from '../../firebase/config'
import { signInWithEmailAndPassword }   from 'firebase/auth'
import { ref, get }                     from 'firebase/database'

const Login = () => {

  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const [error,    setError]    = useState('')
  const [loading,  setLoading]  = useState(false)
  const navigate = useNavigate()

  // ── useEffect REMOVE ✅ ──────────────────────────────────────────────────────
  // Already handled by App.jsx PublicOnlyRoute + LoginPage.jsx

  // ── Handle Login ────────────────────────────────────────────────────────────
  const handleLogin = async () => {
    if (!email || !password) {
      setError('Please enter email and password.')
      return
    }
    setLoading(true)
    setError('')

    try {
      const cred = await signInWithEmailAndPassword(
        auth, email, password
      )
      const uid = cred.user.uid

      const snap     = await get(ref(db, `roles/${uid}`))
      const roleData = snap.val()

      if (!roleData) {
        setError('Role not assigned. Contact admin.')
        setLoading(false)
        return
      }

      const token = await cred.user.getIdToken()
      localStorage.setItem('token',   token)
      localStorage.setItem('uid',     uid)
      localStorage.setItem('role',    roleData.role)
      localStorage.setItem('user_id', roleData.user_id)
      localStorage.setItem('name',    roleData.name)

      if (['manager','admin'].includes(roleData.role)) {
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
          setError('Invalid email or password.')
          break
        case 'auth/too-many-requests':
          setError('Too many attempts. Try again later.')
          break
        default:
          setError('Login failed. Try again.')
      }
    }
    setLoading(false)
  }

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') handleLogin()
  }

  return (
    <div className="w-full max-w-sm">
      <div className="bg-white/10 backdrop-blur-2xl rounded-[3rem]
                      shadow-[0_25px_50px_-12px_rgba(0,0,0,0.5)] p-10
                      border border-white/20 ring-1 ring-white/10">

        <div className="text-center mb-8">
          <div className="inline-block p-4 bg-white/10 rounded-3xl mb-4
                          border border-white/20 shadow-xl">
            <div className="text-5xl drop-shadow-lg">🌿</div>
          </div>
          <h1 className="text-4xl font-black text-white tracking-tight
                         leading-none drop-shadow-md uppercase">
            Latex VFA
          </h1>
          <p className="text-black font-black text-sm tracking-[0.4em]
                        uppercase mt-3 drop-shadow-sm">
            DASHBOARD PORTAL
          </p>
          <div className="flex justify-center gap-2 mt-6">
            <div className="px-3 py-1 bg-white/5 rounded-full
                            border border-white/10 flex items-center
                            gap-2 shadow-sm">
              <span className="w-2 h-2 bg-green-400 rounded-full
                               animate-pulse
                               shadow-[0_0_8px_rgba(74,222,128,0.8)]"/>
              <span className="text-xs font-black text-white/90
                               uppercase tracking-widest">
                Grade A Secured
              </span>
            </div>
          </div>
        </div>

        <div className="space-y-6">
          <div>
            <label className="block text-xs font-black text-white/60
                               hover:text-white uppercase tracking-widest
                               mb-2 ml-2 transition-colors">
              Identity Email
            </label>
            <input
              type="email"
              placeholder="user@lalanrubbers.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              onKeyDown={handleKeyDown}
              className="w-full px-6 py-4 bg-white/5 border border-white/10
                         rounded-2xl text-base font-bold text-white
                         placeholder-white/20 focus:outline-none
                         focus:ring-4 focus:ring-white/5
                         focus:bg-white/10 focus:border-white/30
                         transition-all shadow-inner"
            />
          </div>

          <div>
            <label className="block text-xs font-black text-white/60
                               hover:text-white uppercase tracking-widest
                               mb-2 ml-2 transition-colors">
              Security Key
            </label>
            <input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={e => setPassword(e.target.value)}
              onKeyDown={handleKeyDown}
              className="w-full px-6 py-4 bg-white/5 border border-white/10
                         rounded-2xl text-base font-bold text-white
                         placeholder-white/20 focus:outline-none
                         focus:ring-4 focus:ring-white/5
                         focus:bg-white/10 focus:border-white/30
                         transition-all shadow-inner"
            />
          </div>

          {error && (
            <div className="bg-red-500/20 backdrop-blur-md
                            border border-red-500/30 rounded-2xl
                            px-4 py-3">
              <p className="text-red-200 text-sm font-bold
                            flex items-center gap-2">
                <span>✕</span> {error}
              </p>
            </div>
          )}

          <button
            onClick={handleLogin}
            disabled={loading}
            className="w-full bg-white/10 hover:bg-white/20 text-white
                       py-5 rounded-2xl font-black text-base
                       border border-white/20
                       shadow-[0_20px_40px_-10px_rgba(0,0,0,0.3)]
                       active:scale-[0.98] hover:translate-y-[-2px]
                       transition-all disabled:opacity-50
                       disabled:cursor-not-allowed mt-4
                       tracking-[0.2em] backdrop-blur-md uppercase"
          >
            {loading ? 'AUTHENTICATING...' : 'SECURE LOGIN'}
          </button>
        </div>

        <div className="mt-10 pt-6 border-t border-white/10
                        grid grid-cols-3 gap-3">
          <div className="text-center group">
            <p className="text-[10px] font-black text-white/30
                          group-hover:text-white/60 uppercase
                          tracking-wider transition-colors">
              Manager
            </p>
            <div className="h-1 bg-white/5 rounded-full mt-2 overflow-hidden">
              <div className="h-full bg-green-400 w-full rounded-full
                              shadow-[0_0_5px_rgba(74,222,128,0.5)]"/>
            </div>
          </div>
          <div className="text-center group">
            <p className="text-[10px] font-black text-white/30
                          group-hover:text-white/60 uppercase
                          tracking-wider transition-colors">
              QA
            </p>
            <div className="h-1 bg-white/5 rounded-full mt-2 overflow-hidden">
              <div className="h-full bg-yellow-400 w-[70%] rounded-full
                              shadow-[0_0_5px_rgba(250,204,21,0.5)]"/>
            </div>
          </div>
          <div className="text-center group">
            <p className="text-[10px] font-black text-white/30
                          group-hover:text-white/60 uppercase
                          tracking-wider transition-colors">
              Admin
            </p>
            <div className="h-1 bg-white/5 rounded-full mt-2 overflow-hidden">
              <div className="h-full bg-blue-400 w-full rounded-full
                              shadow-[0_0_5px_rgba(96,165,250,0.5)]"/>
            </div>
          </div>
        </div>

        <p className="text-center text-xs text-white/20 mt-6">
          R26-IT-120 · SLIIT · 2026
        </p>
      </div>
    </div>
  )
}

export default Login