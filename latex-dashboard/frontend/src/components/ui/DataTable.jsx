// src/components/ui/DataTable.jsx
//
// Column-config driven table. Read-only presentation only.
//
// columns: Array<{
//   key: string
//   label: string
//   sortable?: boolean
//   align?: 'left' | 'right' | 'center'
//   render?: (row) => ReactNode
//   sortValue?: (row) => string | number   // defaults to row[key]
// }>

import { useState, useMemo } from 'react'
import EmptyState from './EmptyState'

const alignClass = (a) => (a === 'right' ? 'text-right' : a === 'center' ? 'text-center' : 'text-left')

// `variant="v2"` opts into the forest/ground redesign's table styling. It
// renders the bare <table> only (no outer border/rounded/shadow wrapper) so
// the caller's own card + overflow-x-auto wrapper provides that chrome —
// the default variant (unchanged) keeps its own wrapper for pages that still
// render DataTable standalone.
const DataTable = ({
  columns,
  rows,
  getRowKey = (_, i) => i,
  onRowClick,
  initialSort,
  emptyMessage = 'No records',
  variant = 'default',
}) => {
  const [sort, setSort] = useState(initialSort || null) // { key, dir: 'asc'|'desc' }

  const sortedRows = useMemo(() => {
    if (!sort) return rows
    const col = columns.find((c) => c.key === sort.key)
    if (!col) return rows
    const getVal = col.sortValue || ((r) => r[col.key])
    const factor = sort.dir === 'asc' ? 1 : -1
    return [...rows].sort((a, b) => {
      const va = getVal(a)
      const vb = getVal(b)
      if (va == null) return 1
      if (vb == null) return -1
      if (typeof va === 'number' && typeof vb === 'number') return (va - vb) * factor
      return String(va).localeCompare(String(vb), undefined, { numeric: true }) * factor
    })
  }, [rows, sort, columns])

  const toggleSort = (key) => {
    setSort((prev) => {
      if (prev?.key !== key) return { key, dir: 'asc' }
      if (prev.dir === 'asc') return { key, dir: 'desc' }
      return null
    })
  }

  if (variant === 'v2') {
    const cellPad = (idx) => (idx === 0 ? 'py-[14px] pl-[22px] pr-3' : 'py-[14px] px-3')
    return (
      <table className="w-full text-sm">
        <thead>
          <tr className="bg-[#F7FAF4]">
            {columns.map((col, idx) => {
              const active = sort?.key === col.key
              return (
                <th
                  key={col.key}
                  className={`${cellPad(idx)} text-[12px] font-bold uppercase tracking-[0.06em] text-[#5A6B5F] whitespace-nowrap ${alignClass(col.align)} ${
                    col.sortable ? 'cursor-pointer select-none hover:text-[#11231A]' : ''
                  }`}
                  onClick={col.sortable ? () => toggleSort(col.key) : undefined}
                >
                  <span className="inline-flex items-center gap-1">
                    {col.label}
                    {col.sortable && (
                      <span className={active ? 'text-brand-600' : 'text-[#B9C7B2]'}>
                        {active ? (sort.dir === 'asc' ? '▲' : '▼') : '⇅'}
                      </span>
                    )}
                  </span>
                </th>
              )
            })}
          </tr>
        </thead>
        <tbody>
          {sortedRows.length === 0 ? (
            <tr>
              <td colSpan={columns.length}>
                <EmptyState title={emptyMessage} />
              </td>
            </tr>
          ) : (
            sortedRows.map((row, i) => (
              <tr
                key={getRowKey(row, i)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={`border-t border-[#EDF1E9] ${onRowClick ? 'cursor-pointer' : ''} hover:bg-[#F7FAF4] transition-colors`}
              >
                {columns.map((col, idx) => (
                  <td key={col.key} className={`${cellPad(idx)} text-[14px] text-[#11231A] whitespace-nowrap ${alignClass(col.align)}`}>
                    {col.render ? col.render(row) : (row[col.key] ?? '—')}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    )
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-border bg-surface shadow-sm">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-border bg-slate-50/60">
            {columns.map((col) => {
              const active = sort?.key === col.key
              return (
                <th
                  key={col.key}
                  className={`px-4 py-3 font-medium text-muted whitespace-nowrap ${alignClass(col.align)} ${
                    col.sortable ? 'cursor-pointer select-none hover:text-ink' : ''
                  }`}
                  onClick={col.sortable ? () => toggleSort(col.key) : undefined}
                >
                  <span className="inline-flex items-center gap-1">
                    {col.label}
                    {col.sortable && (
                      <span className={`text-[10px] ${active ? 'text-brand' : 'text-slate-300'}`}>
                        {active ? (sort.dir === 'asc' ? '▲' : '▼') : '⇅'}
                      </span>
                    )}
                  </span>
                </th>
              )
            })}
          </tr>
        </thead>
        <tbody>
          {sortedRows.length === 0 ? (
            <tr>
              <td colSpan={columns.length}>
                <EmptyState title={emptyMessage} />
              </td>
            </tr>
          ) : (
            sortedRows.map((row, i) => (
              <tr
                key={getRowKey(row, i)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={`border-b border-border last:border-0 ${
                  onRowClick ? 'cursor-pointer hover:bg-brand-soft' : 'hover:bg-slate-50/60'
                } transition-colors`}
              >
                {columns.map((col) => (
                  <td
                    key={col.key}
                    className={`px-4 py-3 text-ink whitespace-nowrap ${alignClass(col.align)}`}
                  >
                    {col.render ? col.render(row) : (row[col.key] ?? '—')}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  )
}

export default DataTable
