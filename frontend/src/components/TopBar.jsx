import { useState, useEffect, useRef } from 'react'
import { Bell, Search, Moon, Sun, X, TrendingUp, AlertCircle, Calendar, AlertTriangle } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import useStore from '../store/useStore'
import api from '../api/axios'
import { formatINR } from '../utils/format'

function useNotifications() {
  const [notifs, setNotifs] = useState([])
  const [unread, setUnread] = useState(0)

  const generate = async () => {
    try {
      const today = new Date()
      const generated = []

      const [loansR, cardsR, insuranceR] = await Promise.all([
        api.get('/loans').catch(() => ({ data: [] })),
        api.get('/loans/cards').catch(() => ({ data: [] })),
        api.get('/insurance').catch(() => ({ data: [] })),
      ])

      for (const loan of loansR.data || []) {
        if (!loan.is_active) continue
        const start = new Date(loan.start_date)
        const thisMonth = new Date(today.getFullYear(), today.getMonth(), start.getDate())
        const diff = Math.ceil((thisMonth - today) / 86400000)
        if (diff >= 0 && diff <= 7) {
          generated.push({
            id: `loan-${loan.id}`, icon: 'credit', color: '#d4932a',
            text: `${loan.loan_name} EMI of ${formatINR(loan.emi_amount)} due in ${diff} day${diff !== 1 ? 's' : ''}`,
            read: false,
          })
        }
      }

      for (const card of cardsR.data || []) {
        if (!card.due_date) continue
        const thisMonth = new Date(today.getFullYear(), today.getMonth(), card.due_date)
        const diff = Math.ceil((thisMonth - today) / 86400000)
        if (diff >= 0 && diff <= 7) {
          generated.push({
            id: `card-${card.id}`, icon: 'alert', color: '#ba1a1a',
            text: `${card.card_name} minimum due ${formatINR(card.minimum_due)} due in ${diff} day${diff !== 1 ? 's' : ''}`,
            read: false,
          })
        }
      }

      for (const policy of insuranceR.data || []) {
        if (!policy.is_active || !policy.next_due_date) continue
        const dueDate = new Date(policy.next_due_date)
        const diff = Math.ceil((dueDate - today) / 86400000)
        if (diff >= 0 && diff <= 30) {
          generated.push({
            id: `insurance-${policy.id}`, icon: 'calendar',
            color: diff <= 7 ? '#ba1a1a' : '#d4932a',
            text: `${policy.policy_name} renewal ${diff === 0 ? 'due today' : `due in ${diff} day${diff !== 1 ? 's' : ''}`} — ${formatINR(policy.annual_premium)}`,
            read: false,
          })
        }
      }

      const budget = parseInt(localStorage.getItem('finsense_monthly_budget') || '50000', 10)
      const expRes = await api.get('/expenses/summary', {
        params: { month: today.getMonth() + 1, year: today.getFullYear() },
      }).catch(() => ({ data: [] }))

      const totalSpent = (expRes.data || []).reduce((s, e) => s + parseFloat(e.total || 0), 0)
      if (totalSpent > budget) {
        generated.push({
          id: 'budget-exceeded', icon: 'warning', color: '#ba1a1a',
          text: `Monthly budget exceeded — spent ${formatINR(totalSpent)} of ${formatINR(budget)} limit`,
          read: false,
        })
      } else if (totalSpent > budget * 0.8) {
        generated.push({
          id: 'budget-warning', icon: 'warning', color: '#d4932a',
          text: `80% of monthly budget used — ${formatINR(budget - totalSpent)} remaining`,
          read: false,
        })
      }

      setNotifs(generated)
      setUnread(generated.filter(n => !n.read).length)
    } catch { /* silent */ }
  }

  return { notifs, setNotifs, unread, setUnread, generate }
}

function NotifIcon({ icon, color }) {
  if (icon === 'credit')   return <AlertCircle size={15} style={{ color }} />
  if (icon === 'alert')    return <Bell size={15} style={{ color }} />
  if (icon === 'warning')  return <AlertTriangle size={15} style={{ color }} />
  if (icon === 'calendar') return <Calendar size={15} style={{ color }} />
  return <TrendingUp size={15} style={{ color }} />
}

const TYPE_META = {
  Expense:    { color: '#ba1a1a', bg: 'rgba(186,26,26,0.1)' },
  Trade:      { color: '#006b5d', bg: 'rgba(0,107,93,0.1)' },
  Investment: { color: '#2ab5a0', bg: 'rgba(42,181,160,0.1)' },
  Income:     { color: '#4f5e80', bg: 'rgba(79,94,128,0.1)' },
  Friend:     { color: '#8b7fd4', bg: 'rgba(139,127,212,0.1)' },
}

