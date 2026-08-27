// src/components/layout/Sidebar.jsx

import { Link, useLocation, useNavigate } from 'react-router-dom'
import { getRoleLabel } from '../../constants/roles'

const Sidebar = () => {
  const location = useLocation()
  const navigate = useNavigate()

  const role = localStorage.getItem('role')
  const name = localStorage.getItem('name')

  const handleLogout = () => {
    localStorage.clear()
    navigate('/login')
  }

  const isActive = (path) => location.pathname === path

  const navItems = [
    {
      path: '/summary',
      icon: "📊",
      label: 'Intelligence Summary',
      roles: ['manager', 'qa_officer', 'admin'],
    },
  ]

  return (
    <div className="w-80 min-h-screen bg-[#052c14] flex flex-col border-r border-emerald-900/50 shadow-[20px_0_50px_rgba(0,0,0,0.2)]">
      
      {/* ── Brand ────────────────────────────────────────────────────── */}
      <div className="p-10 pb-16">
        <div className="flex items-center gap-4 group">
          <div className="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center border border-white/5 shadow-xl group-hover:bg-emerald-500 transition-all duration-500 group-hover:rotate-12">
            <span className="text-2xl">🌿</span>
          </div>
          <div>
            <h2 className="text-white text-xl font-black tracking-tighter uppercase leading-none">
              LatexGuard
            </h2>
            <p className="text-emerald-500 text-[8px] font-black tracking-[0.4em] uppercase mt-2">
              Lattice Core
            </p>
          </div>
        </div>
      </div>

      {/* ── Nav ──────────────────────────────────────────────────────── */}
      <nav className="flex-1 px-6 space-y-4">
        <p className="text-white/20 text-[9px] font-black uppercase tracking-[0.3em] px-4 mb-6">Operations Terminal</p>
        {navItems
          .filter(item => item.roles.includes(role))
          .map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`flex items-center justify-between px-6 py-5 rounded-[1.25rem] transition-all duration-300 group
                        ${isActive(item.path) 
                          ? 'bg-white text-[#052c14] shadow-[0_10px_30px_rgba(0,0,0,0.2)] scale-[1.02]' 
                          : 'text-white/50 hover:bg-white/5 hover:text-white'}`}
            >
              <div className="flex items-center gap-5">
                <span className={`text-xl transition-transform group-hover:scale-110 duration-300 ${isActive(item.path) ? '' : 'filter grayscale opacity-50 group-hover:grayscale-0 group-hover:opacity-100'}`}>
                   {item.icon}
                </span>
                <span className={`text-[10px] font-black uppercase tracking-[0.2em] ${isActive(item.path) ? 'text-[#052c14]' : ''}`}>
                  {item.label}
                </span>
              </div>
            </Link>
          ))}
      </nav>

      {/* ── User Profile ─────────────────────────────────────────────── */}
      <div className="p-8 border-t border-white/5 bg-black/20">
        <div className="bg-white/5 rounded-[2rem] p-6 border border-white/5">
           <div className="flex items-center gap-4 mb-6">
              <div className="w-10 h-10 rounded-full bg-emerald-500 flex items-center justify-center text-white font-black text-xs shadow-lg">
                 {name?.split(' ').map(n=>n[0]).join('')}
              </div>
              <div className="overflow-hidden">
                 <p className="text-white text-[10px] font-black uppercase tracking-widest truncate">{name}</p>
                 <p className="text-emerald-500/60 text-[8px] font-black uppercase tracking-[0.2em] mt-1">{getRoleLabel(role)}</p>
              </div>
           </div>
           
           <button
             onClick={handleLogout}
             className="w-full py-4 rounded-xl border border-white/10 hover:border-red-500/50 hover:bg-red-500/10 text-white/30 hover:text-red-500 transition-all text-[9px] font-black uppercase tracking-[0.3em]"
           >
             Terminate Session
           </button>
        </div>
        
        <div className="mt-8 text-center px-4">
           <p className="text-white/10 text-[7px] font-black uppercase tracking-[0.4em]">
             System Node: R26-IT-120
           </p>
        </div>
      </div>

    </div>
  )
}

export default Sidebar
