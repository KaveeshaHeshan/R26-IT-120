// src/components/layout/Navbar.jsx

import { useState, useEffect, useMemo, useRef } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { LuSearch } from 'react-icons/lu'
import { db } from '../../firebase/config'
import { ref, onValue, query, orderByChild, limitToLast } from 'firebase/database'
import useUsers from '../../hooks/useUsers'

const Navbar = () => {
  const navigate = useNavigate()
  const location = useLocation()
  const { farmers } = useUsers()

  const [latestVFA, setLatestVFA] = useState(null)
  const [term, setTerm] = useState('')
  const [open, setOpen] = useState(false)
  const boxRef = useRef(null)

  useEffect(() => {
    const q = query(ref(db, 'predictions'), orderByChild('timestamp'), limitToLast(1))
    const unsub = onValue(q, (snapshot) => {
      const data = snapshot.val()
      if (data) setLatestVFA(Object.values(data)[0])
    })
    return () => unsub()
  }, [])

  useEffect(() => {
    const onClick = (e) => {
      if (boxRef.current && !boxRef.current.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', onClick)
    return () => document.removeEventListener('mousedown', onClick)
  }, [])

  // Reset the search box when the route changes (render-phase state sync)
  const [lastPath, setLastPath] = useState(location.pathname)
  if (location.pathname !== lastPath) {
    setLastPath(location.pathname)
    setTerm('')
    setOpen(false)
  }

  const results = useMemo(() => {
    const t = term.trim().toLowerCase()
    if (t.length < 2) return []
    return farmers
      .filter((f) =>
        [f.name, f.district, f.address, f.nic].some((v) =>
          String(v || '').toLowerCase().includes(t),
        ),
      )
      .slice(0, 8)
  }, [term, farmers])

  const goTo = (uid) => {
    setOpen(false)
    setTerm('')
    navigate(`/farmers/${uid}`)
  }

  return (
    <header className="bg-[#FAFBF8] border-b border-line font-[Figtree] px-10 py-[18px] flex flex-wrap items-center justify-between gap-4">
      {/* Global farmer search */}
      <div className="relative flex-[1_1_280px] max-w-[460px]" ref={boxRef}>
        <LuSearch
          size={16}
          className="pointer-events-none absolute left-4 top-1/2 -translate-y-1/2 text-[#8FA093]"
        />
        <input
          type="text"
          value={term}
          onChange={(e) => {
            setTerm(e.target.value)
            setOpen(true)
          }}
          onFocus={() => setOpen(true)}
          placeholder="Search farmers by name, district, NIC"
          className="w-full h-[46px] rounded-[14px] border border-[#DDE4D8] bg-white pl-10 pr-4 text-sm text-[#11231A] placeholder:text-[#8FA093] focus:outline-none focus:ring-2 focus:ring-brand-500/20 focus:border-brand-500 transition"
        />
        {open && term.trim().length >= 2 && (
          <div className="absolute left-0 right-0 mt-1 max-h-80 overflow-y-auto rounded-xl border border-[#DDE4D8] bg-white shadow-lg py-1 z-50">
            {results.length === 0 ? (
              <p className="px-3 py-2 text-xs text-[#5A6B5F]">No matching farmers</p>
            ) : (
              results.map((f) => (
                <button
                  key={f.uid}
                  onClick={() => goTo(f.uid)}
                  className="w-full text-left px-3 py-2 hover:bg-[#EAF6EE] transition-colors"
                >
                  <p className="text-sm text-[#11231A]">{f.name || f.uid}</p>
                  <p className="text-xs text-[#5A6B5F]">
                    {f.district || '—'}{f.nic ? ` · ${f.nic}` : ''}
                  </p>
                </button>
              ))
            )}
          </div>
        )}
      </div>

      {latestVFA?.vfa != null && (
        <div className="flex items-center gap-2 rounded-full border border-[#C7E8D0] bg-[#E8F6EC] px-4 py-[9px] text-sm text-[#1F4D30]">
          <span>Latest VFA</span>
          <span className="w-2 h-2 rounded-full bg-brand-500" />
          <span className="font-bold text-[15px] text-brand-700 tabular-nums">
            {Number(latestVFA.vfa).toFixed(4)}
          </span>
        </div>
      )}
    </header>
  )
}

export default Navbar
