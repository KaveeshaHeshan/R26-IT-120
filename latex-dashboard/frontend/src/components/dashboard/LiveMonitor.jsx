// src/components/dashboard/LiveMonitor.jsx

import { useState, useEffect }              from 'react'
import { db }                               from '../../firebase/config'
import { ref, onValue, query,
         orderByChild, limitToLast }        from 'firebase/database'
import { LineChart, Line, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer,
         ReferenceLine }                    from 'recharts'
import { getGradeColor, getGradeBg,
         getGradeBadgeColor, getGradeIcon,
         getGradeLabel, getVFAStatus,
         getVFAStatusColor }                from '../../utils/gradeHelper'
import { formatShortTime, timeAgo }         from '../../utils/dateHelper'

const LiveMonitor = () => {

  const [latest,   setLatest]   = useState(null)
  const [history,  setHistory]  = useState([])
  const [loading,  setLoading]  = useState(true)
  const [error,    setError]    = useState(null)

  // ── Firebase real-time listener ─────────────────────────────────────────────
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp'),
      limitToLast(20)
    )

    const unsub = onValue(q, (snapshot) => {
      try {
        const data = snapshot.val()
        if (!data) {
          setLoading(false)
          return
        }

        const items = Object.entries(data)
          .map(([key, val]) => ({
            id:          key,
            vfa:         parseFloat(val.vfa)         || 0,
            grade:       val.grade                   || 'A',
            pH:          parseFloat(val.pH)          || 0,
            turbidity:   parseFloat(val.turbidity)   || 0,
            temperature: parseFloat(val.temperature) || 0,
            farmer_id:   val.farmer_id               || '',
            device_id:   val.device_id               || '',
            sample_id:   val.sample_id               || '',
            timestamp:   val.timestamp               || '',
            time:        val.timestamp?.slice(11,16) || '',
          }))
          .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp))

        setLatest(items[items.length - 1])
        setHistory(items)
        setLoading(false)
        setError(null)

      } catch (err) {
        setError('Failed to load data: ' + err.message)
        setLoading(false)
      }
    }, (err) => {
      setError('Firebase error: ' + err.message)
      setLoading(false)
    })

    return () => unsub()
  }, [])

  // ── Loading ─────────────────────────────────────────────────────────────────
  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center
                      min-h-[60vh] gap-4">
        <div className="w-12 h-12 border-4 border-[#1F3864]
                        border-t-transparent rounded-full animate-spin" />
        <p className="text-gray-500 text-sm">
          Connecting to IoT device...
        </p>
      </div>
    )
  }

  // ── Error ───────────────────────────────────────────────────────────────────
  if (error) {
    return (
      <div className="flex flex-col items-center justify-center
                      min-h-[60vh] text-center px-4">
        <div className="text-5xl mb-4">⚠️</div>
        <p className="text-red-600 font-medium">{error}</p>
        <p className="text-gray-400 text-sm mt-1">
          Check Firebase connection
        </p>
      </div>
    )
  }

  // ── No data ─────────────────────────────────────────────────────────────────
  if (!latest) {
    return (
      <div className="flex flex-col items-center justify-center
                      min-h-[60vh] text-center px-4">
        <div className="text-6xl mb-4">📡</div>
        <h3 className="text-xl font-bold text-[#1F3864] mb-2">
          Waiting for IoT Device
        </h3>
        <p className="text-gray-500 text-sm">
          Connect ESP32 device to start receiving VFA predictions
        </p>
      </div>
    )
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div className="space-y-6">

      {/* ── VFA + Grade Display ───────────────────────────────────────────── */}
      <div className={`border-4 rounded-2xl p-6 text-center
                       ${getGradeBg(latest.grade)}`}>
        <div className="flex items-center justify-center gap-3 mb-2">
          <div
            className="w-3 h-3 rounded-full animate-pulse"
            style={{ backgroundColor: getGradeColor(latest.grade) }}
          />
          <span className="text-gray-500 text-sm font-medium">
            Live Prediction
          </span>
          <span className="text-gray-400 text-xs">
            {timeAgo(latest.timestamp)}
          </span>
        </div>

        {/* VFA Value */}
        <div
          className="text-8xl font-bold mb-2 tracking-tight"
          style={{ color: getGradeColor(latest.grade) }}
        >
          {latest.vfa.toFixed(4)}
        </div>

        {/* Grade Badge */}
        <div className="flex items-center justify-center gap-3">
          <span
            className={`text-2xl font-bold px-6 py-2
                        rounded-xl ${getGradeBadgeColor(latest.grade)}`}
          >
            {getGradeIcon(latest.grade)} Grade {latest.grade}
          </span>
        </div>

        {/* VFA Status */}
        <p
          className="text-sm font-medium mt-3"
          style={{ color: getVFAStatusColor(latest.vfa) }}
        >
          {getVFAStatus(latest.vfa)}
        </p>

        {/* Grade Label */}
        <p className="text-gray-500 text-xs mt-1">
          {getGradeLabel(latest.grade)}
        </p>

        {/* Timestamp */}
        <p className="text-gray-400 text-xs mt-2">
          Last updated: {latest.timestamp?.slice(0,19)?.replace('T',' ')}
        </p>
      </div>

      {/* ── Sensor Readings ───────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">

        {/* pH */}
        <div className="bg-white rounded-xl shadow-sm p-5
                        border border-gray-100">
          <div className="flex items-center justify-between mb-3">
            <span className="text-gray-500 text-sm font-medium">
              pH Level
            </span>
            <span className="text-blue-500 text-lg">🧪</span>
          </div>
          <p className="text-4xl font-bold text-[#1F3864]">
            {latest.pH.toFixed(2)}
          </p>
          <p className="text-gray-400 text-xs mt-1">
            Normal range: 6.0 — 7.5
          </p>
          <div className="mt-3 bg-gray-100 rounded-full h-1.5">
            <div
              className="bg-blue-500 h-1.5 rounded-full transition-all"
              style={{ width: `${(latest.pH / 14) * 100}%` }}
            />
          </div>
        </div>

        {/* Turbidity */}
        <div className="bg-white rounded-xl shadow-sm p-5
                        border border-gray-100">
          <div className="flex items-center justify-between mb-3">
            <span className="text-gray-500 text-sm font-medium">
              Turbidity
            </span>
            <span className="text-green-500 text-lg">💧</span>
          </div>
          <p className="text-4xl font-bold text-[#1F3864]">
            {latest.turbidity.toFixed(1)}
          </p>
          <p className="text-gray-400 text-xs mt-1">
            NTU — Normal: 10 — 80
          </p>
          <div className="mt-3 bg-gray-100 rounded-full h-1.5">
            <div
              className="bg-green-500 h-1.5 rounded-full transition-all"
              style={{ width: `${Math.min((latest.turbidity / 200) * 100, 100)}%` }}
            />
          </div>
        </div>

        {/* Temperature */}
        <div className="bg-white rounded-xl shadow-sm p-5
                        border border-gray-100">
          <div className="flex items-center justify-between mb-3">
            <span className="text-gray-500 text-sm font-medium">
              Temperature
            </span>
            <span className="text-orange-500 text-lg">🌡️</span>
          </div>
          <p className="text-4xl font-bold text-[#1F3864]">
            {latest.temperature.toFixed(1)}°C
          </p>
          <p className="text-gray-400 text-xs mt-1">
            Field range: 26 — 34°C
          </p>
          <div className="mt-3 bg-gray-100 rounded-full h-1.5">
            <div
              className="bg-orange-500 h-1.5 rounded-full transition-all"
              style={{ width: `${((latest.temperature - 20) / 20) * 100}%` }}
            />
          </div>
        </div>

      </div>

      {/* ── Sample Info ───────────────────────────────────────────────────── */}
      <div className="bg-[#1F3864] rounded-xl p-4
                      grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Farmer ID',   value: latest.farmer_id  || '--' },
          { label: 'Device ID',   value: latest.device_id  || '--' },
          { label: 'Sample ID',   value: latest.sample_id  || '--' },
          { label: 'Time',        value: formatShortTime(latest.timestamp) },
        ].map((item, i) => (
          <div key={i} className="text-center">
            <p className="text-gray-400 text-xs mb-1">
              {item.label}
            </p>
            <p className="text-white text-sm font-semibold truncate">
              {item.value}
            </p>
          </div>
        ))}
      </div>

      {/* ── VFA Trend Chart ───────────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm p-5
                      border border-gray-100">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-base font-bold text-[#1F3864]">
              VFA Trend — Last 20 Readings
            </h3>
            <p className="text-gray-400 text-xs mt-0.5">
              Real-time from Firebase
            </p>
          </div>
          <div className="flex items-center gap-4 text-xs text-gray-500">
            <div className="flex items-center gap-1">
              <div className="w-3 h-0.5 bg-[#C9A84C]" />
              <span>Grade B (0.05)</span>
            </div>
            <div className="flex items-center gap-1">
              <div className="w-3 h-0.5 bg-red-500" />
              <span>Grade C (0.08)</span>
            </div>
          </div>
        </div>

        <ResponsiveContainer width="100%" height={280}>
          <LineChart
            data={history}
            margin={{ top: 5, right: 20, left: 0, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
            <XAxis
              dataKey="time"
              tick={{ fontSize: 11, fill: '#9CA3AF' }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              domain={[0, 0.12]}
              tick={{ fontSize: 11, fill: '#9CA3AF' }}
              axisLine={false}
              tickLine={false}
              tickFormatter={v => v.toFixed(3)}
            />
            <Tooltip
              contentStyle={{
                background: '#1F3864',
                border: 'none',
                borderRadius: '8px',
                color: 'white',
                fontSize: '12px',
              }}
              formatter={(val) => [val.toFixed(4), 'VFA']}
            />
            <ReferenceLine
              y={0.05}
              stroke="#C9A84C"
              strokeDasharray="5 5"
              strokeWidth={1.5}
            />
            <ReferenceLine
              y={0.08}
              stroke="#C00000"
              strokeDasharray="5 5"
              strokeWidth={1.5}
            />
            <Line
              type="monotone"
              dataKey="vfa"
              stroke="#1F3864"
              strokeWidth={2.5}
              dot={{ fill: '#1F3864', r: 4, strokeWidth: 0 }}
              activeDot={{ r: 6, fill: '#C9A84C' }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* ── Recent Readings Table ─────────────────────────────────────────── */}
      <div className="bg-white rounded-xl shadow-sm
                      border border-gray-100 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <h3 className="text-base font-bold text-[#1F3864]">
            Recent Readings
          </h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-[#F4F6F9]">
              <tr>
                {['Time','Farmer','VFA','pH','Turbidity','Temp','Grade'].map(h => (
                  <th key={h}
                    className="px-4 py-3 text-left text-xs
                               font-semibold text-gray-500 uppercase">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {[...history].reverse().slice(0, 10).map((item, i) => (
                <tr key={item.id}
                  className={i % 2 === 0
                    ? 'bg-white hover:bg-[#F4F6F9]'
                    : 'bg-gray-50 hover:bg-[#F4F6F9]'
                  }>
                  <td className="px-4 py-3 text-gray-600 text-xs">
                    {item.time}
                  </td>
                  <td className="px-4 py-3 text-gray-700 font-medium text-xs">
                    {item.farmer_id}
                  </td>
                  <td className="px-4 py-3 font-bold text-xs"
                    style={{ color: getGradeColor(item.grade) }}>
                    {item.vfa.toFixed(4)}
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">
                    {item.pH.toFixed(2)}
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">
                    {item.turbidity.toFixed(1)}
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">
                    {item.temperature.toFixed(1)}°C
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-xs font-bold px-2 py-1
                                      rounded-lg
                                      ${getGradeBadgeColor(item.grade)}`}>
                      {getGradeIcon(item.grade)} {item.grade}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  )
}

export default LiveMonitor