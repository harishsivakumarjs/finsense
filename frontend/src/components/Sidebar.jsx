import { useState, useRef, useEffect } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Wallet, Receipt, CreditCard, TrendingUp, PieChart,
  Youtube, FileText, BarChart3, Users, Calculator, LogOut, ChevronLeft,
  ChevronRight, Shield, Settings, Moon, Sun, ClipboardList, X,
} from 'lucide-react'
import useStore from '../store/useStore'
import toast from 'react-hot-toast'
import Modal from './Modal'

const NAV_ITEMS = [
  { path: '/dashboard', label: 'Home', icon: LayoutDashboard },
  { path: '/income', label: 'Income', icon: Wallet },
  { path: '/expenses', label: 'Expenses', icon: Receipt },
  { path: '/debt', label: 'Debt', icon: CreditCard },
  { path: '/trading', label: 'Trading', icon: TrendingUp },
  { path: '/investments', label: 'Investments', icon: PieChart },
  { path: '/insurance', label: 'Insurance', icon: Shield },
  { path: '/creator', label: 'Creator', icon: Youtube },
  { path: '/tax', label: 'Tax', icon: FileText },
  { path: '/networth', label: 'Net Worth', icon: BarChart3 },
  { path: '/friends', label: 'Friends', icon: Users },
  { path: '/simulator', label: 'Simulator', icon: Calculator },
  { path: '/reports', label: 'Reports', icon: ClipboardList },
]

/* ── Settings Modal (lives here so sidebar can open it) ── */
function SettingsModal({ isOpen, onClose }) {
  const { user, theme, setTheme } = useStore()
  const [budget, setBudget] = useState(() => localStorage.getItem('finsense_monthly_budget') || '50000')

  const saveBudget = () => {
    localStorage.setItem('finsense_monthly_budget', budget)
    toast.success('Budget saved')
  }

  const inputStyle = { backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Quick Settings" size="md">
      <div className="space-y-5">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color:'var(--on-surface-variant)' }}>Profile</p>
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Name</label>
              <input defaultValue={user?.name||''} readOnly className="w-full px-4 py-2.5 rounded-lg text-sm border focus:outline-none opacity-70" style={inputStyle} />
            </div>
            <div>
              <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Email</label>
              <input defaultValue={user?.email||''} readOnly className="w-full px-4 py-2.5 rounded-lg text-sm border focus:outline-none opacity-70" style={inputStyle} />
            </div>
          </div>
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color:'var(--on-surface-variant)' }}>Appearance</p>
          <div className="flex items-center justify-between p-4 rounded-lg" style={{ backgroundColor:'var(--surface-container-low)', border:'1px solid var(--outline-variant)' }}>
            <div>
              <p className="text-sm font-medium" style={{ color:'var(--on-surface)' }}>Theme</p>
              <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{theme==='dark'?'Dark mode active':'Light mode active'}</p>
            </div>
            <button onClick={() => setTheme(theme==='dark'?'light':'dark')}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium"
              style={{ backgroundColor:'rgba(42,181,160,0.1)', color:'#2ab5a0', border:'1px solid rgba(42,181,160,0.2)' }}>
              {theme==='dark'?<><Sun size={14}/> Light</>:<><Moon size={14}/> Dark</>}
            </button>
          </div>
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color:'var(--on-surface-variant)' }}>Monthly Budget (₹)</p>
          <div className="flex gap-2">
            <input type="number" value={budget} onChange={e => setBudget(e.target.value)} className="flex-1 px-4 py-2.5 rounded-lg text-sm border focus:outline-none" style={inputStyle} />
            <button onClick={saveBudget} className="px-4 py-2.5 rounded-lg text-sm font-semibold" style={{ backgroundColor:'#2ab5a0', color:'#fff' }}>Save</button>
          </div>
        </div>
      </div>
    </Modal>
  )
}

