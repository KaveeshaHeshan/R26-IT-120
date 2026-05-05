// src/components/shared/VFAChart.jsx

import { LineChart, Line, XAxis, YAxis,
         CartesianGrid, Tooltip,
         ResponsiveContainer, ReferenceLine,
         Area, AreaChart, Legend }          from 'recharts'
import { getGradeColor }                   from '../../utils/gradeHelper'

// ── Custom Tooltip ────────────────────────────────────────────────────────────
const CustomTooltip = ({ active, payload, label }) => {
  if (!active || !payload || !payload.length) return null

  const vfa   = payload[0]?.value
  const grade = vfa < 0.05 ? 'A' : vfa < 0.08 ? 'B' : 'C'

  return (
    <div className="bg-[#1F3864] text-white rounded-xl
                    px-4 py-3 shadow-xl text-xs">
      <p className="text-gray-300 mb-1">{label}</p>
      <p className="text-lg font-bold">
        VFA: {vfa?.toFixed(4)}
      </p>
      <p
        className="font-semibold mt-1"
        style={{ color: getGradeColor(grade) }}
      >
        Grade {grade}
      </p>
    </div>
  )
}

// ── Custom Dot ────────────────────────────────────────────────────────────────
const CustomDot = ({ cx, cy, payload }) => {
  const grade = payload.grade ||
    (payload.vfa < 0.05 ? 'A' : payload.vfa < 0.08 ? 'B' : 'C')
  return (
    <circle
      cx={cx}
      cy={cy}
      r={4}
      fill={getGradeColor(grade)}
      stroke="white"
      strokeWidth={1.5}
    />
  )
}

// ── VFAChart Component ────────────────────────────────────────────────────────
const VFAChart = ({
  data        = [],
  dataKey     = 'vfa',
  xKey        = 'time',
  height      = 280,
  type        = 'line',    // 'line' | 'area'
  showLegend  = false,
  showDots    = true,
  animated    = true,
  title       = '',
  subtitle    = '',
}) => {

  // ── No data ─────────────────────────────────────────────────────────────────
  if (!data || data.length === 0) {
    return (
      <div
        className="flex items-center justify-center
                   bg-gray-50 rounded-xl border border-gray-100"
        style={{ height }}
      >
        <div className="text-center">
          <p className="text-4xl mb-2">📊</p>
          <p className="text-gray-400 text-sm">No data available</p>
        </div>
      </div>
    )
  }

  // ── Shared chart props ──────────────────────────────────────────────────────
  const commonProps = {
    data,
    margin: { top:5, right:20, left:0, bottom:5 },
  }

  const axisProps = {
    xAxis: {
      dataKey:  xKey,
      tick:     { fontSize:11, fill:'#9CA3AF' },
      axisLine: false,
      tickLine: false,
    },
    yAxis: {
      domain:        [0, 0.12],
      tick:          { fontSize:11, fill:'#9CA3AF' },
      axisLine:      false,
      tickLine:      false,
      tickFormatter: v => v.toFixed(3),
    },
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <div>

      {/* ── Title ─────────────────────────────────────────────────────────── */}
      {(title || subtitle) && (
        <div className="mb-4">
          {title && (
            <h4 className="text-base font-bold text-[#1F3864]">
              {title}
            </h4>
          )}
          {subtitle && (
            <p className="text-gray-400 text-xs mt-0.5">
              {subtitle}
            </p>
          )}
        </div>
      )}

      {/* ── Legend ────────────────────────────────────────────────────────── */}
      <div className="flex items-center gap-4 mb-3 text-xs text-gray-500">
        <div className="flex items-center gap-1.5">
          <div className="w-4 h-0.5 bg-[#C9A84C]" />
          <span>Grade B (0.05)</span>
        </div>
        <div className="flex items-center gap-1.5">
          <div className="w-4 h-0.5 bg-red-500" />
          <span>Grade C (0.08)</span>
        </div>
        {data.length > 0 && (
          <div className="flex items-center gap-1.5 ml-auto">
            <span className="text-gray-400">
              {data.length} readings
            </span>
          </div>
        )}
      </div>

      {/* ── Chart ─────────────────────────────────────────────────────────── */}
      <ResponsiveContainer width="100%" height={height}>

        {type === 'area' ? (

          // ── Area Chart ───────────────────────────────────────────────────
          <AreaChart {...commonProps}>
            <defs>
              <linearGradient id="vfaGradient" x1="0" y1="0"
                              x2="0" y2="1">
                <stop offset="5%"
                  stopColor="#1F3864" stopOpacity={0.2} />
                <stop offset="95%"
                  stopColor="#1F3864" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
            <XAxis {...axisProps.xAxis} />
            <YAxis {...axisProps.yAxis} />
            <Tooltip content={<CustomTooltip />} />
            <ReferenceLine y={0.05} stroke="#C9A84C"
              strokeDasharray="5 5" strokeWidth={1.5} />
            <ReferenceLine y={0.08} stroke="#C00000"
              strokeDasharray="5 5" strokeWidth={1.5} />
            {showLegend && <Legend />}
            <Area
              type="monotone"
              dataKey={dataKey}
              stroke="#1F3864"
              strokeWidth={2.5}
              fill="url(#vfaGradient)"
              dot={showDots
                ? <CustomDot />
                : false
              }
              activeDot={{
                r:           6,
                fill:        '#C9A84C',
                stroke:      'white',
                strokeWidth: 2,
              }}
              isAnimationActive={animated}
            />
          </AreaChart>

        ) : (

          // ── Line Chart ───────────────────────────────────────────────────
          <LineChart {...commonProps}>
            <CartesianGrid strokeDasharray="3 3" stroke="#F0F0F0" />
            <XAxis {...axisProps.xAxis} />
            <YAxis {...axisProps.yAxis} />
            <Tooltip content={<CustomTooltip />} />
            <ReferenceLine y={0.05} stroke="#C9A84C"
              strokeDasharray="5 5" strokeWidth={1.5} />
            <ReferenceLine y={0.08} stroke="#C00000"
              strokeDasharray="5 5" strokeWidth={1.5} />
            {showLegend && <Legend />}
            <Line
              type="monotone"
              dataKey={dataKey}
              stroke="#1F3864"
              strokeWidth={2.5}
              dot={showDots
                ? <CustomDot />
                : false
              }
              activeDot={{
                r:           6,
                fill:        '#C9A84C',
                stroke:      'white',
                strokeWidth: 2,
              }}
              isAnimationActive={animated}
            />
          </LineChart>

        )}

      </ResponsiveContainer>
    </div>
  )
}

export default VFAChart