import { useState, useRef, useEffect } from 'react'
import { ChevronLeft, ChevronRight, Calendar } from 'lucide-react'

export default function DatePickerInput({ value, onChange, placeholder='DD/MM/YYYY', disabled=false }) {
  const [open, setOpen] = useState(false)
  const containerRef = useRef(null)

  const todayDate = new Date()
  const todayY = todayDate.getFullYear()
  const todayM = todayDate.getMonth() + 1
  const todayD = todayDate.getDate()

  const parsed = (() => {
    if (!value) return null
    const parts = value.split('-')
    if (parts.length !== 3) return null
    const y = parseInt(parts[0], 10), m = parseInt(parts[1], 10), d = parseInt(parts[2], 10)
    if (!y || !m || !d) return null
    return { year:y, month:m, day:d }
  })()

  const [viewYear, setViewYear] = useState(() => parsed?.year ?? todayY)
  const [viewMonth, setViewMonth] = useState(() => parsed?.month ?? todayM)

  useEffect(() => {
    if (parsed) { setViewYear(parsed.year); setViewMonth(parsed.month) }
  }, [value])

  useEffect(() => {
    if (!open) return
    const handle = (e) => {
      if (containerRef.current && !containerRef.current.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', handle)
    return () => document.removeEventListener('mousedown', handle)
  }, [open])

  const display = parsed
    ? `${String(parsed.day).padStart(2,'0')}/${String(parsed.month).padStart(2,'0')}/${parsed.year}`
    : ''

  const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December']
  const DAYS = ['Su','Mo','Tu','We','Th','Fr','Sa']

  const daysInMonth = new Date(viewYear, viewMonth, 0).getDate()
  const firstDOW = new Date(viewYear, viewMonth - 1, 1).getDay()
  const cells = [...Array(firstDOW).fill(null), ...Array.from({ length:daysInMonth }, (_,i) => i+1)]

  const prevMonth = () => {
    if (viewMonth === 1) { setViewYear(y => y-1); setViewMonth(12) }
    else setViewMonth(m => m-1)
  }
  const nextMonth = () => {
    if (viewMonth === 12) { setViewYear(y => y+1); setViewMonth(1) }
    else setViewMonth(m => m+1)
  }
  const selectDay = (day) => {
    onChange(`${viewYear}-${String(viewMonth).padStart(2,'0')}-${String(day).padStart(2,'0')}`)
    setOpen(false)
  }
  const goToday = () => {
    setViewYear(todayY); setViewMonth(todayM)
    onChange(`${todayY}-${String(todayM).padStart(2,'0')}-${String(todayD).padStart(2,'0')}`)
    setOpen(false)
  }

  const isSelected = (day) => parsed && day===parsed.day && viewMonth===parsed.month && viewYear===parsed.year
  const isToday = (day) => day===todayD && viewMonth===todayM && viewYear===todayY

  return (
    <div ref={containerRef} className="relative">
      <button type="button" disabled={disabled} onClick={() => !disabled && setOpen(o => !o)}
        className="w-full px-4 py-2.5 rounded-lg text-sm border text-left flex items-center justify-between gap-2 focus:outline-none transition-all"
        style={{
          backgroundColor:'var(--surface-container-low)',
          borderColor: open ? '#2ab5a0' : 'var(--outline-variant)',
          color: display ? 'var(--on-surface)' : 'var(--on-surface-variant)',
          opacity: disabled ? 0.6 : 1,
          cursor: disabled ? 'default' : 'pointer',
        }}>
        <span className="flex-1">{display || placeholder}</span>
        <Calendar size={14} className="flex-shrink-0" style={{ color:'var(--on-surface-variant)' }} />
      </button>

      {open && (
        <div className="absolute top-full mt-2 left-0 z-50 rounded-xl p-3 w-72"
          style={{ backgroundColor:'var(--surface)', border:'1px solid var(--outline-variant)', boxShadow:'0 8px 32px rgba(0,0,0,0.12)' }}
          onMouseDown={e => e.stopPropagation()}>
          <div className="flex items-center justify-between mb-2">
            <button type="button" onClick={prevMonth} className="p-1.5 rounded-lg transition-colors"
              style={{ color:'var(--on-surface-variant)' }}
              onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
              onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
              <ChevronLeft size={14} />
            </button>
            <span className="text-sm font-semibold select-none" style={{ color:'var(--on-surface)' }}>
              {MONTHS[viewMonth-1]} {viewYear}
            </span>
            <button type="button" onClick={nextMonth} className="p-1.5 rounded-lg transition-colors"
              style={{ color:'var(--on-surface-variant)' }}
              onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
              onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
              <ChevronRight size={14} />
            </button>
          </div>

          <div className="grid grid-cols-7 mb-1">
            {DAYS.map(d => (
              <div key={d} className="text-center text-[10px] font-medium py-1" style={{ color:'var(--on-surface-variant)' }}>{d}</div>
            ))}
          </div>

          <div className="grid grid-cols-7">
            {cells.map((day, i) => day ? (
              <button key={i} type="button" onClick={() => selectDay(day)}
                className="h-8 w-full rounded-lg text-xs font-medium transition-all"
                style={{
                  backgroundColor: isSelected(day)?'#2ab5a0':isToday(day)?'rgba(42,181,160,0.12)':'transparent',
                  color: isSelected(day)?'#fff':isToday(day)?'#2ab5a0':'var(--on-surface)',
                }}>
                {day}
              </button>
            ) : <div key={i} />)}
          </div>

          <div className="mt-2 pt-2" style={{ borderTop:'1px solid var(--outline-variant)' }}>
            <button type="button" onClick={goToday} className="w-full text-xs py-1.5 rounded-lg font-medium"
              style={{ color:'#2ab5a0', backgroundColor:'rgba(42,181,160,0.08)' }}>
              Today
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
