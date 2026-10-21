// src/components/ui/Card.jsx

// `variant="v2"` opts into the forest/ground redesign (rounded-[20px],
// border-line, 24px padding, font-display-ish header) without touching the
// default look other pages still rely on until their own redesign phase.
const Card = ({ title, subtitle, action, accent = false, padded = true, className = '', variant = 'default', children }) => {
  if (variant === 'v2') {
    return (
      <div className={`rounded-[20px] border border-line bg-white ${padded ? 'p-6' : ''} ${className}`}>
        {(title || action) && (
          <div className="flex flex-wrap items-start justify-between gap-3 mb-5">
            <div>
              {title && <h3 className="text-base font-bold text-[#11231A]">{title}</h3>}
              {subtitle && <p className="text-sm text-[#5A6B5F] mt-1">{subtitle}</p>}
            </div>
            {action && <div className="shrink-0">{action}</div>}
          </div>
        )}
        {children}
      </div>
    )
  }

  return (
    <div className={`rounded-xl border border-border bg-surface shadow-sm overflow-hidden ${className}`}>
      {accent && <div className="h-0.5 w-full bg-brand" />}
      {(title || action) && (
        <div className="flex items-start justify-between gap-4 px-5 pt-4 pb-3 border-b border-border">
          <div>
            {title && <h3 className="text-sm font-semibold text-ink">{title}</h3>}
            {subtitle && <p className="text-xs text-muted mt-0.5">{subtitle}</p>}
          </div>
          {action && <div className="shrink-0">{action}</div>}
        </div>
      )}
      <div className={padded ? 'p-5' : ''}>{children}</div>
    </div>
  )
}

export default Card
