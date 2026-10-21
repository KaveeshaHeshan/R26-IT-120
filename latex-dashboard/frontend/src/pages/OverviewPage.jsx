// src/pages/OverviewPage.jsx

import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { LuUsers, LuSprout, LuShieldCheck, LuDroplet } from 'react-icons/lu'
import {
  PageHeader, StatCard, Card, Donut, DonutLegend, EmptyState, Spinner, ProgressBar, Button,
} from '../components/ui'
import useFactoryData from '../hooks/useFactoryData'
import usePredictions from '../hooks/usePredictions'
import { CHART_SERIES, GRADE_COLORS } from '../constants/theme'
import { volumeByDistrict, topFarmersByVolume, recentSessions, parseNum, round } from '../utils/aggregate'
import { exportCsv } from '../utils/csv'
import { formatDateReadable } from '../utils/dateHelper'

const todayStr = () => new Date().toISOString().slice(0, 10)
const daysAgoStr = (n) => {
  const d = new Date()
  d.setDate(d.getDate() - n)
  return d.toISOString().slice(0, 10)
}

const todayLabel = () =>
  new Date().toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })

const initialsOf = (name) =>
  String(name || '')
    .split(' ')
    .map((n) => n[0])
    .filter(Boolean)
    .slice(0, 2)
    .join('')
    .toUpperCase() || '—'

