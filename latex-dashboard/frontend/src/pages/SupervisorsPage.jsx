// src/pages/SupervisorsPage.jsx

import { useEffect, useMemo, useState } from 'react'
import { LuPhone, LuMail, LuDownload } from 'react-icons/lu'
import { PageHeader, Card, SearchInput, Spinner, Avatar, Button, EmptyState } from '../components/ui'
import useUsers from '../hooks/useUsers'
import { exportCsv } from '../utils/csv'

const SupervisorsPage = () => {
  const { supervisors, loading, error } = useUsers()
  const [term, setTerm] = useState('')

  useEffect(() => {
    document.title = 'Supervisors — LatexGuard'
    return () => { document.title = 'LatexGuard' }
  }, [])

  const rows = useMemo(() => {
    const t = term.trim().toLowerCase()
    return supervisors.filter((s) =>
      !t
        ? true
        : [s.name, s.employeeId, s.email, s.phone].some((v) =>
            String(v || '').toLowerCase().includes(t),
          ),
    )
  }, [supervisors, term])

  if (loading) return <Spinner size="lg" label="Loading supervisors…" className="min-h-[60vh]" />

  const handleExport = () =>
    exportCsv('supervisors', rows, [
      { key: 'name', label: 'Name' },
      { key: 'employeeId', label: 'Employee ID' },
      { key: 'phone', label: 'Phone' },
      { key: 'email', label: 'Email' },
    ])

  return (
    <div className="space-y-6">
      <PageHeader
        variant="v2"
        title="Supervisors"
        description={`${supervisors.length} registered supervisors`}
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

      <div className="rounded-2xl bg-white border border-line px-[18px] py-[14px] flex flex-wrap items-center gap-[14px]">
        <SearchInput
          variant="v2"
          value={term}
          onChange={setTerm}
          placeholder="Search name, ID, email…"
          className="w-full sm:w-72"
        />
        <span className="ml-auto text-sm text-[#5A6B5F]">{rows.length} shown</span>
      </div>

      {rows.length === 0 ? (
        <Card variant="v2">
          <EmptyState title="No supervisors match this search" />
        </Card>
      ) : (
        <div className="flex flex-wrap gap-5">
          {rows.map((s) => {
            // Real status, unchanged semantics from the rest of the app
            // (Badge "New" / plain "Active" elsewhere) — just a richer pill here.
            const active = !s.isNew
            return (
              <div
                key={s.uid}
                className="flex-[1_1_300px] min-w-0 rounded-[20px] bg-white border border-line p-6 flex flex-col gap-5"
              >
                <div className="flex items-center gap-4">
                  <Avatar
                    name={s.name || s.uid}
                    size={52}
                    shape="tile"
                    bg="#0E2A1C"
                    color="#7BE08F"
                    className="font-display text-lg"
                  />
                  <div className="min-w-0 flex-1">
                    <p className="text-lg font-bold text-[#11231A] truncate">{s.name || s.uid}</p>
                    <p className="text-sm text-[#5A6B5F] truncate">Employee ID · {s.employeeId || '—'}</p>
                  </div>
                  {active ? (
                    <span className="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-[#E3F5E8] px-[11px] py-[5px] text-[13px] font-semibold text-[#0B5E2D]">
                      <span className="w-[6px] h-[6px] rounded-full bg-brand-500" />
                      Active
                    </span>
                  ) : (
                    <span className="shrink-0 inline-flex items-center gap-1.5 rounded-full bg-[#FBF0D5] px-[11px] py-[5px] text-[13px] font-semibold text-[#7A4A06]">
                      <span className="w-[6px] h-[6px] rounded-full bg-[#D97706]" />
                      New
                    </span>
                  )}
                </div>

                <div className="border-t border-[#EDF1E9] pt-[18px] flex flex-col gap-3">
                  <div className="flex items-center gap-2 text-sm text-[#3F5146]">
                    <LuPhone size={18} className="text-[#5A6B5F] shrink-0" />
                    <span>{s.phone || '—'}</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-[#3F5146]">
                    <LuMail size={18} className="text-[#5A6B5F] shrink-0" />
                    <span className="break-all">{s.email || '—'}</span>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

export default SupervisorsPage