/* ── Sidebar ── */
export default function Sidebar({ mobileOpen = false, onMobileClose = () => {} }) {
  const { user, logout, sidebarCollapsed, setSidebarCollapsed, theme, setTheme, avatar } = useStore()
  const navigate = useNavigate()

  const [showProfile, setShowProfile] = useState(false)
  const [profilePos, setProfilePos] = useState(null)
  const [showSettings, setShowSettings] = useState(false)
  const [isMobile, setIsMobile] = useState(() => window.innerWidth < 768)

  const userRef = useRef(null)
  const dropRef = useRef(null)

  useEffect(() => {
    const handler = () => setIsMobile(window.innerWidth < 768)
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])

  // Close mobile sidebar when escape pressed
  useEffect(() => {
    if (!mobileOpen) return
    const onKey = (e) => { if (e.key === 'Escape') onMobileClose() }
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [mobileOpen])

  // Click-outside + Escape to close profile dropdown
  useEffect(() => {
    if (!showProfile) return
    const handler = (e) => {
      if (
        dropRef.current && !dropRef.current.contains(e.target) &&
        userRef.current && !userRef.current.contains(e.target)
      ) {
        setShowProfile(false)
      }
    }
    const onKey = (e) => { if (e.key === 'Escape') setShowProfile(false) }
    document.addEventListener('mousedown', handler)
    document.addEventListener('keydown', onKey)
    return () => {
      document.removeEventListener('mousedown', handler)
      document.removeEventListener('keydown', onKey)
    }
  }, [showProfile])

  const toggleProfile = () => {
    if (showProfile) { setShowProfile(false); return }
    if (userRef.current) setProfilePos(userRef.current.getBoundingClientRect())
    setShowProfile(true)
  }

  const handleLogout = () => {
    setShowProfile(false)
    logout()
    toast.success('Logged out successfully')
    navigate('/login')
  }

  const initials = user?.name
    ? user.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)
    : 'U'

  const isCollapsed = !isMobile && sidebarCollapsed
  const w = isMobile ? 220 : (sidebarCollapsed ? 64 : 220)

  const dropStyle = profilePos
    ? isCollapsed
      ? {
          position: 'fixed',
          top: Math.max(8, Math.min(profilePos.top, window.innerHeight - 300)),
          left: profilePos.right + 8,
          width: 240,
          zIndex: 1000,
        }
      : {
          position: 'fixed',
          bottom: window.innerHeight - profilePos.top + 8,
          left: profilePos.left,
          width: 240,
          zIndex: 1000,
        }
    : { display: 'none' }

  return (
    <>
      {/* Mobile backdrop overlay */}
      {isMobile && mobileOpen && (
        <div
          className="fixed inset-0 z-30"
          style={{ backgroundColor: 'rgba(0,0,0,0.55)' }}
          onClick={onMobileClose}
        />
      )}

      <div
        className="fixed left-0 top-0 h-full flex flex-col z-40 overflow-hidden"
        style={{
          width: w,
          backgroundColor: '#0B1426',
          borderRight: '1px solid rgba(255,255,255,0.06)',
          transform: isMobile ? (mobileOpen ? 'translateX(0)' : 'translateX(-100%)') : 'translateX(0)',
          transition: 'transform 0.25s ease, width 0.2s ease',
        }}
      >
        {/* Header: Logo + toggle */}
        <div
          className="flex items-center flex-shrink-0"
          style={{
            borderBottom: '1px solid rgba(255,255,255,0.06)',
            height: 64,
            padding: isCollapsed ? '0 12px' : '0 16px',
            justifyContent: isCollapsed ? 'center' : 'space-between',
          }}
        >
          <div className="flex items-center gap-2.5 overflow-hidden">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center font-bold text-sm flex-shrink-0"
              style={{ backgroundColor: '#2AB5A0', color: '#ffffff' }}
            >
              F
            </div>
            {!isCollapsed && (
              <span
                className="whitespace-nowrap"
                style={{ fontFamily: 'var(--font-heading)', fontWeight: 700, fontSize: 18, color: '#ffffff' }}
              >
                FinSense
              </span>
            )}
          </div>

          {/* Desktop collapse button */}
          {!isMobile && !sidebarCollapsed && (
            <button
              onClick={() => setSidebarCollapsed(true)}
              className="p-1 rounded-lg transition-colors flex-shrink-0"
              style={{ color: '#8BA8C8' }}
              onMouseEnter={e => e.currentTarget.style.color = '#ffffff'}
              onMouseLeave={e => e.currentTarget.style.color = '#8BA8C8'}
              title="Collapse sidebar"
            >
              <ChevronLeft size={15} />
            </button>
          )}

          {/* Mobile close button */}
          {isMobile && (
            <button
              onClick={onMobileClose}
              className="p-1 rounded-lg transition-colors flex-shrink-0"
              style={{ color: '#8BA8C8' }}
              onMouseEnter={e => e.currentTarget.style.color = '#ffffff'}
              onMouseLeave={e => e.currentTarget.style.color = '#8BA8C8'}
            >
              <X size={16} />
            </button>
          )}
        </div>

        {/* Expand button when desktop collapsed */}
        {isCollapsed && (
          <button
            onClick={() => setSidebarCollapsed(false)}
            className="flex items-center justify-center py-2 transition-colors flex-shrink-0"
            style={{ color: '#8BA8C8' }}
            onMouseEnter={e => e.currentTarget.style.color = '#ffffff'}
            onMouseLeave={e => e.currentTarget.style.color = '#8BA8C8'}
            title="Expand sidebar"
          >
            <ChevronRight size={14} />
          </button>
        )}

        {/* Nav items */}
        <nav className="flex-1 overflow-y-auto" style={{ padding: isCollapsed ? '6px 6px' : '6px 8px' }}>
          <ul className="space-y-0.5">
            {NAV_ITEMS.map(({ path, label, icon: Icon }) => (
              <li key={path}>
                <NavLink
                  to={path}
                  onClick={isMobile ? onMobileClose : undefined}
                  title={isCollapsed ? label : undefined}
                  className={({ isActive }) =>
                    `flex items-center transition-all duration-150 relative
                    ${isCollapsed ? 'justify-center px-0 py-2.5 rounded-xl' : 'gap-2.5 py-2.5'}
                    ${isActive
                      ? (isCollapsed ? 'rounded-xl' : 'rounded-r-xl')
                      : 'rounded-xl'
                    }`
                  }
                  style={({ isActive }) => ({
                    fontSize: 13.5,
                    fontWeight: isActive ? 600 : 500,
                    fontFamily: 'var(--font-body)',
                    paddingLeft: isCollapsed ? 0 : undefined,
                    paddingRight: isCollapsed ? 0 : 12,
                    color: isActive ? '#5BDDC4' : '#8BA8C8',
                    backgroundColor: isActive
                      ? 'rgba(42,181,160,0.08)'
                      : 'transparent',
                  })}
                  onMouseEnter={(e) => {
                    const isActive = e.currentTarget.getAttribute('aria-current') === 'page'
                    if (!isActive) {
                      e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.04)'
                      e.currentTarget.style.color = '#ffffff'
                    }
                  }}
                  onMouseLeave={(e) => {
                    const isActive = e.currentTarget.getAttribute('aria-current') === 'page'
                    if (!isActive) {
                      e.currentTarget.style.backgroundColor = 'transparent'
                      e.currentTarget.style.color = '#8BA8C8'
                    }
                  }}
                >
                  {({ isActive }) => (
                    <>
                      {isActive && !isCollapsed && (
                        <div
                          className="absolute left-0 top-0 bottom-0 rounded-r-sm"
                          style={{ width: 3, backgroundColor: '#2AB5A0' }}
                        />
                      )}
                      <Icon size={17} strokeWidth={1.8} className={`flex-shrink-0 sidebar-nav-icon ${isCollapsed ? '' : 'ml-3'}`} />
                      {!isCollapsed && (
                        <span>{label}</span>
                      )}
                    </>
                  )}
                </NavLink>
              </li>
            ))}
          </ul>
        </nav>

        {/* User section */}
        <div
          className="flex-shrink-0"
          style={{ borderTop: '1px solid rgba(255,255,255,0.06)', padding: isCollapsed ? '8px 6px' : '8px' }}
        >
          <button
            ref={userRef}
            onClick={toggleProfile}
            title={isCollapsed ? (user?.name || 'Profile') : 'Profile & Settings'}
            className="flex items-center w-full rounded-lg px-2 py-2 transition-all duration-150"
            style={{
              justifyContent: isCollapsed ? 'center' : 'flex-start',
              gap: isCollapsed ? 0 : 10,
              backgroundColor: showProfile ? 'rgba(255,255,255,0.06)' : 'transparent',
            }}
            onMouseEnter={e => { if (!showProfile) e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.04)' }}
            onMouseLeave={e => { if (!showProfile) e.currentTarget.style.backgroundColor = 'transparent' }}
          >
            {avatar ? (
              <img
                src={avatar}
                alt="avatar"
                className="w-8 h-8 rounded-full object-cover flex-shrink-0"
                style={{ border: '1.5px solid rgba(62,207,178,0.4)' }}
              />
            ) : (
              <div
                className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0"
                style={{
                  background: 'linear-gradient(135deg, #3ECFB2, #5B9CF6)',
                  color: '#0F1117',
                  fontFamily: 'var(--font-heading)',
                  fontWeight: 600,
                  fontSize: 13,
                }}
              >
                {initials}
              </div>
            )}
            {!isCollapsed && (
              <div className="flex-1 min-w-0 text-left">
                <p className="text-sm font-semibold truncate leading-tight" style={{ color: '#ffffff', fontFamily: 'var(--font-body)' }}>
                  {user?.name || 'User'}
                </p>
                <p className="text-xs leading-tight truncate" style={{ color: '#8BA8C8', fontFamily: 'var(--font-body)' }}>
                  {user?.email || ''}
                </p>
              </div>
            )}
            {!isCollapsed && (
              <Settings size={14} style={{ color: '#8BA8C8', flexShrink: 0 }} />
            )}
          </button>
        </div>
      </div>

      {/* Profile dropdown — fixed so it escapes sidebar overflow:hidden */}
      {showProfile && profilePos && (
        <div
          ref={dropRef}
          style={{ ...dropStyle, backgroundColor:'#1a2535', border:'1px solid rgba(255,255,255,0.1)', borderRadius:12, boxShadow:'0 8px 32px rgba(0,0,0,0.4)' }}
        >
          <div className="px-4 py-4" style={{ borderBottom:'1px solid rgba(255,255,255,0.08)' }}>
            <div className="flex items-center gap-3">
              {avatar ? (
                <img
                  src={avatar}
                  alt="avatar"
                  className="w-10 h-10 rounded-full object-cover flex-shrink-0"
                  style={{ border: '2px solid rgba(42,181,160,0.4)' }}
                />
              ) : (
                <div className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 font-bold text-sm"
                  style={{ background:'linear-gradient(135deg, #2ab5a0, #4a8ed4)', color:'#fff' }}>
                  {initials}
                </div>
              )}
              <div className="min-w-0">
                <p className="text-sm font-semibold truncate" style={{ color:'#e2e8f0' }}>{user?.name || 'User'}</p>
                <p className="text-xs truncate" style={{ color:'rgba(255,255,255,0.5)' }}>{user?.email || ''}</p>
              </div>
            </div>
          </div>

          <div className="py-1">
            {[
              { label:'Settings', icon:Settings, onClick:() => { setShowProfile(false); navigate('/settings') } },
              { label:theme==='dark'?'Switch to Light':'Switch to Dark', icon:theme==='dark'?Sun:Moon, onClick:() => { setTheme(theme==='dark'?'light':'dark'); setShowProfile(false) } },
            ].map(({ label, icon:Icon, onClick }) => (
              <button key={label} onClick={onClick}
                className="w-full flex items-center gap-3 px-4 py-2.5 text-sm transition-colors"
                style={{ color:'rgba(255,255,255,0.65)' }}
                onMouseEnter={e => { e.currentTarget.style.backgroundColor='rgba(255,255,255,0.06)'; e.currentTarget.style.color='#e2e8f0' }}
                onMouseLeave={e => { e.currentTarget.style.backgroundColor='transparent'; e.currentTarget.style.color='rgba(255,255,255,0.65)' }}>
                <Icon size={15} />
                {label}
              </button>
            ))}
          </div>

          <div className="py-1" style={{ borderTop:'1px solid rgba(255,255,255,0.08)' }}>
            <button
              onClick={handleLogout}
              className="w-full flex items-center gap-3 px-4 py-2.5 text-sm transition-colors"
              style={{ color: '#FF4757' }}
              onMouseEnter={e => e.currentTarget.style.backgroundColor = 'rgba(255,71,87,0.08)'}
              onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}
            >
              <LogOut size={15} />
              Logout
            </button>
          </div>
        </div>
      )}

      <SettingsModal isOpen={showSettings} onClose={() => setShowSettings(false)} />
    </>
  )
}
