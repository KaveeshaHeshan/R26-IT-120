// src/components/layout/Navbar.jsx

import { useState, useEffect } from 'react'
import { Link, useNavigate, useLocation } from 'react-router-dom'
import { db } from '../../firebase/config'
import { ref, onValue, query, orderByChild, limitToLast } from 'firebase/database'
import { getGradeColor, getGradeIcon, getGradeBadgeColor } from '../../utils/gradeHelper'
import { getRoleLabel } from '../../constants/roles'
import { formatShortTime } from '../../utils/dateHelper'

const Navbar = () => {

  const [latestVFA,   setLatestVFA]   = useState(null)
  const [unreadCount, setUnreadCount] = useState(0)
  const [menuOpen,    setMenuOpen]    = useState(false)
  const navigate  = useNavigate()
  const location  = useLocation()

  const role   = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')
  const name   = localStorage.getItem('name')

  // ── Fetch latest VFA real-time ──────────────────────────────────────────────
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp'),
      limitToLast(1)
    )
    const unsub = onValue(q, (snapshot) => {
      const data = snapshot.val()
      if (data) {
        const latest = Object.values(data)[0]
        setLatestVFA(latest)
      }
    })
    return () => unsub()
  }, [])

  // ── Fetch unread alerts count ───────────────────────────────────────────────
  useEffect(() => {
    const alertsRef = ref(db, 'alerts')
    const unsub = onValue(alertsRef, (snapshot) => {
      const data = snapshot.val()
      if (data) {
        const unread = Object.values(data)
          .filter(a => !a.read).length
        setUnreadCount(unread)
      }
    })
    return () => unsub()
  }, [])

  // ── Logout ──────────────────────────────────────────────────────────────────
  const handleLogout = () => {
    localStorage.clear()
    navigate('/login')
  }

  // ── Active link check ───────────────────────────────────────────────────────
  const isActive = (path) => location.pathname === path

  const activeCls = 'text-[#C9A84C] border-b-2 border-[#C9A84C] pb-1'
  const inactiveCls = 'text-gray-300 hover:text-[#C9A84C] transition pb-1'

  // ── Nav links per role ──────────────────────────────────────────────────────
  const navLinks = [
    {
      path:  '/',
      label: 'Live Monitor',
      roles: ['manager', 'admin'],
    },
    {
      path:  '/farmer',
      label: 'Farmer Profile',
      roles: ['manager', 'admin'],
    },
    {
      path:  '/alerts',
      label: 'Alerts',
      roles: ['manager', 'qa_officer', 'admin'],
      badge: true,
    },
    {
      path:  '/summary',
      label: 'Daily Summary',
      roles: ['manager', 'qa_officer', 'admin'],
    },
  ]

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <nav className="bg-[#1F3864] shadow-lg sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 py-3">
        <div className="flex items-center justify-between">

          {/* ── Logo ─────────────────────────────────────────────────────── */}
          <div className="flex items-center gap-3">
            <span className="text-2xl">🌿</span>
            <div>
              <p className="text-white font-bold text-base leading-tight">
                Latex VFA Dashboard
              </p>
              <p className="text-[#C9A84C] text-xs">
                Lalan Rubbers (Pvt) Ltd
              </p>
            </div>
          </div>

          {/* ── Desktop Nav Links ─────────────────────────────────────────── */}
          <div className="hidden md:flex items-center gap-6 text-sm font-medium">
            {navLinks
              .filter(link => link.roles.includes(role))
              .map(link => (
                <Link
                  key={link.path}
                  to={link.path}
                  className={isActive(link.path) ? activeCls : inactiveCls}
                >
                  <span className="flex items-center gap-1">
                    {link.label}
                    {link.badge && unreadCount > 0 && (
                      <span className="bg-red-600 text-white text-xs
                                       rounded-full px-1.5 py-0.5 leading-none">
                        {unreadCount}
                      </span>
                    )}
                  </span>
                </Link>
              ))
            }
          </div>

          {/* ── Right Section ─────────────────────────────────────────────── */}
          <div className="flex items-center gap-3">

            {/* Live VFA indicator */}
            {latestVFA && (
              <div className="hidden lg:flex items-center gap-2
                              bg-[#162a4a] px-3 py-1.5 rounded-lg">
                <div
                  className="w-2 h-2 rounded-full animate-pulse"
                  style={{ backgroundColor: getGradeColor(latestVFA.grade) }}
                />
                <span className="text-white text-xs font-medium">
                  VFA: {parseFloat(latestVFA.vfa).toFixed(4)}
                </span>
                <span
                  className={`text-xs font-bold px-1.5 py-0.5 rounded
                              ${getGradeBadgeColor(latestVFA.grade)}`}
                >
                  {getGradeIcon(latestVFA.grade)} {latestVFA.grade}
                </span>
                <span className="text-gray-400 text-xs">
                  {formatShortTime(latestVFA.timestamp)}
                </span>
              </div>
            )}

            {/* Alert bell */}
            <Link to="/alerts"
              className="relative text-gray-300
                         hover:text-[#C9A84C] transition">
              <span className="text-xl">🔔</span>
              {unreadCount > 0 && (
                <span className="absolute -top-1 -right-1
                                 bg-red-600 text-white text-xs
                                 rounded-full w-4 h-4 flex
                                 items-center justify-center
                                 leading-none font-bold">
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </Link>

            {/* User info */}
            <div className="hidden md:flex items-center gap-2
                            bg-[#162a4a] px-3 py-1.5 rounded-lg">
              <span className="text-white text-xs font-medium">
                {userId}
              </span>
              <span className="text-[#C9A84C] text-xs">
                {getRoleLabel(role)}
              </span>
            </div>

            {/* Logout */}
            <button
              onClick={handleLogout}
              className="bg-red-600 text-white text-xs font-medium
                         px-3 py-1.5 rounded-lg hover:bg-red-700
                         active:bg-red-800 transition"
            >
              Logout
            </button>

            {/* Mobile menu button */}
            <button
              onClick={() => setMenuOpen(!menuOpen)}
              className="md:hidden text-white text-xl"
            >
              {menuOpen ? '✕' : '☰'}
            </button>

          </div>
        </div>

        {/* ── Mobile Menu ──────────────────────────────────────────────────── */}
        {menuOpen && (
          <div className="md:hidden mt-3 pb-3 border-t
                          border-[#2a4a7a] space-y-2 pt-3">

            {navLinks
              .filter(link => link.roles.includes(role))
              .map(link => (
                <Link
                  key={link.path}
                  to={link.path}
                  onClick={() => setMenuOpen(false)}
                  className={`flex items-center justify-between
                              px-2 py-2 rounded-lg text-sm
                              ${isActive(link.path)
                                ? 'bg-[#162a4a] text-[#C9A84C]'
                                : 'text-gray-300 hover:bg-[#162a4a]'
                              }`}
                >
                  <span>{link.label}</span>
                  {link.badge && unreadCount > 0 && (
                    <span className="bg-red-600 text-white text-xs
                                     rounded-full px-1.5 py-0.5">
                      {unreadCount}
                    </span>
                  )}
                </Link>
              ))
            }

            {/* Mobile VFA */}
            {latestVFA && (
              <div className="flex items-center gap-2 px-2 py-2
                              bg-[#162a4a] rounded-lg">
                <div
                  className="w-2 h-2 rounded-full animate-pulse"
                  style={{ backgroundColor: getGradeColor(latestVFA.grade) }}
                />
                <span className="text-white text-xs">
                  VFA: {parseFloat(latestVFA.vfa).toFixed(4)}
                </span>
                <span className={`text-xs font-bold px-1.5 py-0.5
                                  rounded ${getGradeBadgeColor(latestVFA.grade)}`}>
                  {latestVFA.grade}
                </span>
              </div>
            )}

          </div>
        )}
      </div>
    </nav>
  )
}

export default Navbar