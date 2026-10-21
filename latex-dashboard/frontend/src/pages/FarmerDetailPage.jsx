// src/pages/FarmerDetailPage.jsx

import { useEffect, useMemo } from 'react'
import { useParams, Link } from 'react-router-dom'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from 'recharts'
import {
  PageHeader, Card, StatCard, DataTable, Badge, Spinner, EmptyState, ChartTooltip,
} from '../components/ui'
import useFactoryData from '../hooks/useFactoryData'
import { parseNum, round, farmerActivity } from '../utils/aggregate'
import { COLORS, AXIS_TICK, GRID_STROKE } from '../constants/theme'
import { formatDateReadable } from '../utils/dateHelper'
import { exportCsv } from '../utils/csv'

const Field = ({ label, value }) => (
  <div>
    <p className="text-xs font-medium uppercase tracking-wide text-faint">{label}</p>
    <p className="text-sm text-ink mt-0.5">{value || '—'}</p>
  </div>
)

const FarmerDetailPage = () => {
  const { uid } = useParams()
  const { usersById, joinedSessions, loading, error } = useFactoryData()

  const farmer = usersById.get(uid)

  const sessions = useMemo(
    () =>
      joinedSessions
        .filter((s) => s.userId === uid)
        .sort((a, b) => (b.sessionDate?.getTime() || 0) - (a.sessionDate?.getTime() || 0)),
    [joinedSessions, uid],
  )

  useEffect(() => {
    document.title = farmer?.name ? `${farmer.name} — LatexGuard` : 'Farmer — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [farmer])

  const stats = useMemo(() => {
    const act = farmerActivity(sessions).get(uid)
    return {
      sessionCount: act?.sessionCount || 0,
      totalVolumeL: act?.totalVolumeL || 0,
      avgYieldPerTreeL: act?.avgYieldPerTreeL || 0,
      lastSession: act?.lastSession || null,
    }
  }, [sessions, uid])

  const chartData = useMemo(
    () =>
      [...sessions]
        .filter((s) => s.sessionDate)
        .sort((a, b) => a.sessionDate - b.sessionDate)
        .map((s) => ({
          date: s.sessionDate.toISOString().slice(5, 10),
          volumeL: round(parseNum(s.latexVolumeL)),
        })),
    [sessions],
  )

  if (loading) return <Spinner size="lg" label="Loading farmer…" className="min-h-[60vh]" />

  if (!farmer) {
    return (
      <div className="space-y-4">
        <Link to="/farmers" className="text-sm text-brand hover:underline">← Back to farmers</Link>
        <EmptyState title="Farmer not found" description={error || `No user record for ${uid}`} />
      </div>
    )
  }

  const sessionColumns = [
    {
      key: 'sessionDate',
      label: 'Date',
      sortable: true,
      sortValue: (r) => r.sessionDate?.getTime() || 0,
      render: (r) => (r.sessionDate ? formatDateReadable(r.sessionDate) : '—'),
    },
    { key: 'startTime', label: 'Start', render: (r) => r.startTime || '—' },
    { key: 'endTime', label: 'End', render: (r) => r.endTime || '—' },
    { key: 'durationMinutes', label: 'Duration (min)', align: 'right', sortable: true },
    { key: 'treesCount', label: 'Trees', align: 'right', sortable: true },
    { key: 'latexVolumeL', label: 'Volume (L)', align: 'right', sortable: true, render: (r) => parseNum(r.latexVolumeL) },
    { key: 'yieldPerTreeL', label: 'Yield/tree (L)', align: 'right', sortable: true, render: (r) => parseNum(r.yieldPerTreeL) },
    { key: 'treeCondition', label: 'Tree condition', render: (r) => r.treeCondition || '—' },
    { key: 'weatherCondition', label: 'Weather', render: (r) => r.weatherCondition || '—' },
    { key: 'notes', label: 'Notes', render: (r) => r.notes || '—' },
  ]

  const handleExport = () =>
    exportCsv(`farmer-${farmer.name || uid}-sessions`, sessions, [
      { key: 'sessionDate', label: 'Date', format: (r) => (r.sessionDate ? r.sessionDate.toISOString().slice(0, 10) : '') },
      { key: 'startTime', label: 'Start' },
      { key: 'endTime', label: 'End' },
      { key: 'durationMinutes', label: 'Duration (min)' },
      { key: 'treesCount', label: 'Trees' },
      { key: 'latexVolumeL', label: 'Volume (L)' },
      { key: 'yieldPerTreeL', label: 'Yield/tree (L)' },
      { key: 'treeCondition', label: 'Tree condition' },
      { key: 'weatherCondition', label: 'Weather' },
      { key: 'notes', label: 'Notes' },
    ])

  return (
    <div className="space-y-6">
      <Link to="/farmers" className="text-sm text-brand hover:underline">← Back to farmers</Link>

      <PageHeader
        title={farmer.name || uid}
        description={[farmer.district, farmer.address].filter(Boolean).join(' · ') || 'Farmer profile'}
        actions={
          <div className="flex items-center gap-2">
            {farmer.isNew && <Badge tone="brand">New farmer</Badge>}
            {farmer.modelFarmerId && <Badge>{farmer.modelFarmerId}</Badge>}
          </div>
        }
      />

      <Card title="Profile">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
          <Field label="Phone" value={farmer.phone} />
          <Field label="NIC" value={farmer.nic} />
          <Field label="Email" value={farmer.email} />
          <Field label="Experience" value={farmer.experience} />
          <Field label="Land size" value={farmer.landSize} />
          <Field label="Rubber trees (total)" value={farmer.rubberTrees} />
          <Field label="District" value={farmer.district} />
          <Field label="Address" value={farmer.address} />
        </div>
      </Card>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard label="Sessions" value={stats.sessionCount} />
        <StatCard label="Total volume" value={`${stats.totalVolumeL} L`} tone="brand" />
        <StatCard label="Avg yield / tree" value={`${stats.avgYieldPerTreeL} L`} />
        <StatCard
          label="Last session"
          value={stats.lastSession ? formatDateReadable(stats.lastSession) : '—'}
        />
      </div>

      <Card title="Volume over time">
        {chartData.length === 0 ? (
          <EmptyState title="No sessions recorded" />
        ) : (
          <div style={{ width: '100%', height: 240 }}>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData} margin={{ top: 8, right: 8, left: -12, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke={GRID_STROKE} vertical={false} />
                <XAxis dataKey="date" tick={AXIS_TICK} axisLine={false} tickLine={false} />
                <YAxis tick={AXIS_TICK} axisLine={false} tickLine={false} />
                <Tooltip content={<ChartTooltip rows={(p) => [{ label: 'Volume (L)', value: p[0].payload.volumeL, color: COLORS.brand }]} />} />
                <Line type="monotone" dataKey="volumeL" stroke={COLORS.brand} strokeWidth={2} dot={{ r: 3, fill: COLORS.brand }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
      </Card>

      <div>
        <div className="flex items-center justify-between mb-3">
          <div>
            <h3 className="text-sm font-semibold text-ink">Tapping sessions</h3>
            <p className="text-xs text-muted mt-0.5">{sessions.length} sessions</p>
          </div>
          {sessions.length > 0 && (
            <button
              onClick={handleExport}
              className="rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted hover:bg-slate-50 hover:text-ink transition-colors"
            >
              Export CSV
            </button>
          )}
        </div>
        <DataTable
          columns={sessionColumns}
          rows={sessions}
          getRowKey={(r) => r.id}
          initialSort={{ key: 'sessionDate', dir: 'desc' }}
          emptyMessage="No tapping sessions for this farmer"
        />
      </div>
    </div>
  )
}

export default FarmerDetailPage
