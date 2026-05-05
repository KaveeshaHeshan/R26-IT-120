// src/components/shared/LoadingSpinner.jsx

const LoadingSpinner = ({
  size    = 'md',     // 'sm' | 'md' | 'lg' | 'xl'
  message = '',
  fullScreen = false,
}) => {

  // ── Size config ─────────────────────────────────────────────────────────────
  const sizes = {
    sm: { spinner: 'w-5  h-5  border-2', text: 'text-xs' },
    md: { spinner: 'w-10 h-10 border-4', text: 'text-sm' },
    lg: { spinner: 'w-14 h-14 border-4', text: 'text-base' },
    xl: { spinner: 'w-20 h-20 border-4', text: 'text-lg'  },
  }

  const sz = sizes[size] || sizes.md

  // ── Spinner element ─────────────────────────────────────────────────────────
  const Spinner = () => (
    <div className="flex flex-col items-center gap-3">
      <div
        className={`${sz.spinner} border-[#1F3864]
                    border-t-transparent rounded-full animate-spin`}
      />
      {message && (
        <p className={`text-gray-500 font-medium ${sz.text}`}>
          {message}
        </p>
      )}
    </div>
  )

  // ── Full screen ─────────────────────────────────────────────────────────────
  if (fullScreen) {
    return (
      <div className="fixed inset-0 bg-white bg-opacity-80
                      backdrop-blur-sm flex items-center
                      justify-center z-50">
        <div className="bg-white rounded-2xl shadow-xl p-8
                        flex flex-col items-center gap-4">
          <div className="text-3xl">🌿</div>
          <div className={`${sizes.lg.spinner} border-[#1F3864]
                           border-t-transparent rounded-full
                           animate-spin`} />
          <div className="text-center">
            <p className="text-[#1F3864] font-bold text-sm">
              Latex VFA Dashboard
            </p>
            <p className="text-gray-400 text-xs mt-1">
              {message || 'Loading...'}
            </p>
          </div>
        </div>
      </div>
    )
  }

  // ── Inline ──────────────────────────────────────────────────────────────────
  return <Spinner />
}

export default LoadingSpinner