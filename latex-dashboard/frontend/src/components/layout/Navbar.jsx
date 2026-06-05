// src/components/layout/Navbar.jsx

import { useState, useEffect } from 'react'
import { db } from '../../firebase/config'
import { ref, onValue, query, orderByChild, limitToLast } from 'firebase/database'

const Navbar = () => {

  const [latestVFA, setLatestVFA] = useState(null)

  // ── Fetch latest VFA real-time 
  useEffect(() => {
    const q = query(
      ref(db, 'predictions'),
      orderByChild('timestamp'),
      limitToLast(1)
    )
    const unsub = onValue(q, (snapshot) => {
      const data = snapshot.val()
      if (data) {
        const latest = Object.values(data)[0]
        setLatestVFA(latest)
      }
    })
    return () => unsub()
  }, [])

  // ── Render ──────────────────────────────────────────────────────────────────
  return (
    <nav className="h-14 bg-white/40 backdrop-blur-md border-b border-emerald-100/50 sticky top-0 z-[60] px-10 flex items-center justify-between">
      <div className="flex items-center gap-6">
         <div className="flex items-center gap-2">
            <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
            <span className="text-[9px] font-black uppercase tracking-[0.3em] text-[#052c14]/40">Active Sync</span>
         </div>
         <div className="h-4 w-[1px] bg-emerald-100"></div>
         {latestVFA && (
            <div className="flex items-center gap-4">
               <span className="text-[9px] font-black uppercase tracking-[0.2em] text-[#052c14]/20">Latest Vector</span>
               <span className="text-[10px] font-mono font-black text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded shadow-sm border border-emerald-100">
                  {latestVFA.vfa?.toFixed(4)} VFA
               </span>
            </div>
         )}
      </div>

      <div className="flex items-center gap-8">
         <div className="flex items-center gap-2">
            <span className="text-[8px] font-black uppercase tracking-[0.4em] text-[#052c14]/20">Kernel Status</span>
            <span className="text-[9px] font-black text-emerald-500 uppercase">Nominal</span>
         </div>
         <div className="flex items-center gap-3">
            <div className="text-right">
               <p className="text-[8px] font-black text-[#052c14]/20 uppercase tracking-widest leading-none">Global Latency</p>
               <p className="text-[10px] font-black text-[#052c14]/60 mt-0.5">24ms</p>
            </div>
            <div className="w-8 h-4 bg-emerald-50 rounded-full flex items-center px-1 border border-emerald-100 shadow-inner">
               <div className="w-2.5 h-2.5 bg-emerald-500 rounded-full"></div>
            </div>
         </div>
      </div>
    </nav>
  )
}

export default Navbar