export default function TopBar({ title }) {
  const { theme, setTheme } = useStore()
  const navigate = useNavigate()
  const { notifs, setNotifs, unread, setUnread, generate } = useNotifications()

  const [searchVal, setSearchVal] = useState('')
  const [searchFocused, setSearchFocused] = useState(false)
  const [showSearch, setShowSearch] = useState(false)
  const [searchResults, setSearchResults] = useState([])
  const [searching, setSearching] = useState(false)
  const [showBell, setShowBell] = useState(false)

  const bellRef = useRef(null)
  const searchRef = useRef(null)

  // Load notifications on mount so the red dot appears immediately
  useEffect(() => { generate() }, [])

  useEffect(() => {
    if (showBell) generate()
  }, [showBell])

  useEffect(() => {
    const handler = (e) => {
      if (bellRef.current && !bellRef.current.contains(e.target)) setShowBell(false)
      if (searchRef.current && !searchRef.current.contains(e.target)) {
        setShowSearch(false); setSearchFocused(false)
      }
    }
    const escape = (e) => { if (e.key === 'Escape') { setShowBell(false); setShowSearch(false) } }
    document.addEventListener('mousedown', handler)
    document.addEventListener('keydown', escape)
    return () => { document.removeEventListener('mousedown', handler); document.removeEventListener('keydown', escape) }
  }, [])

  const runSearch = async (q) => {
    if (!q.trim()) { setSearchResults([]); setShowSearch(false); return }
    setSearching(true); setShowSearch(true)
    try {
      const [expR, trdR, invR, incR, frR] = await Promise.all([
        api.get('/expenses', { params: { limit: 50 } }).catch(() => ({ data: [] })),
        api.get('/trades').catch(() => ({ data: [] })),
        api.get('/investments').catch(() => ({ data: [] })),
        api.get('/income').catch(() => ({ data: [] })),
        api.get('/friends').catch(() => ({ data: [] })),
      ])
      const ql = q.toLowerCase()
      const results = []
      ;(expR.data || []).filter(e => (e.description || '').toLowerCase().includes(ql) || e.category.toLowerCase().includes(ql))
        .slice(0, 3).forEach(e => results.push({ type: 'Expense', label: e.description || e.category, sub: formatINR(e.amount), path: '/expenses' }))
      ;(trdR.data || []).filter(t => t.scrip.toLowerCase().includes(ql))
        .slice(0, 3).forEach(t => results.push({ type: 'Trade', label: t.scrip, sub: t.trade_type, path: '/trading' }))
      ;(invR.data || []).filter(i => i.name.toLowerCase().includes(ql))
        .slice(0, 3).forEach(i => results.push({ type: 'Investment', label: i.name, sub: formatINR(i.current_value), path: '/investments' }))
      ;(incR.data || []).filter(i => (i.description || '').toLowerCase().includes(ql) || i.source_type.toLowerCase().includes(ql))
        .slice(0, 2).forEach(i => results.push({ type: 'Income', label: i.description || i.source_type, sub: formatINR(i.amount), path: '/income' }))
      ;(frR.data || []).filter(f => f.friend_name.toLowerCase().includes(ql))
        .slice(0, 2).forEach(f => results.push({ type: 'Friend', label: f.friend_name, sub: f.reason || '', path: '/friends' }))
      setSearchResults(results)
    } finally { setSearching(false) }
  }

  const markAllRead = () => { setNotifs(n => n.map(x => ({ ...x, read: true }))); setUnread(0) }
  const grouped = searchResults.reduce((acc, r) => { if (!acc[r.type]) acc[r.type] = []; acc[r.type].push(r); return acc }, {})

  return (
    <div
      className="flex items-center justify-between px-6 z-30 flex-shrink-0"
      style={{
        backgroundColor: 'var(--surface)',
        borderBottom: '1px solid var(--outline-variant)',
        height: 64,
        boxShadow: 'var(--shadow-card)',
      }}
    >
      <h1 className="text-lg font-semibold" style={{ color: 'var(--on-surface)', fontFamily: 'var(--font-body)' }}>
        {title}
      </h1>

      <div className="flex items-center gap-2">
        {/* Search */}
        <div className="relative" ref={searchRef}>
          <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: 'var(--on-surface-variant)' }} />
          <input
            type="text"
            placeholder="Search..."
            value={searchVal}
            onChange={(e) => { setSearchVal(e.target.value); runSearch(e.target.value) }}
            onFocus={() => { setSearchFocused(true); if (searchVal) setShowSearch(true) }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') runSearch(searchVal)
              if (e.key === 'Escape') { setShowSearch(false); e.currentTarget.blur() }
            }}
            className="pl-9 pr-4 py-2 rounded-lg text-sm focus:outline-none transition-all"
            style={{
              width: searchFocused ? 280 : 220,
              backgroundColor: 'var(--surface-container-low)',
              border: `1px solid ${searchFocused ? 'var(--primary-container)' : 'var(--outline-variant)'}`,
              color: 'var(--on-surface)',
              boxShadow: searchFocused ? '0 0 0 3px rgba(42,181,160,0.12)' : 'none',
              transition: 'width 0.2s, border-color 0.15s, box-shadow 0.15s',
            }}
          />
          {showSearch && (
            <div className="absolute top-full mt-2 right-0 rounded-xl border z-50 overflow-hidden"
              style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--outline-variant)', boxShadow: 'var(--shadow-md)', minWidth: 300 }}>
              {searching ? (
                <div className="px-4 py-5 text-sm text-center" style={{ color: 'var(--on-surface-variant)' }}>Searching…</div>
              ) : searchResults.length === 0 ? (
                <div className="px-4 py-5 text-sm text-center" style={{ color: 'var(--on-surface-variant)' }}>
                  No results for <span style={{ color: 'var(--on-surface)' }}>"{searchVal}"</span>
                </div>
              ) : (
                Object.entries(grouped).map(([type, items]) => {
                  const meta = TYPE_META[type] || { color: '#6c7a76', bg: 'rgba(108,122,118,0.1)' }
                  return (
                    <div key={type}>
                      <div className="px-4 py-2" style={{ borderBottom: '1px solid var(--outline-variant)', backgroundColor: 'var(--surface-container-low)' }}>
                        <span className="text-xs font-bold uppercase tracking-wider" style={{ color: meta.color }}>{type}s</span>
                      </div>
                      {items.map((r, i) => (
                        <button key={i} onClick={() => { navigate(r.path); setShowSearch(false); setSearchVal('') }}
                          className="w-full flex items-center justify-between px-4 py-2.5 text-left transition-colors"
                          style={{ borderBottom: i < items.length - 1 ? '1px solid var(--outline-variant)' : 'none' }}
                          onMouseEnter={e => e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
                          onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
                        >
                          <div className="flex items-center gap-2.5">
                            <div className="w-1.5 h-1.5 rounded-full" style={{ backgroundColor: meta.color }} />
                            <span className="text-sm" style={{ color: 'var(--on-surface)' }}>{r.label}</span>
                          </div>
                          <span className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>{r.sub}</span>
                        </button>
                      ))}
                    </div>
                  )
                })
              )}
            </div>
          )}
        </div>

        {/* Bell */}
        <div className="relative" ref={bellRef}>
          <button onClick={() => setShowBell(!showBell)}
            className="relative p-2 rounded-lg transition-colors"
            style={{ color: 'var(--on-surface-variant)' }}
            onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'; e.currentTarget.style.color = 'var(--on-surface)' }}
            onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'var(--on-surface-variant)' }}
          >
            <Bell size={18} />
            {unread > 0 && (
              <span className="absolute top-1 right-1 w-4 h-4 rounded-full text-xs font-bold flex items-center justify-center"
                style={{ backgroundColor: 'var(--error)', color: '#fff', fontSize: 9 }}>
                {unread > 9 ? '9+' : unread}
              </span>
            )}
          </button>

          {showBell && (
            <div className="absolute right-0 top-full mt-2 w-96 rounded-xl border z-50 overflow-hidden"
              style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--outline-variant)', boxShadow: 'var(--shadow-md)' }}>
              <div className="flex items-center justify-between px-4 py-3" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
                <span className="text-sm font-semibold" style={{ color: 'var(--on-surface)' }}>Notifications</span>
                <div className="flex items-center gap-2">
                  {unread > 0 && (
                    <button onClick={markAllRead} className="text-xs transition-colors" style={{ color: 'var(--primary-container)' }}>
                      Mark all read
                    </button>
                  )}
                  <button onClick={() => setShowBell(false)} style={{ color: 'var(--on-surface-variant)' }}>
                    <X size={14} />
                  </button>
                </div>
              </div>
              <div className="max-h-96 overflow-y-auto">
                {notifs.length === 0 ? (
                  <div className="py-10 text-center">
                    <Bell size={24} className="mx-auto mb-3" style={{ color: 'var(--on-surface-variant)' }} />
                    <p className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>No new notifications</p>
                  </div>
                ) : notifs.map(n => (
                  <div key={n.id}
                    onClick={() => { setNotifs(prev => prev.map(x => x.id === n.id ? { ...x, read: true } : x)); setUnread(u => Math.max(0, u - (n.read ? 0 : 1))) }}
                    className="flex items-start gap-3 px-4 py-3 cursor-pointer transition-colors"
                    style={{ borderBottom: '1px solid var(--outline-variant)', backgroundColor: n.read ? undefined : `${n.color}0a` }}
                    onMouseEnter={e => e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor = n.read ? 'transparent' : `${n.color}0a`}
                  >
                    <div className="mt-0.5 p-1.5 rounded-lg flex-shrink-0" style={{ backgroundColor: `${n.color}18` }}>
                      <NotifIcon icon={n.icon} color={n.color} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm leading-snug" style={{ color: 'var(--on-surface)' }}>{n.text}</p>
                      <p className="text-xs mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>Just now</p>
                    </div>
                    {!n.read && <div className="w-2 h-2 rounded-full mt-1.5 flex-shrink-0" style={{ backgroundColor: 'var(--info)' }} />}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Theme toggle */}
        <button
          onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          className="p-2 rounded-lg transition-colors"
          title={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          style={{ color: 'var(--on-surface-variant)' }}
          onMouseEnter={e => { e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'; e.currentTarget.style.color = 'var(--on-surface)' }}
          onMouseLeave={e => { e.currentTarget.style.backgroundColor = 'transparent'; e.currentTarget.style.color = 'var(--on-surface-variant)' }}
        >
          {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>

      </div>
    </div>
  )
}
