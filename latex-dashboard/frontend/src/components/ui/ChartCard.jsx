// src/components/ui/ChartCard.jsx

import { ResponsiveContainer } from 'recharts'
import Card from './Card'
import EmptyState from './EmptyState'

const ChartCard = ({
  title, subtitle, action, height = 280, minHeight,
  empty = false, emptyLabel = 'No data',
  centerLabel, legend,
  children,
}) => (
  <Card title={title} subtitle={subtitle} action={action}>
    {empty ? (
      <div style={{ height }} className="flex items-center justify-center">
        <EmptyState title={emptyLabel} />
      </div>
    ) : (
      legend ? (
        <div className="flex flex-col xl:flex-row xl:items-center gap-6">
          <div style={{ height }} className="relative w-full xl:w-64 xl:shrink-0">
            <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={minHeight ?? Math.min(height, 200)}>
              {children}
            </ResponsiveContainer>
            {centerLabel && (
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-3xl font-bold tracking-tight text-ink tabular-nums">
                  {centerLabel.value}
                </span>
                <span className="text-xs font-medium text-muted mt-0.5">
                  {centerLabel.label}
                </span>
              </div>
            )}
          </div>
          <div className="w-full xl:flex-1 xl:min-w-0">{legend}</div>
        </div>
      ) : (
        <div style={{ width: '100%', height }} className="relative">
          <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={minHeight ?? Math.min(height, 200)}>
            {children}
          </ResponsiveContainer>
          {centerLabel && (
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-3xl font-bold tracking-tight text-ink tabular-nums">
                {centerLabel.value}
              </span>
              <span className="text-xs font-medium text-muted mt-0.5">
                {centerLabel.label}
              </span>
            </div>
          )}
        </div>
      )
    )}
  </Card>
)

export default ChartCard
