// src/utils/csv.js
//
// Minimal client-side CSV export. No dependency.

const escapeCell = (value) => {
  if (value === null || value === undefined) return ''
  const str = String(value)
  return /[",\n]/.test(str) ? `"${str.replace(/"/g, '""')}"` : str
}

/**
 * @param {Array<object>} rows
 * @param {Array<{ key: string, label: string, format?: (row: object) => any }>} columns
 * @returns {string} CSV text
 */
export const toCsv = (rows, columns) => {
  const header = columns.map((c) => escapeCell(c.label)).join(',')
  const body = rows.map((row) =>
    columns
      .map((c) => escapeCell(c.format ? c.format(row) : row[c.key]))
      .join(','),
  )
  return [header, ...body].join('\n')
}

export const downloadCsv = (filename, csvText) => {
  const blob = new Blob(['﻿' + csvText], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename.endsWith('.csv') ? filename : `${filename}.csv`
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

/** Convenience: build + download in one call. */
export const exportCsv = (filename, rows, columns) =>
  downloadCsv(filename, toCsv(rows, columns))
