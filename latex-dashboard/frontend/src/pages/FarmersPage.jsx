// src/pages/FarmersPage.jsx

import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { LuDownload } from 'react-icons/lu'
import { PageHeader, Card, DataTable, Select, SearchInput, Badge, Spinner, Avatar, Button } from '../components/ui'
import useFactoryData from '../hooks/useFactoryData'
import { parseNum, isLowActivity } from '../utils/aggregate'
import { exportCsv } from '../utils/csv'
import { formatDateReadable } from '../utils/dateHelper'

const LOW_ACTIVITY_OPTIONS = [
  { value: '7', label: '7 days' },
  { value: '14', label: '14 days' },
  { value: '30', label: '30 days' },
]

const FarmersPage = () => {
  const navigate = useNavigate()
  const { farmers, districts, activityByFarmer, loading, error } = useFactoryData()

  const [term, setTerm] = useState('')
  const [district, setDistrict] = useState('all')
  const [lowDays, setLowDays] = useState('14')

  useEffect(() => {
    document.title = 'Farmers — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  const rows = useMemo(() => {
    const t = term.trim().toLowerCase()
    return farmers
      .filter((f) => (district === 'all' ? true : f.district === district))
      .filter((f) =>
        !t
          ? true
          : [f.name, f.district, f.address, f.nic].some((v) =>
              String(v || '').toLowerCase().includes(t),
            ),
      )
      .map((f) => {
        const act = activityByFarmer.get(f.uid)
        return {
          ...f,
          landSizeNum: parseNum(f.landSize),
          treesNum: parseNum(f.rubberTrees),
          lastSession: act?.lastSession || null,
          totalVolumeL: act?.totalVolumeL || 0,
          low: isLowActivity(act?.lastSession, Number(lowDays)),
        }
      })
  }, [farmers, district, term, activityByFarmer, lowDays])

  const handleExport = () =>
    exportCsv('farmers-directory', rows, [
      { key: 'name', label: 'Name' },
      { key: 'address', label: 'Address' },
      { key: 'district', label: 'District' },
      { key: 'landSizeNum', label: 'Land size' },
      { key: 'treesNum', label: 'Rubber trees' },
      { key: 'phone', label: 'Phone' },
      { key: 'experience', label: 'Experience' },
      { key: 'totalVolumeL', label: 'Total volume (L)' },
      { key: 'lastSession', label: 'Last session', format: (r) => (r.lastSession ? r.lastSession.toISOString().slice(0, 10) : '') },
    ])

  if (loading) return <Spinner size="lg" label="Loading farmers…" className="min-h-[60vh]" />

  const columns = [
    {
      key: 'name',
      label: 'Name',
      sortable: true,
      render: (r) => (
        <span className="flex items-center gap-3">
          <Avatar name={r.name || r.uid} size={34} />
          <span className="font-semibold text-[#11231A]">{r.name || r.uid}</span>
        </span>
      ),
    },
    { key: 'district', label: 'District', sortable: true, render: (r) => r.district || '—' },
    { key: 'address', label: 'Address', render: (r) => <span className="text-[#3F5146]">{r.address || '—'}</span> },
    { key: 'landSizeNum', label: 'Land', align: 'right', sortable: true },
    { key: 'treesNum', label: 'Trees', align: 'right', sortable: true },
    { key: 'phone', label: 'Phone', render: (r) => r.phone || '—' },
    { key: 'experience', label: 'Experience', render: (r) => r.experience || '—' },
    {
      key: 'lastSession',
      label: 'Last session',
      sortable: true,
      sortValue: (r) => (r.lastSession ? r.lastSession.getTime() : 0),
      render: (r) => {
        const tone = !r.lastSession ? 'danger' : r.low ? 'warning' : 'success'
        const label = r.lastSession ? formatDateReadable(r.lastSession) : 'Never'
        return (
          <Badge variant="v2" tone={tone}>
            {label}
          </Badge>
        )
      },
    },
  ]

  return (
    <div className="space-y-6">
      <PageHeader
        variant="v2"
        title="Farmers"
        description={`${farmers.length} registered farmers`}
        actions={
          <Button variant="primary" icon={<LuDownload size={16} className="text-glow" />} onClick={handleExport}>
            Export CSV
          </Button>
        }
      />

      {error && (
        <Card className="border-amber-200 bg-amber-50">
          <p className="text-sm text-amber-800">{error}</p>
        </Card>
      )}

      <Card variant="v2" padded={false} className="overflow-hidden">
        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-[14px] px-[22px] py-[18px] border-b border-[#EDF1E9]">
          <SearchInput
            variant="v2"
            value={term}
            onChange={setTerm}
            placeholder="Search name, district, NIC…"
            className="w-full sm:w-64"
          />
          <Select
            variant="v2"
            label="District"
            value={district}
            onChange={setDistrict}
            options={[{ value: 'all', label: 'All districts' }, ...districts.map((d) => ({ value: d, label: d }))]}
          />
          <Select variant="v2" label="Low activity" value={lowDays} onChange={setLowDays} options={LOW_ACTIVITY_OPTIONS} />
          <span className="ml-auto text-sm text-[#5A6B5F]">{rows.length} shown</span>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <div className="min-w-[980px]">
            <DataTable
              variant="v2"
              columns={columns}
              rows={rows}
              getRowKey={(r) => r.uid}
              initialSort={{ key: 'name', dir: 'asc' }}
              onRowClick={(r) => navigate(`/farmers/${r.uid}`)}
              emptyMessage="No farmers match these filters"
            />
          </div>
        </div>

        {/* Footer legend */}
        <div className="flex flex-wrap items-center gap-4 px-[22px] py-4 border-t border-[#EDF1E9] text-sm text-[#5A6B5F]">
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#1EAE57]" /> Active in last {lowDays} days
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#D97706]" /> Low activity
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#DC2626]" /> Never recorded
          </span>
        </div>
      </Card>
    </div>
  )
}

export default FarmersPage
