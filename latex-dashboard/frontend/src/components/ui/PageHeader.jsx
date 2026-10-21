// src/components/ui/PageHeader.jsx

// `variant="v2"` opts into the forest/ground redesign's large display title
// without touching the default look other (not-yet-redesigned) pages use.
const PageHeader = ({ title, description, breadcrumb, actions, variant = 'default' }) => {
  if (variant === 'v2') {
    return (
      <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
        <div>
          {breadcrumb && <div className="mb-1 text-sm font-medium text-[#5A6B5F]">{breadcrumb}</div>}
          <h1 className="font-display text-4xl font-bold tracking-[-0.02em] text-[#11231A]">{title}</h1>
          {description && <p className="mt-1 text-base text-[#5A6B5F]">{description}</p>}
        </div>
        {actions && <div className="flex items-center gap-2 shrink-0">{actions}</div>}
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between mb-6">
      <div>
        {breadcrumb && <div className="mb-1 text-xs font-medium text-muted">{breadcrumb}</div>}
        <h1 className="text-xl md:text-2xl font-semibold tracking-tight text-ink">{title}</h1>
        {description && <p className="mt-1 text-sm text-muted">{description}</p>}
      </div>
      {actions && <div className="flex items-center gap-2 shrink-0">{actions}</div>}
    </div>
  )
}

export default PageHeader
