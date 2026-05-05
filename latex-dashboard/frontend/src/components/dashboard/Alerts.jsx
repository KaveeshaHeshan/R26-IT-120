// src/components/dashboard/Alerts.jsx

import { useState }                         from 'react'
import useAlerts                            from '../../hooks/useAlerts'
import { getGradeColor, getGradeBadgeColor,
         getGradeIcon }                     from '../../utils/gradeHelper'
import { formatDateTime, timeAgo }          from '../../utils/dateHelper'

const Alerts = () => {

  const [filterSeverity, setFilterSeverity] = useState('')
  const [filterFarmer,   setFilterFarmer]   = useState('')
  const [filterDate,     setFilterDate]     = useState('')

  const {
    alerts,
    unreadCount,
    loading,
    error,
    latestAlert,
    alertStats,
    markAsRead,
    markAllAsRead,
    filterBySeverity,
    filterByFarmer,
    filterByDate,
    getSeverityColor,
    getSeverityLabel,
  } = useAlerts(100)

  // ── Apply filters ───────────────────────────────────────────────────────────
  let filtered = alerts
  if (filterSeverity) filtered = filterBySeverity(filterSeverity)
  if (filterFarmer)   filtered = filtered.filter(a =>
    a.farmer_id.toLowerCase().includes(filterFarmer.toLowerCase()))
  if (filterDate)     filtered = filterByDate(filterDate)

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">

      {/* ── Stats Row ─────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        {[
          { label: 'Total Alerts',  value: alertStats.total,
            icon: '🔔', bg: 'bg-gray-50',    color: 'text-[#1F3864]' },
          { label: 'Unread',        value: alertStats.unread,
            icon: '📬', bg: 'bg-blue-50',    color: 'text-blue-700'  },
          { label: 'Critical',      value: alertStats.critical,
            icon: '🔴', bg: 'bg-red-50',     color: 'text-red-700'   },
          { label: 'High',          value: alertStats.high,
            icon: '🟠', bg: 'bg-orange-50',  color: 'text-orange-700'},
          { label: 'Today',         value: alertStats.today,
            icon: '📅', bg: 'bg-yellow-50',  color: 'text-yellow-700'},
        ].map((s, i) => (
          <div key={i}
            className={`${s.bg} rounded-xl p-4 border
                         border-gray-100 shadow-sm`}>
            <div className="flex items-center justify-between mb-1">
              <span className="text-gray-500 text-xs font-medium">
                {s.label}
              </span>
              <span className="text-base">{s.icon}</span>
            </div>
            <p className={`text-2xl font-bold ${s.color}`}>
              {s.value}
            </p>
          </div>
        ))}
      </div>

      {/* ── Latest Alert Banner ───────────────────────────────────────────── */}
      {latestAlert && (
        <div className="bg-red-600 rounded-xl p-4
                        flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 bg-white rounded-full animate-pulse" />
            <div>
              <p className="text-white font-bold text-sm">
                ⚠️ Latest Grade C Alert
              </p>
              <p className="text-red-200 text-xs mt-0.5">
                Farmer: {latestAlert.farmer_id} ·
                VFA: {latestAlert.vfa?.toFixed(4)} ·
                {timeAgo(latestAlert.timestamp)}
              </p>
            </div>
          </div>
          <span className="bg-white text-red-600 text-xs
                           font-bold px-3 py-1.5 rounded-lg">
            {latestAlert.severity?.toUpperCase()}
          </span>
        </div>
      )}

      {/* ── Filters + Actions ─────────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm p-4
                      border border-gray-100">
        <div className="flex flex-col md:flex-row gap-3
                        items-start md:items-center justify-between">

          {/* Filters */}
          <div className="flex flex-wrap gap-3">

            {/* Severity filter */}
            <select
              value={filterSeverity}
              onChange={e => setFilterSeverity(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg
                         text-xs focus:outline-none
                         focus:ring-2 focus:ring-[#1F3864] bg-white"
            >
              <option value="">All Severity</option>
              <option value="critical">🔴 Critical</option>
              <option value="high">🟠 High</option>
              <option value="medium">🟡 Medium</option>
            </select>

            {/* Farmer filter */}
            <input
              type="text"
              placeholder="Filter by Farmer ID"
              value={filterFarmer}
              onChange={e => setFilterFarmer(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg
                         text-xs focus:outline-none
                         focus:ring-2 focus:ring-[#1F3864] w-40"
            />

            {/* Date filter */}
            <input
              type="date"
              value={filterDate}
              onChange={e => setFilterDate(e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-lg
                         text-xs focus:outline-none
                         focus:ring-2 focus:ring-[#1F3864]"
            />

            {/* Clear filters */}
            {(filterSeverity || filterFarmer || filterDate) && (
              <button
                onClick={() => {
                  setFilterSeverity('')
                  setFilterFarmer('')
                  setFilterDate('')
                }}
                className="px-3 py-2 bg-gray-100 text-gray-600
                           rounded-lg text-xs hover:bg-gray-200 transition"
              >
                Clear
              </button>
            )}
          </div>

          {/* Mark all read */}
          {unreadCount > 0 && (
            <button
              onClick={markAllAsRead}
              className="px-4 py-2 bg-[#1F3864] text-white
                         rounded-lg text-xs font-medium
                         hover:bg-[#162a4a] transition whitespace-nowrap"
            >
              ✓ Mark All Read ({unreadCount})
            </button>
          )}
        </div>

        {/* Result count */}
        <p className="text-gray-400 text-xs mt-3">
          Showing {filtered.length} of {alerts.length} alerts
        </p>
      </div>

      {/* ── Loading ───────────────────────────────────────────────────────── */}
      {loading && (
        <div className="flex items-center justify-center min-h-[30vh]">
          <div className="w-10 h-10 border-4 border-[#1F3864]
                          border-t-transparent rounded-full animate-spin" />
        </div>
      )}

      {/* ── Error ─────────────────────────────────────────────────────────── */}
      {error && (
        <div className="bg-red-50 border border-red-200
                        rounded-xl p-4 text-center">
          <p className="text-red-600 text-sm">{error}</p>
        </div>
      )}

      {/* ── No Alerts ─────────────────────────────────────────────────────── */}
      {!loading && filtered.length === 0 && (
        <div className="flex flex-col items-center justify-center
                        min-h-[30vh] text-center">
          <div className="text-6xl mb-4">✅</div>
          <h3 className="text-xl font-bold text-[#1F3864] mb-2">
            No Alerts
          </h3>
          <p className="text-gray-500 text-sm">
            No Grade C detections found
          </p>
        </div>
      )}

      {/* ── Alerts List ───────────────────────────────────────────────────── */}
      {!loading && filtered.length > 0 && (
        <div className="space-y-3">
          {filtered.map((alert, i) => (
            <div
              key={alert.id}
              className={`bg-white rounded-xl shadow-sm p-4
                          border-l-4 transition
                          ${alert.read
                            ? 'border-gray-200 opacity-75'
                            : 'border-red-600'
                          }`}
            >
              <div className="flex items-start
                              justify-between gap-4">

                {/* Left content */}
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">

                    {/* Unread dot */}
                    {!alert.read && (
                      <div className="w-2 h-2 bg-red-600
                                      rounded-full flex-shrink-0" />
                    )}

                    {/* Severity badge */}
                    <span
                      className="text-xs font-bold px-2 py-0.5 rounded-full"
                      style={{
                        backgroundColor: getSeverityColor(alert.severity) + '20',
                        color: getSeverityColor(alert.severity),
                      }}
                    >
                      {getSeverityLabel(alert.severity)}
                    </span>

                    {/* Grade badge */}
                    <span className={`text-xs font-bold px-2 py-0.5
                                      rounded-lg
                                      ${getGradeBadgeColor(alert.grade)}`}>
                      {getGradeIcon(alert.grade)} Grade {alert.grade}
                    </span>

                    {/* Time ago */}
                    <span className="text-gray-400 text-xs ml-auto">
                      {timeAgo(alert.timestamp)}
                    </span>
                  </div>

                  {/* VFA + details */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                    <div>
                      <p className="text-gray-400 text-xs">VFA Value</p>
                      <p className="font-bold text-lg"
                        style={{ color: getGradeColor(alert.grade) }}>
                        {alert.vfa?.toFixed(4)}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-xs">Farmer ID</p>
                      <p className="font-semibold text-sm text-[#1F3864]">
                        {alert.farmer_id || '--'}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-xs">Device ID</p>
                      <p className="font-semibold text-sm text-gray-600">
                        {alert.device_id || '--'}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-xs">Date & Time</p>
                      <p className="font-semibold text-xs text-gray-600">
                        {formatDateTime(alert.timestamp)}
                      </p>
                    </div>
                  </div>

                  {/* Sensor readings */}
                  {(alert.pH || alert.turbidity || alert.temperature) && (
                    <div className="flex gap-4 mt-2 pt-2
                                    border-t border-gray-100">
                      <span className="text-xs text-gray-500">
                        pH: <b>{alert.pH?.toFixed(2)}</b>
                      </span>
                      <span className="text-xs text-gray-500">
                        Turbidity: <b>{alert.turbidity?.toFixed(1)} NTU</b>
                      </span>
                      <span className="text-xs text-gray-500">
                        Temp: <b>{alert.temperature?.toFixed(1)}°C</b>
                      </span>
                    </div>
                  )}
                </div>

                {/* Mark read button */}
                {!alert.read && (
                  <button
                    onClick={() => markAsRead(alert.id)}
                    className="flex-shrink-0 px-3 py-1.5
                               bg-gray-100 text-gray-600 text-xs
                               rounded-lg hover:bg-gray-200 transition"
                  >
                    Mark Read
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

    </div>
  )
}

export default Alerts