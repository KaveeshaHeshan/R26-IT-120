// src/components/ui/Button.jsx
//
// Forest/ground redesign button: "primary" (dark, for CSV export etc.) and
// "secondary" (white/bordered, for lighter actions). New component — existing
// pages keep their own plain <button> markup until their redesign phase.

const VARIANTS = {
  primary: 'bg-forest-900 text-white hover:bg-forest-800',
  secondary: 'bg-white text-[#11231A] border border-[#DDE4D8] hover:bg-[#F7FAF4]',
}

const Button = ({ variant = 'primary', icon, children, className = '', ...props }) => (
  <button
    className={`inline-flex items-center gap-2 rounded-xl px-[18px] py-3 text-sm font-semibold transition-colors whitespace-nowrap ${VARIANTS[variant] || VARIANTS.primary} ${className}`}
    {...props}
  >
    {icon}
    {children}
  </button>
)

export default Button
