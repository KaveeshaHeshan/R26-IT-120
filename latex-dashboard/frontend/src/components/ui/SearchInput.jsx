// src/components/ui/SearchInput.jsx

import { LuSearch } from 'react-icons/lu'

// `variant="v2"` opts into the forest/ground redesign's search field without
// touching the default look other (not-yet-redesigned) pages still use.
const SearchInput = ({ value, onChange, placeholder = 'Search…', className = '', variant = 'default' }) => {
  if (variant === 'v2') {
    return (
      <div className={`relative ${className}`}>
        <LuSearch size={16} className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-[#8FA093]" />
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          className="w-full h-[42px] rounded-xl border border-[#DDE4D8] bg-[#F7FAF4] pl-10 pr-3 text-sm text-[#11231A] placeholder:text-[#8FA093] focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition"
        />
      </div>
    )
  }

  return (
    <div className={`relative ${className}`}>
      <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-faint text-sm">
        ⌕
      </span>
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-lg border border-border bg-surface pl-8 pr-3 py-2 text-sm text-ink placeholder:text-faint focus:outline-none focus:ring-2 focus:ring-brand/20 focus:border-brand transition"
      />
    </div>
  )
}

export default SearchInput