const OverviewPage = () => {
  const navigate = useNavigate()
  const { users, farmers, supervisors, joinedSessions, loading, error } = useFactoryData()
  const { predictions, loading: gradeLoading } = usePredictions()

  const [from, setFrom] = useState(daysAgoStr(30))
  const [to, setTo] = useState(todayStr())

  useEffect(() => {
    document.title = 'Overview — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  const totalVolume = useMemo(
    () => round(joinedSessions.reduce((s, x) => s + parseNum(x.latexVolumeL), 0)),
    [joinedSessions],
  )

  const farmersPct = users.length ? Math.round((farmers.length / users.length) * 100) : 0

  const activeSupervisors = useMemo(() => supervisors.filter((s) => !s.isNew).length, [supervisors])
  const supervisorsCaption =
    supervisors.length === 0
      ? 'No supervisors yet'
      : activeSupervisors === supervisors.length
        ? 'All active'
        : `${activeSupervisors} of ${supervisors.length} active`

  const roleData = useMemo(
    () => [
      { name: 'Farmers', value: farmers.length, color: CHART_SERIES[0] },
      { name: 'Supervisors', value: supervisors.length, color: '#1F3A2B' },
    ],
    [farmers.length, supervisors.length],
  )
  const roleSplit = useMemo(() => roleData.filter((d) => d.value > 0), [roleData])
  const totalPeople = farmers.length + supervisors.length

  const gradeTotals = useMemo(() => {
    const acc = { gradeA: 0, gradeB: 0, gradeC: 0 }
    predictions.forEach((p) => {
      const key = `grade${p.grade}`
      if (key in acc) acc[key] += 1
    })
    return acc
  }, [predictions])
  const gradeTotal = predictions.length

  const gradeData = useMemo(
    () => [
      { name: 'Grade A', value: gradeTotals.gradeA, color: GRADE_COLORS.A },
      { name: 'Grade B', value: gradeTotals.gradeB, color: GRADE_COLORS.B },
      { name: 'Grade C', value: gradeTotals.gradeC, color: GRADE_COLORS.C },
    ],
    [gradeTotals],
  )
  const gradeSplit = useMemo(() => gradeData.filter((d) => d.value > 0), [gradeData])

  const districtRange = useMemo(() => {
    const fromD = from ? new Date(from + 'T00:00:00') : null
    const toD = to ? new Date(to + 'T23:59:59') : null
    return volumeByDistrict(joinedSessions, { from: fromD, to: toD })
  }, [joinedSessions, from, to])

  const maxDistrictVolume = useMemo(
    () => Math.max(...districtRange.map((d) => d.volumeL), 1),
    [districtRange],
  )

  const topFarmers = useMemo(
    () => topFarmersByVolume(joinedSessions, { days: 30, limit: 8 }),
    [joinedSessions],
  )
  const topFarmerMax = topFarmers[0]?.volumeL || 1

  const feed = useMemo(() => recentSessions(joinedSessions, 12), [joinedSessions])

  if (loading) return <Spinner size="lg" label="Loading factory data…" className="min-h-[60vh]" />

  return (
    <div className="space-y-6">
      <PageHeader
        variant="v2"
        title="Overview"
        description="People, latex volume and quality at a glance."
        actions={
          <div className="rounded-xl border border-[#DDE4D8] bg-white px-[14px] py-[10px] text-sm font-medium text-[#5A6B5F]">
            {todayLabel()}
          </div>
        }
      />

      {error && (
        <Card className="border-amber-200 bg-amber-50">
          <p className="text-sm text-amber-800">{error}</p>
        </Card>
      )}

      {/* KPI row */}
      <div className="flex flex-wrap gap-5">
        <div className="flex-[1_1_220px]">
          <StatCard
            variant="kpi"
            label="Total users"
            value={users.length}
            sub="Farmers + supervisors"
            iconChip={{ icon: <LuUsers size={18} />, bg: '#EAF1E6', color: '#1F4D30' }}
          />
        </div>
        <div className="flex-[1_1_220px]">
          <StatCard
            variant="kpi"
            label="Farmers"
            value={farmers.length}
            sub={`${farmersPct}% of all users`}
            iconChip={{ icon: <LuSprout size={18} />, bg: '#E3F5E8', color: '#0E6B33' }}
          />
        </div>
        <div className="flex-[1_1_220px]">
          <StatCard
            variant="kpi"
            label="Supervisors"
            value={supervisors.length}
            sub={supervisorsCaption}
            iconChip={{ icon: <LuShieldCheck size={18} />, bg: '#E6EBF0', color: '#2B3F52' }}
          />
        </div>
        <div className="flex-[1_1_220px]">
          <StatCard
            variant="hero"
            label="Latex volume"
            value={totalVolume.toLocaleString('en-US')}
            unit="L"
            sub="All recorded sessions"
            iconChip={<LuDroplet size={18} />}
          />
        </div>
      </div>

      {/* Donuts */}
      <div className="flex flex-wrap gap-5">
        <Card variant="v2" className="flex-[1_1_420px]" title="People" subtitle="Farmer vs supervisor">
          {roleSplit.length === 0 ? (
            <EmptyState title="No users yet" />
          ) : (
            <div className="flex flex-col sm:flex-row items-center gap-6">
              <Donut data={roleSplit} centerValue={totalPeople} centerLabel="Total users" />
              <div className="w-full sm:flex-1 sm:min-w-0">
                <DonutLegend items={roleData} variant="v2" />
              </div>
            </div>
          )}
        </Card>

        <Card
          variant="v2"
          className="flex-[1_1_420px]"
          title="VFA grade distribution"
          subtitle={gradeLoading ? 'Loading…' : `${gradeTotal} classified readings`}
        >
          {gradeSplit.length === 0 ? (
            <EmptyState title="No readings yet" />
          ) : (
            <div className="flex flex-col sm:flex-row items-center gap-6">
              <Donut data={gradeSplit} centerValue={gradeTotal} centerLabel="Readings" />
              <div className="w-full sm:flex-1 sm:min-w-0">
                <DonutLegend items={gradeData} variant="v2" />
              </div>
            </div>
          )}
        </Card>
      </div>

      {/* Latex volume by district */}
      <Card
        variant="v2"
        title="Latex volume by district"
        subtitle="Aggregated from tapping sessions, joined to each farmer's district"
        action={
          <div className="flex flex-wrap items-center gap-2">
            <input
              type="date"
              value={from}
              max={to}
              onChange={(e) => setFrom(e.target.value)}
              className="h-10 rounded-xl border border-[#DDE4D8] bg-white px-3 text-sm text-[#11231A]"
            />
            <span className="text-sm text-[#8FA093]">→</span>
            <input
              type="date"
              value={to}
              min={from}
              max={todayStr()}
              onChange={(e) => setTo(e.target.value)}
              className="h-10 rounded-xl border border-[#DDE4D8] bg-white px-3 text-sm text-[#11231A]"
            />
            <Button
              variant="secondary"
              onClick={() =>
                exportCsv('district-volume', districtRange, [
                  { key: 'district', label: 'District' },
                  { key: 'volumeL', label: 'Volume (L)' },
                  { key: 'sessions', label: 'Sessions' },
                ])
              }
            >
              Export CSV
            </Button>
          </div>
        }
      >
        {districtRange.length === 0 ? (
          <EmptyState title="No sessions in this range" />
        ) : (
          <div className="space-y-5">
            {districtRange.map((d) => (
              <div key={d.district}>
                <div className="flex flex-wrap items-baseline justify-between gap-2 mb-2">
                  <span className="text-base font-semibold text-[#11231A]">{d.district}</span>
                  <span className="text-sm text-[#5A6B5F]">
                    <strong className="font-bold text-[#11231A]">{d.volumeL.toLocaleString('en-US')} L</strong>
                    {' · '}
                    {d.sessions} session{d.sessions === 1 ? '' : 's'}
                  </span>
                </div>
                <ProgressBar value={d.volumeL} max={maxDistrictVolume} height={14} />
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* Top farmers / recent activity */}
      <div className="flex flex-wrap gap-5">
        <Card variant="v2" className="flex-[1_1_420px]" title="Top farmers by volume" subtitle="Last 30 days">
          {topFarmers.length === 0 ? (
            <EmptyState title="No sessions in the last 30 days" />
          ) : (
            <ul className="space-y-4">
              {topFarmers.map((f, i) => (
                <li
                  key={f.uid}
                  className="cursor-pointer"
                  onClick={() => navigate(`/farmers/${f.uid}`)}
                >
                  <div className="flex items-center gap-3">
                    <span className="w-[34px] h-[34px] shrink-0 rounded-full bg-[#E8F6EC] text-brand-700 font-bold flex items-center justify-center">
                      {i + 1}
                    </span>
                    <p className="min-w-0 flex-1 text-sm font-semibold text-[#11231A] truncate">
                      {f.name} <span className="font-normal text-[#5A6B5F]">· {f.district}</span>
                    </p>
                    <span className="shrink-0 text-sm font-bold text-[#11231A] tabular-nums">
                      {f.volumeL.toLocaleString('en-US')} L
                    </span>
                  </div>
                  <div className="mt-2 ml-[46px]">
                    <ProgressBar value={f.volumeL} max={topFarmerMax} height={8} />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card variant="v2" className="flex-[1_1_420px]" title="Recent activity" subtitle="Latest tapping sessions">
          {feed.length === 0 ? (
            <EmptyState title="No recent sessions" />
          ) : (
            <ul>
              {feed.map((s, i) => (
                <li
                  key={s.id}
                  onClick={() => s.userId && navigate(`/farmers/${s.userId}`)}
                  className={`flex items-center gap-3 py-3 cursor-pointer ${i > 0 ? 'border-t border-[#EDF1E9]' : ''}`}
                >
                  <span className="w-10 h-10 shrink-0 rounded-xl bg-[#EAF1E6] text-[#1F4D30] font-bold flex items-center justify-center">
                    {initialsOf(s.farmerName || s.userId)}
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold text-[#11231A] truncate">
                      {s.farmerName || s.userId || 'Unknown'}
                    </p>
                    <p className="text-xs text-[#5A6B5F] truncate">
                      {s.district || '—'} · {s.treesCount ?? '—'} trees
                    </p>
                  </div>
                  <div className="text-right shrink-0">
                    <p className="text-sm font-bold text-[#11231A] tabular-nums">{parseNum(s.latexVolumeL)} L</p>
                    <p className="text-xs text-[#5A6B5F]">
                      {s.sessionDate ? formatDateReadable(s.sessionDate) : '—'}
                    </p>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>
    </div>
  )
}

export default OverviewPage
