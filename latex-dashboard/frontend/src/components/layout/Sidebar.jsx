// src/components/layout/Sidebar.jsx

import { useState, useEffect } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { db } from '../../firebase/config'
import {
  ref,
  onValue,
  query,
  orderByChild,
  limitToLast
} from 'firebase/database'
import { getRoleLabel }                              from '../../constants/roles'
import { getGradeColor, getGradeBadgeColor,
         getGradeIcon }                              from '../../utils/gradeHelper'
import { formatShortTime }                           from '../../utils/dateHelper'

const Sidebar = () => {

  const [unreadCount, setUnreadCount] = useState(0)
  const [latestVFA,   setLatestVFA]   = useState(null)
  const [collapsed,   setCollapsed]   = useState(false)

  const location = useLocation()
  const navigate = useNavigate()

  const role   = localStorage.getItem('role')
  const userId = localStorage.getItem('user_id')
  const name   = localStorage.getItem('name')

  // ── Fetch latest VFA ────────────────────────────────────────────────────────
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp'),
      limitToLast(1)
    )
    const unsub = onValue(q, (snapshot) => {
      const data = snapshot.val()
      if (data) {
        setLatestVFA(Object.values(data)[0])
      }
    })
    return () => unsub()
  }, [])

  // ── Fetch unread alerts ─────────────────────────────────────────────────────
  useEffect(() => {
    const unsub = onValue(ref(db, 'alerts'), (snapshot) => {
      const data = snapshot.val()
      if (data) {
        setUnreadCount(
          Object.values(data).filter(a => !a.read).length
        )
      }
    })
    return () => unsub()
  }, [])

  // ── Logout ──────────────────────────────────────────────────────────────────
  const handleLogout = () => {
    localStorage.clear()
    navigate('/login')
  }

  // ── Active check ────────────────────────────────────────────────────────────
  const isActive = (path) => location.pathname === path

  // ── Nav items ───────────────────────────────────────────────────────────────
  const navItems = [
    {
      path:  '/',
      icon:  '📡',
      label: 'Live Monitor',
      desc:  'Real-time VFA readings',
      roles: ['manager', 'admin'],
      badge: false,
    },
    {
      path:  '/farmer',
      icon:  '👨‍🌾',
      label: 'Farmer Profile',
      desc:  'VFA history per farmer',
      roles: ['manager', 'admin'],
      badge: false,
    },
    {
      path:  '/alerts',
      icon:  '🔔',
      label: 'Alerts',
      desc:  'Grade C detections',
      roles: ['manager', 'qa_officer', 'admin'],
      badge: true,
    },
    {
      path:  '/summary',
      icon:  '📊',
      label: 'Daily Summary',
      desc:  'Factory statistics',
      roles: ['manager', 'qa_officer', 'admin'],
      badge: false,
    },
  ]

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <aside
      className={`
        bg-[#1F3864] min-h-screen flex flex-col
        transition-all duration-300 shadow-xl flex-shrink-0
        ${collapsed ? 'w-16' : 'w-64'}
      `}
    >

      {/* ── Logo + Collapse ────────────────────────────────────────────────── */}
      <div className="flex items-center justify-between
                      px-4 py-4 border-b border-[#2a4a7a]">
        {!collapsed && (
          <div>
            <p className="text-white font-bold text-sm leading-tight">
              🌿 Latex VFA
            </p>
            <p className="text-[#C9A84C] text-xs">
              R26-IT-120 · SLIIT
            </p>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="text-gray-400 hover:text-white
                     transition-colors text-base ml-auto"
        >
          {collapsed ? '▶' : '◀'}
        </button>
      </div>

      {/* ── Live VFA Card ───────────────────────────────────────────────────── */}
      {latestVFA && !collapsed && (
        <div className="mx-3 mt-4 p-3 bg-[#162a4a]
                        rounded-xl border border-[#2a4a7a]">
          <div className="flex items-center gap-1.5 mb-1">
            <div
              className="w-1.5 h-1.5 rounded-full animate-pulse"
              style={{ backgroundColor: getGradeColor(latestVFA.grade) }}
            />
            <p className="text-gray-400 text-xs">
              Live VFA
            </p>
          </div>
          <div className="flex items-center justify-between">
            <span
              className="text-2xl font-bold"
              style={{ color: getGradeColor(latestVFA.grade) }}
            >
              {parseFloat(latestVFA.vfa).toFixed(4)}
            </span>
            <span
              className={`text-xs font-bold px-2 py-1
                          rounded-lg ${getGradeBadgeColor(latestVFA.grade)}`}
            >
              {getGradeIcon(latestVFA.grade)} {latestVFA.grade}
            </span>
          </div>
          <p className="text-gray-500 text-xs mt-1">
            {latestVFA.farmer_id} ·{' '}
            {formatShortTime(latestVFA.timestamp)}
          </p>
        </div>
      )}

      {/* Collapsed VFA dot */}
      {latestVFA && collapsed && (
        <div className="flex justify-center mt-4">
          <div
            className="w-3 h-3 rounded-full animate-pulse"
            style={{ backgroundColor: getGradeColor(latestVFA.grade) }}
          />
        </div>
      )}

      {/* ── Nav Links ───────────────────────────────────────────────────────── */}
      <nav className="flex-1 px-2 py-4 space-y-1">
        {navItems
          .filter(item => item.roles.includes(role))
          .map(item => (
            <Link
              key={item.path}
              to={item.path}
              className={`
                flex items-center gap-3 px-3 py-2.5
                rounded-xl transition-all duration-200 group relative
                ${isActive(item.path)
                  ? 'bg-[#C9A84C] text-[#1F3864]'
                  : 'text-gray-300 hover:bg-[#162a4a] hover:text-white'
                }
              `}
            >
              {/* Icon */}
              <span className="text-lg flex-shrink-0">
                {item.icon}
              </span>

              {/* Label + desc */}
              {!collapsed && (
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium truncate">
                      {item.label}
                    </span>
                    {item.badge && unreadCount > 0 && (
                      <span className="bg-red-600 text-white
                                       text-xs rounded-full px-1.5
                                       py-0.5 leading-none font-bold">
                        {unreadCount > 9 ? '9+' : unreadCount}
                      </span>
                    )}
                  </div>
                  <p className={`
                    text-xs truncate mt-0.5
                    ${isActive(item.path)
                      ? 'text-[#1F3864] opacity-70'
                      : 'text-gray-500 group-hover:text-gray-400'
                    }
                  `}>
                    {item.desc}
                  </p>
                </div>
              )}

              {/* Collapsed badge */}
              {collapsed && item.badge && unreadCount > 0 && (
                <span className="absolute top-1 right-1
                                 bg-red-600 text-white text-xs
                                 rounded-full w-4 h-4 flex
                                 items-center justify-center
                                 leading-none font-bold">
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}

              {/* Collapsed tooltip */}
              {collapsed && (
                <div className="absolute left-14 bg-[#162a4a]
                                text-white text-xs px-2 py-1
                                rounded-lg whitespace-nowrap
                                opacity-0 group-hover:opacity-100
                                transition-opacity pointer-events-none
                                z-50 shadow-lg">
                  {item.label}
                </div>
              )}
            </Link>
          ))
        }
      </nav>

      {/* ── Divider ─────────────────────────────────────────────────────────── */}
      <div className="border-t border-[#2a4a7a] mx-3" />

      {/* ── User Info + Logout ──────────────────────────────────────────────── */}
      <div className="p-3 space-y-3">

        {/* User info */}
        {!collapsed ? (
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-[#C9A84C] rounded-full
                            flex items-center justify-center
                            text-[#1F3864] font-bold text-sm
                            flex-shrink-0">
              {userId?.charAt(0)?.toUpperCase() || 'U'}
            </div>
            <div className="min-w-0">
              <p className="text-white text-xs font-semibold truncate">
                {name || userId}
              </p>
              <p className="text-[#C9A84C] text-xs truncate">
                {getRoleLabel(role)}
              </p>
            </div>
          </div>
        ) : (
          <div className="flex justify-center">
            <div className="w-9 h-9 bg-[#C9A84C] rounded-full
                            flex items-center justify-center
                            text-[#1F3864] font-bold text-sm">
              {userId?.charAt(0)?.toUpperCase() || 'U'}
            </div>
          </div>
        )}

        {/* Logout */}
        <button
          onClick={handleLogout}
          className="w-full bg-red-600 text-white text-xs
                     font-medium py-2 rounded-lg
                     hover:bg-red-700 active:bg-red-800
                     transition flex items-center
                     justify-center gap-2"
        >
          <span>🚪</span>
          {!collapsed && <span>Logout</span>}
        </button>

      </div>
    </aside>
  )
}

export default Sidebar