// src/components/ui/Avatar.jsx
//
// Initials tile/circle for the forest/ground redesign (Farmers table,
// Supervisors cards, etc). New component — real name is always derived from
// the actual record, never hard-coded.

const SHAPES = {
  circle: 'rounded-full',
  square: 'rounded-xl',
  tile: 'rounded-2xl',
}

const Avatar = ({ name, size = 34, bg = '#EAF1E6', color = '#1F4D30', shape = 'circle', className = '' }) => {
  const initials =
    String(name || '')
      .split(' ')
      .map((n) => n[0])
      .filter(Boolean)
      .slice(0, 2)
      .join('')
      .toUpperCase() || '—'

  return (
    <span
      className={`inline-flex items-center justify-center font-bold shrink-0 ${SHAPES[shape] || SHAPES.circle} ${className}`}
      style={{ width: size, height: size, background: bg, color }}
    >
      {initials}
    </span>
  )
}

export default Avatar
