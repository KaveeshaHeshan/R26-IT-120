// src/components/ui/Donut.jsx
//
// Standalone forest/ground-redesign donut: a bare Recharts pie (no Card
// chrome — callers wrap it in <Card variant="v2">) with a centered total.
// New component (not a variant of ChartCard) since ChartCard's default is
// still used as-is by the not-yet-redesigned Quality Summary page.

import { PieChart, Pie, Cell, ResponsiveContainer } from 'recharts'

const Donut = ({ data, size = 190, centerValue, centerLabel }) => (
  <div className="relative shrink-0 mx-auto sm:mx-0" style={{ width: size, height: size }}>
    <ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie
          data={data}
          dataKey="value"
          nameKey="name"
          cx="50%"
          cy="50%"
          innerRadius="70%"
          outerRadius="100%"
          paddingAngle={2}
          stroke="none"
        >
          {data.map((d, i) => (
            <Cell key={i} fill={d.color} />
          ))}
        </Pie>
      </PieChart>
    </ResponsiveContainer>
    {(centerValue != null || centerLabel) && (
      <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
        <span className="font-display text-[36px] font-bold leading-none text-[#11231A] tabular-nums">
          {centerValue}
        </span>
        {centerLabel && <span className="text-xs text-[#5A6B5F] mt-1">{centerLabel}</span>}
      </div>
    )}
  </div>
)

export default Donut
