// src/components/ui/BrandMark.jsx
//
// Code-built brand mark (icon tile + "Latex Guard" wordmark) — no image
// assets. Used in the Sidebar and the Login page's left panel.

const SIZES = {
  md: { tile: 40, icon: 20, text: 22 },
  lg: { tile: 44, icon: 22, text: 26 },
}

const DropIcon = ({ size, color }) => (
  <svg viewBox="0 0 24 24" width={size} height={size} aria-hidden="true">
    <path d="M12 2.5c3.6 4.4 6.5 7.7 6.5 11.5a6.5 6.5 0 0 1-13 0C5.5 10.2 8.4 6.9 12 2.5Z" fill={color} />
    <path d="M9 14.5a3 3 0 0 0 2.2 2.9" stroke="#fff" strokeOpacity=".6" strokeWidth="1.6" strokeLinecap="round" fill="none" />
  </svg>
)

const BrandMark = ({ variant = 'light', size = 'md' }) => {
  const dims = SIZES[size] || SIZES.md
  const light = variant === 'light'

  const tileStyle = light
    ? { width: dims.tile, height: dims.tile, background: '#E3F5E8' }
    : {
        width: dims.tile,
        height: dims.tile,
        background: 'rgba(255,255,255,0.10)',
        border: '1px solid rgba(255,255,255,0.15)',
      }

  const iconColor = light ? '#138A43' : '#7BE08F'
  const latexColor = light ? '#11231A' : '#ffffff'
  const guardColor = light ? '#138A43' : '#7BE08F'

  return (
    <span className="inline-flex items-center gap-3">
      <span className="shrink-0 rounded-xl flex items-center justify-center" style={tileStyle}>
        <DropIcon size={dims.icon} color={iconColor} />
      </span>
      <span className="font-display font-bold leading-none tracking-tight" style={{ fontSize: dims.text }}>
        <span style={{ color: latexColor }}>Latex</span> <span style={{ color: guardColor }}>Guard</span>
      </span>
    </span>
  )
}

export default BrandMark
