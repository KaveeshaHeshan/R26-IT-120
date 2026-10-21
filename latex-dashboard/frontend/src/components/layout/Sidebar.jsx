// src/components/layout/Sidebar.jsx

import { NavLink, useNavigate } from 'react-router-dom'
import { LuLayoutDashboard, LuSprout, LuShieldCheck, LuChartColumn } from 'react-icons/lu'
import { getRoleLabel, NAV_SECTIONS } from '../../constants/roles'
import BrandMark from '../ui/BrandMark'

// Icon lookup keyed by route path — keeps roles.js (and its consumers, e.g.
// Navbar's section lookup) untouched; this is purely a presentational map.
const NAV_ICONS = {
  '/overview': LuLayoutDashboard,
  '/farmers': LuSprout,
  '/supervisors': LuShieldCheck,
  '/quality': LuChartColumn,
}

const Sidebar = () => {
  const navigate = useNavigate()
  const role = localStorage.getItem('role')
  const name = localStorage.getItem('name') || ''

  const handleLogout = () => {
    localStorage.clear()
    navigate('/login')
  }

  const initials = name
    .split(' ')
    .map((n) => n[0])
    .filter(Boolean)
    .slice(0, 2)
    .join('')
    .toUpperCase()

  return (
    <aside className="flex-[1_1_240px] max-w-[260px] min-h-screen shrink-0 bg-forest-900 font-[Figtree] flex flex-col gap-7 px-[18px] pt-7 pb-5">
      {/* Brand */}
      <div className="shrink-0">
        <BrandMark variant="dark" size="md" />
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto flex flex-col">
        {NAV_SECTIONS.map((section, si) => {
          const items = section.items.filter((i) => i.roles.includes(role))
          if (items.length === 0) return null
          return (
            <div key={section.heading} className={si > 0 ? 'mt-[18px]' : ''}>
              <p className="text-[11px] font-bold uppercase tracking-[0.1em] text-[#8FB09A] px-[14px] pb-1.5">
                {section.heading}
              </p>
              <div className="flex flex-col gap-0.5">
                {items.map((item) => {
                  const Icon = NAV_ICONS[item.path]
                  return (
                    <NavLink
                      key={item.path}
                      to={item.path}
                      className={({ isActive }) =>
                        `flex items-center gap-3 px-[14px] py-[11px] rounded-xl text-[15px] transition-colors ${
                          isActive
                            ? 'bg-white/12 text-white font-semibold'
                            : 'text-[#CFE0D5] font-medium hover:bg-white/8'
                        }`
                      }
                    >
                      {({ isActive }) => (
                        <>
                          {Icon && <Icon size={18} className={`shrink-0 ${isActive ? 'text-glow' : ''}`} />}
                          {item.label}
                        </>
                      )}
                    </NavLink>
                  )
                })}
              </div>
            </div>
          )
        })}
      </nav>

      {/* Profile / logout */}
      <div className="mt-auto pt-6 shrink-0 flex flex-col gap-3">
        <div className="flex items-center gap-3 bg-white/7 rounded-2xl p-3">
          <div className="w-[38px] h-[38px] shrink-0 rounded-full bg-brand-500 text-forest-900 flex items-center justify-center text-sm font-bold">
            {initials || '·'}
          </div>
          <div className="min-w-0">
            <p className="text-sm font-semibold text-white truncate">{name || 'User'}</p>
            <p className="text-xs text-[#9DBBA8] truncate">{getRoleLabel(role)}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="w-full rounded-xl border border-white/20 bg-transparent px-3 py-[11px] text-sm font-semibold text-[#CFE0D5] hover:bg-white/8 transition-colors"
        >
          Sign out
        </button>
      </div>
    </aside>
  )
}

export default Sidebar
