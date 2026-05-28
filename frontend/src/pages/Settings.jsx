import { useState, useRef } from 'react'
import { User, Lock, Bell, Palette, Shield, LogOut, ChevronRight, Sun, Moon, Camera, Phone, Check, AlertTriangle, X } from 'lucide-react'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'
import api from '../api/axios'
import useStore from '../store/useStore'

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

const NAV = [
  { id:'profile',      label:'Profile',       icon:User },
  { id:'security',     label:'Security',      icon:Lock },
  { id:'notifications',label:'Notifications', icon:Bell },
  { id:'appearance',   label:'Appearance',    icon:Palette },
  { id:'data',         label:'Data & Privacy',icon:Shield },
]

export default function Settings() {
  const { user, setUser, theme, setTheme, logout, setAvatar: setStoreAvatar } = useStore()
  const navigate = useNavigate()
  const [activeSection, setActiveSection] = useState('profile')
  const [passwords, setPasswords] = useState({ current:'', next:'', confirm:'' })
  const [clearInput, setClearInput] = useState('')
  const [deleteInput, setDeleteInput] = useState('')
  const [showClearPopup, setShowClearPopup] = useState(false)
  const [showDeletePopup, setShowDeletePopup] = useState(false)
  const [notifToggles, setNotifToggles] = useState({
    emi: true, insurance: true, budget: false, weekly: true, milestones: true,
  })
  const [avatar, setAvatar] = useState(() => user?.photo || localStorage.getItem('finsense_avatar') || null)
  const [mobile, setMobile] = useState(user?.mobile || '')
  const fileInputRef = useRef(null)

  const handleProfileSave = async () => {
    try {
      const res = await api.put('/auth/profile', { mobile })
      setUser(res.data)
      toast.success('Profile updated')
    } catch (e) {
      toast.error(e?.response?.data?.detail || 'Failed to update profile')
    }
  }

  const handlePasswordChange = async () => {
    if (!passwords.current || !passwords.next) return toast.error('Fill all password fields')
    if (passwords.next !== passwords.confirm) return toast.error('Passwords do not match')
    if (passwords.next.length < 6) return toast.error('Password must be at least 6 characters')
    try {
      await api.put('/auth/password', { current_password: passwords.current, new_password: passwords.next })
      toast.success('Password updated')
      setPasswords({ current:'', next:'', confirm:'' })
    } catch (e) {
      toast.error(e?.response?.data?.detail || 'Failed to update password')
    }
  }

  const handlePhotoUpload = (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (!file.type.startsWith('image/')) { toast.error('Please select an image file'); return }
    if (file.size > 2 * 1024 * 1024) { toast.error('Image must be under 2MB'); return }
    const reader = new FileReader()
    reader.onload = async (ev) => {
      const dataUrl = ev.target.result
      setAvatar(dataUrl)
      setStoreAvatar(dataUrl)
      try {
        const res = await api.put('/auth/profile', { photo: dataUrl })
        setUser(res.data)
        toast.success('Photo updated')
      } catch {
        toast.error('Photo saved locally but could not sync to server')
      }
    }
    reader.readAsDataURL(file)
  }

  const handleExportJSON = async () => {
    const tid = toast.loading('Preparing export…')
    try {
      const results = await Promise.allSettled([
        api.get('/expenses'), api.get('/income'), api.get('/investments'), api.get('/loans'),
      ])
      const [expenses, income, investments, loans] = results.map(r => r.status === 'fulfilled' ? r.value.data : [])
      const data = { exported_at: new Date().toISOString(), expenses, income, investments, loans }
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url; a.download = `finsense_export_${new Date().toISOString().split('T')[0]}.json`
      document.body.appendChild(a); a.click(); document.body.removeChild(a)
      URL.revokeObjectURL(url)
      toast.dismiss(tid); toast.success('JSON exported')
    } catch { toast.dismiss(tid); toast.error('Export failed') }
  }

  const handleExportCSV = async () => {
    const tid = toast.loading('Preparing CSV…')
    try {
      const [expR, incR] = await Promise.allSettled([api.get('/expenses'), api.get('/income')])
      const expenses = expR.status === 'fulfilled' ? expR.value.data : []
      const income = incR.status === 'fulfilled' ? incR.value.data : []
      const q = (v) => `"${String(v ?? '').replace(/"/g, '""')}"`
      const rows = [['date','type','category','description','amount']]
      expenses.forEach(e => rows.push([e.date, 'expense', e.category||'', e.description||'', e.amount]))
      income.forEach(i => rows.push([i.date, 'income', i.source||'', i.description||'', i.amount]))
      rows.sort((a, b) => (b[0] > a[0] ? 1 : -1))
      const csv = rows.map(r => r.map(q).join(',')).join('\n')
      const blob = new Blob([csv], { type: 'text/csv' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url; a.download = `finsense_transactions_${new Date().toISOString().split('T')[0]}.csv`
      document.body.appendChild(a); a.click(); document.body.removeChild(a)
      URL.revokeObjectURL(url)
      toast.dismiss(tid); toast.success('CSV exported')
    } catch { toast.dismiss(tid); toast.error('Export failed') }
  }

  const handleClearData = async () => {
    if (clearInput !== 'clear all data') return
    try {
      await api.delete('/auth/data')
      localStorage.removeItem('finsense_milestones')
      toast.success('All data cleared')
      setShowClearPopup(false)
      setClearInput('')
    } catch {
      toast.error('Failed to clear data')
    }
  }

  const handleDeleteAccount = async () => {
    if (deleteInput !== 'delete my account') return
    try {
      await api.delete('/auth/account')
      logout()
      navigate('/login')
      toast.success('Account deleted')
    } catch {
      toast.error('Failed to delete account')
    }
  }

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const initials = user?.name
    ? user.name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0,2)
    : '?'

  return (
    <div className="p-4 md:p-6" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="mb-5 md:mb-6">
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Settings</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Manage your account and preferences</p>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 md:gap-6">
          {/* Left Nav */}
          <div className="w-full sm:w-52 flex-shrink-0 space-y-1">
            {NAV.map(({ id, label, icon:Icon }) => (
              <button key={id} onClick={() => setActiveSection(id)}
                className="w-full flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-all text-left"
                style={{
                  backgroundColor: activeSection===id ? 'rgba(42,181,160,0.1)' : 'transparent',
                  color: activeSection===id ? '#2ab5a0' : 'var(--on-surface-variant)',
                }}
                onMouseEnter={e => { if(activeSection!==id) e.currentTarget.style.backgroundColor='var(--surface-container-low)' }}
                onMouseLeave={e => { if(activeSection!==id) e.currentTarget.style.backgroundColor='transparent' }}>
                <Icon size={16} />
                {label}
                {activeSection===id && <ChevronRight size={14} className="ml-auto" />}
              </button>
            ))}

            <div className="pt-3 mt-3" style={{ borderTop:'1px solid var(--outline-variant)' }}>
              <button onClick={handleLogout}
                className="w-full flex items-center gap-3 px-4 py-2.5 rounded-lg text-sm font-medium transition-all text-left"
                style={{ color:'var(--error)' }}
                onMouseEnter={e => e.currentTarget.style.backgroundColor='rgba(186,26,26,0.06)'}
                onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                <LogOut size={16} /> Sign Out
              </button>
            </div>
          </div>

          {/* Right Content */}
          <div className="flex-1 space-y-5">

            {/* PROFILE */}
            {activeSection === 'profile' && (
              <>
                <Card className="p-6">
                  <h2 className="text-base font-semibold mb-5" style={{ color:'var(--on-surface)' }}>Profile Information</h2>

                  {/* Avatar with camera FAB */}
                  <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={handlePhotoUpload} />
                  <div className="flex items-start gap-5 mb-6">
                    <div className="relative flex-shrink-0">
                      {avatar ? (
                        <img src={avatar} alt="avatar" className="w-20 h-20 rounded-full object-cover"
                          style={{ border:'3px solid #2ab5a0' }} />
                      ) : (
                        <div className="w-20 h-20 rounded-full flex items-center justify-center text-2xl font-bold"
                          style={{ backgroundColor:'rgba(42,181,160,0.15)', color:'#2ab5a0', border:'3px solid #2ab5a0' }}>
                          {initials}
                        </div>
                      )}
                      <button className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full flex items-center justify-center transition-colors"
                        style={{ backgroundColor:'#2ab5a0', color:'white', border:'2px solid white' }}
                        onClick={() => fileInputRef.current?.click()}>
                        <Camera size={12} />
                      </button>
                    </div>
                    <div className="pt-1">
                      <p className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>{user?.name || '—'}</p>
                      <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{user?.email || '—'}</p>
                    </div>
                  </div>

                  {/* Fields */}
                  <div className="space-y-4">
                    <div>
                      <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Full Name</label>
                      <input defaultValue={user?.name||''} placeholder="Your full name" readOnly
                        className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border"
                        style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)', cursor:'default' }} />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Email Address</label>
                      <div className="relative">
                        <input defaultValue={user?.email||''} placeholder="your@email.com" readOnly
                          className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border pr-24"
                          style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)', cursor:'default' }} />
                        <span className="absolute right-3 top-1/2 -translate-y-1/2 flex items-center gap-1 text-xs font-bold px-2 py-0.5 rounded-full"
                          style={{ backgroundColor:'rgba(0,107,93,0.12)', color:'var(--positive)' }}>
                          <Check size={10} /> VERIFIED
                        </span>
                      </div>
                    </div>
                    <div>
                      <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Mobile Number</label>
                      <div className="flex">
                        <div className="flex items-center px-3 rounded-l-lg border border-r-0 flex-shrink-0"
                          style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
                          <Phone size={13} className="mr-1" />
                          <span className="text-sm font-mono">+91</span>
                        </div>
                        <input value={mobile} onChange={e => setMobile(e.target.value)} placeholder="98765 43210" type="tel"
                          className="flex-1 px-4 py-2.5 rounded-r-lg text-sm focus:outline-none border"
                          style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
                      </div>
                    </div>
                    <button onClick={handleProfileSave}
                      className="px-5 py-2.5 rounded-lg text-sm font-semibold"
                      style={{ backgroundColor:'#2ab5a0', color:'#fff' }}>
                      Save Profile
                    </button>
                  </div>

                  {user?.name && (
                    <p className="text-xs mt-4" style={{ color:'var(--on-surface-variant)' }}>
                      To update your name or email, contact support.
                    </p>
                  )}
                </Card>

              </>
            )}

            {/* SECURITY */}
            {activeSection === 'security' && (
              <Card className="p-6">
                <h2 className="text-base font-semibold mb-5" style={{ color:'var(--on-surface)' }}>Change Password</h2>
                <div className="space-y-4 max-w-sm">
                  {[
                    { label:'Current Password', key:'current', placeholder:'Enter current password' },
                    { label:'New Password', key:'next', placeholder:'Enter new password' },
                    { label:'Confirm New Password', key:'confirm', placeholder:'Confirm new password' },
                  ].map(({ label, key, placeholder }) => (
                    <div key={key}>
                      <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>{label}</label>
                      <input type="password" placeholder={placeholder} value={passwords[key]}
                        onChange={e => setPasswords(p => ({ ...p, [key]:e.target.value }))}
                        className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border"
                        style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
                    </div>
                  ))}
                  <button onClick={handlePasswordChange}
                    className="px-5 py-2.5 rounded-lg text-sm font-semibold"
                    style={{ backgroundColor:'#2ab5a0', color:'#fff' }}>
                    Update Password
                  </button>
                </div>

                <div className="mt-8 pt-6" style={{ borderTop:'1px solid var(--outline-variant)' }}>
                  <h3 className="text-sm font-semibold mb-3" style={{ color:'var(--on-surface)' }}>Active Sessions</h3>
                  <div className="flex items-center justify-between p-4 rounded-lg" style={{ backgroundColor:'var(--surface-container-low)' }}>
                    <div>
                      <p className="text-sm font-medium" style={{ color:'var(--on-surface)' }}>Current session</p>
                      <p className="text-xs" style={{ color:'var(--on-surface-variant)' }}>Web browser · Active now</p>
                    </div>
                    <span className="text-xs font-semibold px-2 py-0.5 rounded-full" style={{ backgroundColor:'rgba(0,107,93,0.1)', color:'var(--positive)' }}>Active</span>
                  </div>
                </div>
              </Card>
            )}

            {/* NOTIFICATIONS */}
            {activeSection === 'notifications' && (
              <Card className="p-6">
                <h2 className="text-base font-semibold mb-5" style={{ color:'var(--on-surface)' }}>Notification Preferences</h2>
                <div className="space-y-1">
                  {[
                    { key:'emi',        label:'EMI & Loan Reminders',  desc:'Get notified before EMI due dates' },
                    { key:'insurance',  label:'Insurance Renewals',     desc:'Alerts for upcoming policy renewals' },
                    { key:'budget',     label:'Budget Alerts',          desc:'Notify when spending exceeds budget' },
                    { key:'weekly',     label:'Weekly Summary',         desc:'Weekly financial health digest' },
                    { key:'milestones', label:'Goal Milestones',        desc:'Celebrate when you hit net worth milestones' },
                  ].map(({ key, label, desc }) => (
                    <div key={key} className="flex items-center justify-between py-3" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                      <div>
                        <p className="text-sm font-medium" style={{ color:'var(--on-surface)' }}>{label}</p>
                        <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{desc}</p>
                      </div>
                      <button onClick={() => setNotifToggles(t => ({ ...t, [key]:!t[key] }))}
                        className="relative w-10 h-5 rounded-full transition-colors flex-shrink-0"
                        style={{ backgroundColor:notifToggles[key]?'#2ab5a0':'var(--outline-variant)' }}>
                        <span className="absolute top-0.5 w-4 h-4 rounded-full bg-white transition-all" style={{ left:notifToggles[key]?'22px':'2px' }} />
                      </button>
                    </div>
                  ))}
                </div>
              </Card>
            )}

            {/* APPEARANCE */}
            {activeSection === 'appearance' && (
              <Card className="p-6">
                <h2 className="text-base font-semibold mb-1" style={{ color:'var(--on-surface)' }}>Appearance</h2>
                <p className="text-sm mb-5" style={{ color:'var(--on-surface-variant)' }}>Choose your preferred color scheme</p>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {[
                    { id:'light', label:'Light Mode', desc:'Clean and bright interface', icon:Sun, color:'#d4932a',
                      preview: { bg:'#f7f9fc', card:'#ffffff', text:'#191c1e', accent:'#2ab5a0' } },
                    { id:'dark', label:'Dark Mode', desc:'Easy on the eyes at night', icon:Moon, color:'#4a8ed4',
                      preview: { bg:'#0f1923', card:'#1a2535', text:'#e2e8f0', accent:'#2ab5a0' } },
                  ].map(({ id, label, desc, icon:Icon, color, preview }) => {
                    const active = theme === id
                    return (
                      <button key={id} onClick={() => setTheme(id)}
                        className="p-4 rounded-xl text-left transition-all overflow-hidden"
                        style={{ border:`2px solid ${active?color:'var(--outline-variant)'}`, backgroundColor:active?`${color}06`:'var(--surface)' }}>
                        {/* Mini preview */}
                        <div className="w-full h-20 rounded-lg mb-3 p-2 overflow-hidden" style={{ backgroundColor:preview.bg }}>
                          <div className="h-3 rounded mb-1.5" style={{ backgroundColor:preview.card, width:'70%' }} />
                          <div className="h-2 rounded mb-1" style={{ backgroundColor:preview.accent, width:'40%' }} />
                          <div className="h-2 rounded" style={{ backgroundColor:preview.card, width:'55%' }} />
                        </div>
                        <div className="flex items-center gap-2 mb-1">
                          <Icon size={15} style={{ color }} />
                          <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{label}</span>
                          {active && <span className="text-xs font-semibold px-1.5 py-0.5 rounded-full ml-auto" style={{ backgroundColor:`${color}15`, color }}>Active</span>}
                        </div>
                        <p className="text-xs" style={{ color:'var(--on-surface-variant)' }}>{desc}</p>
                      </button>
                    )
                  })}
                </div>
              </Card>
            )}

            {/* DATA & PRIVACY */}
            {activeSection === 'data' && (
              <>
                <Card className="p-6">
                  <h2 className="text-base font-semibold mb-5" style={{ color:'var(--on-surface)' }}>Data Export</h2>
                  <p className="text-sm mb-4" style={{ color:'var(--on-surface-variant)' }}>Download a copy of all your financial data.</p>
                  <div className="flex gap-3">
                    <button onClick={handleExportJSON}
                      className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium border transition-colors"
                      style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}
                      onMouseEnter={e => { e.currentTarget.style.borderColor='var(--primary)'; e.currentTarget.style.color='var(--primary)' }}
                      onMouseLeave={e => { e.currentTarget.style.borderColor='var(--outline-variant)'; e.currentTarget.style.color='var(--on-surface-variant)' }}>
                      Export as JSON
                    </button>
                    <button onClick={handleExportCSV}
                      className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-medium border transition-colors"
                      style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}
                      onMouseEnter={e => { e.currentTarget.style.borderColor='var(--primary)'; e.currentTarget.style.color='var(--primary)' }}
                      onMouseLeave={e => { e.currentTarget.style.borderColor='var(--outline-variant)'; e.currentTarget.style.color='var(--on-surface-variant)' }}>
                      Export as CSV
                    </button>
                  </div>
                </Card>

                {/* Danger Zone */}
                <Card className="p-6" style={{ borderLeft:'4px solid #ba1a1a' }}>
                  <h2 className="text-base font-semibold mb-1" style={{ color:'var(--error)' }}>Danger Zone</h2>
                  <p className="text-sm mb-5" style={{ color:'var(--on-surface-variant)' }}>Irreversible actions. Proceed with caution.</p>

                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 rounded-lg" style={{ backgroundColor:'rgba(186,26,26,0.04)', border:'1px solid rgba(186,26,26,0.15)' }}>
                      <div>
                        <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Clear All Data</p>
                        <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Delete all transactions, loans, investments — keeps your account</p>
                      </div>
                      <button onClick={() => { setClearInput(''); setShowClearPopup(true) }}
                        className="px-4 py-2 rounded-lg text-xs font-semibold"
                        style={{ backgroundColor:'rgba(186,26,26,0.1)', color:'var(--error)', border:'1px solid rgba(186,26,26,0.2)' }}>
                        Clear Data
                      </button>
                    </div>

                    <div className="flex items-center justify-between p-4 rounded-lg" style={{ backgroundColor:'rgba(186,26,26,0.04)', border:'1px solid rgba(186,26,26,0.15)' }}>
                      <div>
                        <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Delete Account</p>
                        <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Permanently delete your account and all data</p>
                      </div>
                      <button onClick={() => { setDeleteInput(''); setShowDeletePopup(true) }}
                        className="px-4 py-2 rounded-lg text-xs font-semibold"
                        style={{ backgroundColor:'#ba1a1a', color:'#fff' }}>
                        Delete Account
                      </button>
                    </div>
                  </div>
                </Card>

                {/* Clear Data Popup */}
                {showClearPopup && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ backgroundColor:'rgba(0,0,0,0.5)' }}>
                    <div className="w-full max-w-md rounded-2xl p-6 mx-4" style={{ backgroundColor:'var(--surface)', boxShadow:'0 16px 48px rgba(0,0,0,0.3)' }}>
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full flex items-center justify-center" style={{ backgroundColor:'rgba(186,26,26,0.1)' }}>
                            <AlertTriangle size={20} style={{ color:'#ba1a1a' }} />
                          </div>
                          <div>
                            <h3 className="text-base font-bold" style={{ color:'var(--on-surface)' }}>Clear all data?</h3>
                            <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>This action cannot be undone.</p>
                          </div>
                        </div>
                        <button onClick={() => setShowClearPopup(false)} style={{ color:'var(--on-surface-variant)' }}><X size={18} /></button>
                      </div>
                      <p className="text-sm mb-4" style={{ color:'var(--on-surface-variant)' }}>
                        All your transactions, loans, investments and trades will be permanently deleted. Your account remains active.
                      </p>
                      <p className="text-xs font-semibold mb-2" style={{ color:'var(--on-surface)' }}>
                        Type <span style={{ color:'#ba1a1a', fontFamily:'monospace' }}>clear all data</span> to confirm:
                      </p>
                      <input
                        type="text"
                        value={clearInput}
                        onChange={e => setClearInput(e.target.value)}
                        placeholder="clear all data"
                        className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border mb-4"
                        style={{ backgroundColor:'var(--surface-container-low)', borderColor: clearInput === 'clear all data' ? '#ba1a1a' : 'var(--outline-variant)', color:'var(--on-surface)' }}
                      />
                      <div className="flex gap-3">
                        <button onClick={() => setShowClearPopup(false)}
                          className="flex-1 py-2.5 rounded-lg text-sm font-medium border"
                          style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
                          Cancel
                        </button>
                        <button onClick={handleClearData}
                          disabled={clearInput !== 'clear all data'}
                          className="flex-1 py-2.5 rounded-lg text-sm font-semibold transition-all"
                          style={{ backgroundColor: clearInput === 'clear all data' ? '#ba1a1a' : 'rgba(186,26,26,0.3)', color:'#fff', cursor: clearInput === 'clear all data' ? 'pointer' : 'not-allowed' }}>
                          Clear All Data
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* Delete Account Popup */}
                {showDeletePopup && (
                  <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ backgroundColor:'rgba(0,0,0,0.5)' }}>
                    <div className="w-full max-w-md rounded-2xl p-6 mx-4" style={{ backgroundColor:'var(--surface)', boxShadow:'0 16px 48px rgba(0,0,0,0.3)' }}>
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full flex items-center justify-center" style={{ backgroundColor:'rgba(186,26,26,0.1)' }}>
                            <AlertTriangle size={20} style={{ color:'#ba1a1a' }} />
                          </div>
                          <div>
                            <h3 className="text-base font-bold" style={{ color:'var(--on-surface)' }}>Delete your account?</h3>
                            <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>This is permanent and irreversible.</p>
                          </div>
                        </div>
                        <button onClick={() => setShowDeletePopup(false)} style={{ color:'var(--on-surface-variant)' }}><X size={18} /></button>
                      </div>
                      <p className="text-sm mb-4" style={{ color:'var(--on-surface-variant)' }}>
                        Your account, profile, and all financial data will be permanently erased. You will not be able to log in again with this email.
                      </p>
                      <p className="text-xs font-semibold mb-2" style={{ color:'var(--on-surface)' }}>
                        Type <span style={{ color:'#ba1a1a', fontFamily:'monospace' }}>delete my account</span> to confirm:
                      </p>
                      <input
                        type="text"
                        value={deleteInput}
                        onChange={e => setDeleteInput(e.target.value)}
                        placeholder="delete my account"
                        className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border mb-4"
                        style={{ backgroundColor:'var(--surface-container-low)', borderColor: deleteInput === 'delete my account' ? '#ba1a1a' : 'var(--outline-variant)', color:'var(--on-surface)' }}
                      />
                      <div className="flex gap-3">
                        <button onClick={() => setShowDeletePopup(false)}
                          className="flex-1 py-2.5 rounded-lg text-sm font-medium border"
                          style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
                          Cancel
                        </button>
                        <button onClick={handleDeleteAccount}
                          disabled={deleteInput !== 'delete my account'}
                          className="flex-1 py-2.5 rounded-lg text-sm font-semibold transition-all"
                          style={{ backgroundColor: deleteInput === 'delete my account' ? '#ba1a1a' : 'rgba(186,26,26,0.3)', color:'#fff', cursor: deleteInput === 'delete my account' ? 'pointer' : 'not-allowed' }}>
                          Delete My Account
                        </button>
                      </div>
                    </div>
                  </div>
                )}
              </>
            )}

          </div>
        </div>
      </div>
    </div>
  )
}
