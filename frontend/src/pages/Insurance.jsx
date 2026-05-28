import { useState, useEffect } from 'react'
import { Plus, Pencil, Trash2, Shield, Heart, Car, Home, AlertCircle, Plane, Package, Filter } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatINRCompact, formatDate } from '../utils/format'
import useStore from '../store/useStore'

const POLICY_TYPES = [
  { value:'health',   label:'Health',   icon:Heart,       color:'#E05A5A', tax:'80D' },
  { value:'life',     label:'Life',     icon:Shield,      color:'#4a8ed4', tax:'80C' },
  { value:'term',     label:'Term',     icon:Shield,      color:'#4a8ed4', tax:'80C' },
  { value:'vehicle',  label:'Vehicle',  icon:Car,         color:'#d4932a', tax:'' },
  { value:'home',     label:'Home',     icon:Home,        color:'#2ab5a0', tax:'' },
  { value:'accident', label:'Accident', icon:AlertCircle, color:'#E05A5A', tax:'' },
  { value:'travel',   label:'Travel',   icon:Plane,       color:'#8b7fd4', tax:'' },
  { value:'other',    label:'Other',    icon:Package,     color:'#6c7a76', tax:'' },
]

const FREQ_LABELS = { monthly:'Monthly', quarterly:'Quarterly', half_yearly:'Half-Yearly', yearly:'Yearly' }

const BLANK = {
  policy_type:'', policy_name:'', insurer_name:'', policy_number:'',
  sum_assured:'', annual_premium:'', premium_frequency:'yearly',
  next_due_date:'', start_date:'', end_date:'',
  tax_section:'', tax_benefit_amount:'', is_active:true, notes:'',
}

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

function typeInfo(val) { return POLICY_TYPES.find(t => t.value === val) || POLICY_TYPES[7] }

function TypeIcon({ val, size=16 }) {
  const t = typeInfo(val); const Icon = t.icon
  return <Icon size={size} style={{ color:t.color }} />
}

function daysUntil(dateStr) {
  if (!dateStr) return null
  const today = new Date(); today.setHours(0,0,0,0)
  const d = new Date(dateStr); d.setHours(0,0,0,0)
  return Math.ceil((d - today) / 86400000)
}

function DayBadge({ days }) {
  if (days === null) return null
  let bg, color, text
  if (days < 0) { bg='#ba1a1a'; color='#fff'; text='Overdue' }
  else if (days <= 7) { bg='#ba1a1a'; color='#fff'; text=`${days}d` }
  else if (days <= 30) { bg='rgba(212,147,42,0.15)'; color='#d4932a'; text=`${days}d` }
  else { bg='rgba(42,181,160,0.15)'; color='#2ab5a0'; text=`${days}d` }
  return (
    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold"
      style={{ backgroundColor:bg, color }}>
      {text}
    </span>
  )
}

function DueBadge({ dateStr }) {
  const days = daysUntil(dateStr)
  if (days === null) return null
  let style, text, pulse
  if (days < 0) {
    style = { color:'var(--error)', background:'rgba(186,26,26,0.08)', border:'1px solid rgba(186,26,26,0.2)' }
    text = 'Overdue'; pulse = true
  } else if (days <= 7) {
    style = { color:'var(--error)', background:'rgba(186,26,26,0.08)', border:'1px solid rgba(186,26,26,0.2)' }
    text = `${days}d`; pulse = true
  } else if (days <= 30) {
    style = { color:'#d4932a', background:'rgba(212,147,42,0.08)', border:'1px solid rgba(212,147,42,0.2)' }
    text = `${days}d`; pulse = false
  } else {
    style = { color:'var(--positive)', background:'rgba(0,107,93,0.08)', border:'1px solid rgba(0,107,93,0.2)' }
    text = `${days}d`; pulse = false
  }
  return (
    <span className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold" style={style}>
      {pulse && (
        <span className="relative flex h-1.5 w-1.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75" style={{ backgroundColor:'#ba1a1a' }} />
          <span className="relative inline-flex rounded-full h-1.5 w-1.5" style={{ backgroundColor:'#ba1a1a' }} />
        </span>
      )}
      {text}
    </span>
  )
}

function PolicyModal({ isOpen, onClose, editPolicy, onSaved }) {
  const [form, setForm] = useState(BLANK)
  const [saving, setSaving] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)

  useEffect(() => {
    if (!isOpen) { setConfirmDelete(false); return }
    if (editPolicy) {
      setForm({
        policy_type: editPolicy.policy_type || '',
        policy_name: editPolicy.policy_name || '',
        insurer_name: editPolicy.insurer_name || '',
        policy_number: editPolicy.policy_number || '',
        sum_assured: editPolicy.sum_assured != null ? String(editPolicy.sum_assured) : '',
        annual_premium: editPolicy.annual_premium != null ? String(editPolicy.annual_premium) : '',
        premium_frequency: editPolicy.premium_frequency || 'yearly',
        next_due_date: editPolicy.next_due_date || '',
        start_date: editPolicy.start_date || '',
        end_date: editPolicy.end_date || '',
        tax_section: editPolicy.tax_section || '',
        tax_benefit_amount: editPolicy.tax_benefit_amount != null ? String(editPolicy.tax_benefit_amount) : '',
        is_active: editPolicy.is_active !== false,
        notes: editPolicy.notes || '',
      })
    } else { setForm(BLANK) }
  }, [isOpen, editPolicy])

  const set = (k, v) => setForm(p => ({ ...p, [k]:v }))
  const selectType = (val) => {
    const t = typeInfo(val)
    setForm(p => ({ ...p, policy_type:val, tax_section:t.tax, tax_benefit_amount:t.tax?(p.annual_premium||''):'' }))
  }
  const handlePremiumChange = (v) => {
    setForm(p => ({ ...p, annual_premium:v, tax_benefit_amount:p.tax_section?v:p.tax_benefit_amount }))
  }

  const handleSave = async () => {
    if (!form.policy_type) return toast.error('Select a policy type')
    if (!form.policy_name.trim()) return toast.error('Policy name is required')
    if (!form.annual_premium) return toast.error('Annual premium is required')
    if (!form.next_due_date) return toast.error('Next due date is required')
    const payload = {
      policy_type:form.policy_type, policy_name:form.policy_name.trim(),
      insurer_name:form.insurer_name.trim()||null, policy_number:form.policy_number.trim()||null,
      sum_assured:form.sum_assured?parseFloat(form.sum_assured):null,
      annual_premium:parseFloat(form.annual_premium), premium_frequency:form.premium_frequency,
      next_due_date:form.next_due_date, start_date:form.start_date||null, end_date:form.end_date||null,
      tax_section:form.tax_section||null, tax_benefit_amount:form.tax_benefit_amount?parseFloat(form.tax_benefit_amount):null,
      is_active:form.is_active, notes:form.notes.trim()||null,
    }
    setSaving(true)
    try {
      if (editPolicy) { await api.put(`/insurance/${editPolicy.id}`, payload); toast.success('Policy updated') }
      else { await api.post('/insurance', payload); toast.success('Policy added') }
      onSaved(); onClose()
    } catch (e) { toast.error(e?.response?.data?.detail||'Failed to save') }
    finally { setSaving(false) }
  }

  const handleDelete = async () => {
    if (!confirmDelete) { setConfirmDelete(true); return }
    setSaving(true)
    try {
      await api.delete(`/insurance/${editPolicy.id}`)
      toast.success('Policy deleted'); onSaved(); onClose()
    } catch { toast.error('Failed to delete') }
    finally { setSaving(false) }
  }

  const inputCls = "w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border"
  const inputStyle = { backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={editPolicy?'Edit Policy':'Add Insurance Policy'} size="lg">
      <div className="space-y-5">
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider mb-2" style={{ color:'var(--on-surface-variant)' }}>Policy Type</label>
          <div className="grid grid-cols-4 gap-2">
            {POLICY_TYPES.map(t => {
              const Icon = t.icon; const sel = form.policy_type === t.value
              return (
                <button key={t.value} type="button" onClick={() => selectType(t.value)}
                  className="flex flex-col items-center gap-1.5 p-3 rounded-xl text-xs font-medium transition-all"
                  style={{ border:`1px solid ${sel?t.color:'var(--outline-variant)'}`, backgroundColor:sel?`${t.color}15`:'transparent', color:sel?t.color:'var(--on-surface-variant)' }}>
                  <Icon size={18} />
                  {t.label}
                </button>
              )
            })}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Policy Name *</label>
            <input className={inputCls} style={inputStyle} placeholder="e.g. Star Health Comprehensive" value={form.policy_name} onChange={e => set('policy_name', e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Insurer Name</label>
            <input className={inputCls} style={inputStyle} placeholder="e.g. Star Health Insurance" value={form.insurer_name} onChange={e => set('insurer_name', e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Policy Number</label>
            <input className={inputCls} style={inputStyle} placeholder="e.g. POL123456" value={form.policy_number} onChange={e => set('policy_number', e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Sum Assured (₹)</label>
            <input type="number" className={inputCls} style={inputStyle} placeholder="5000000" value={form.sum_assured} onChange={e => set('sum_assured', e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Annual Premium (₹) *</label>
            <input type="number" className={inputCls} style={inputStyle} placeholder="12000" value={form.annual_premium} onChange={e => handlePremiumChange(e.target.value)} />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Premium Frequency</label>
            <select className={inputCls} style={inputStyle} value={form.premium_frequency} onChange={e => set('premium_frequency', e.target.value)}>
              <option value="monthly">Monthly</option>
              <option value="quarterly">Quarterly</option>
              <option value="half_yearly">Half-Yearly</option>
              <option value="yearly">Yearly</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Next Due Date *</label>
            <DatePickerInput value={form.next_due_date} onChange={v => set('next_due_date', v)} />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Start Date</label>
            <DatePickerInput value={form.start_date} onChange={v => set('start_date', v)} placeholder="DD/MM/YYYY (optional)" />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>End / Maturity Date</label>
            <DatePickerInput value={form.end_date} onChange={v => set('end_date', v)} placeholder="DD/MM/YYYY (optional)" />
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Tax Section</label>
            <select className={inputCls} style={inputStyle} value={form.tax_section} onChange={e => set('tax_section', e.target.value)}>
              <option value="">None</option>
              <option value="80C">80C</option>
              <option value="80D">80D</option>
            </select>
          </div>
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Tax Benefit Amount (₹)</label>
            <input type="number" className={inputCls} style={inputStyle} placeholder="Auto-filled from premium" value={form.tax_benefit_amount} onChange={e => set('tax_benefit_amount', e.target.value)} />
          </div>
          <div className="flex items-center gap-3 pt-1">
            <label className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>Active Policy</label>
            <button type="button" onClick={() => set('is_active', !form.is_active)}
              className="relative w-10 h-5 rounded-full transition-colors flex-shrink-0"
              style={{ backgroundColor:form.is_active?'#2ab5a0':'var(--outline-variant)' }}>
              <span className="absolute top-0.5 w-4 h-4 rounded-full bg-white transition-all" style={{ left:form.is_active?'22px':'2px' }} />
            </button>
          </div>
        </div>
        <div>
          <label className="block text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Notes</label>
          <textarea className={inputCls} style={inputStyle} rows={2} placeholder="Optional notes..." value={form.notes} onChange={e => set('notes', e.target.value)} />
        </div>
        <div className="flex items-center gap-3 pt-2">
          {editPolicy && (
            <button onClick={handleDelete} disabled={saving} className="px-4 py-2.5 rounded-lg text-sm font-medium transition-all"
              style={{ backgroundColor:confirmDelete?'#ba1a1a':'rgba(186,26,26,0.08)', color:confirmDelete?'#fff':'#ba1a1a' }}>
              {confirmDelete?'Confirm Delete':'Delete'}
            </button>
          )}
          <div className="flex-1" />
          <button onClick={onClose} className="px-4 py-2.5 rounded-lg text-sm font-medium" style={{ color:'var(--on-surface-variant)' }}>Cancel</button>
          <button onClick={handleSave} disabled={saving} className="px-6 py-2.5 rounded-lg text-sm font-semibold transition-all"
            style={{ backgroundColor:'#2ab5a0', color:'#fff', opacity:saving?0.7:1 }}>
            {saving?'Saving…':editPolicy?'Save Changes':'Add Policy'}
          </button>
        </div>
      </div>
    </Modal>
  )
}

export default function Insurance() {
  const { selectedFY } = useStore()
  const [policies, setPolicies] = useState([])
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editPolicy, setEditPolicy] = useState(null)
  const [showActive, setShowActive] = useState(true)
  const [detail, setDetail] = useState(null)

  const load = async () => {
    setLoading(true)
    try {
      const [listR, sumR] = await Promise.all([api.get('/insurance'), api.get('/insurance/summary')])
      console.log("API response insurance:", listR.data, "summary:", sumR.data)
      setPolicies(Array.isArray(listR.data) ? listR.data : [])
      setSummary(sumR.data || null)
    } catch { toast.error('Failed to load insurance data') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [selectedFY])

  const openAdd = () => { setEditPolicy(null); setShowModal(true) }
  const openEdit = (p) => { setEditPolicy(p); setShowModal(true) }

  const section80cLimit = 150000
  const section80dLimit = 25000
  const section80cUsed = summary?.section_80c || 0
  const section80dUsed = summary?.section_80d || 0

  const filteredPolicies = policies.filter(p => showActive ? p.is_active !== false : p.is_active === false)

  return (
    <div className="p-4 md:p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Insurance Policies</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Manage your coverage and track renewals</p>
        </div>
        <button onClick={openAdd} className="flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold"
          style={{ backgroundColor:'#2ab5a0', color:'#fff' }}>
          <Plus size={16} /> Add Policy
        </button>
      </div>

      {/* Metric Cards */}
      {summary && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { label:'Total Coverage',  value:formatINR(summary.total_coverage),        sub:'Sum assured across all policies',         color:'#2ab5a0' },
            { label:'Annual Premium',  value:formatINR(summary.total_annual_premium),  sub:'Total yearly outflow',                    color:'var(--error)' },
            { label:'Tax Benefit',     value:formatINR(summary.total_tax_benefit),     sub:`80C: ${formatINR(summary.section_80c)}  80D: ${formatINR(summary.section_80d)}`, color:'#8b7fd4' },
            { label:'Active Policies', value:summary.active_count,                            sub:'Currently active',                         color:'#4a8ed4' },
          ].map(m => (
            <Card key={m.label} className="p-5">
              <p className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color:'var(--on-surface-variant)' }}>{m.label}</p>
              <p className="text-2xl font-bold font-mono" style={{ color:m.color }}>{m.value}</p>
              <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>{m.sub}</p>
            </Card>
          ))}
        </div>
      )}

      {/* Main Layout: col-span-4 LEFT | col-span-8 RIGHT */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">

        {/* LEFT — Upcoming Renewals + Tax Benefits */}
        <div className="lg:col-span-4 space-y-4">
          {/* Upcoming Renewals */}
          <Card className="overflow-hidden">
            <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
              <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Upcoming Renewals</p>
              <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Next 60 days</p>
            </div>
            <div className="p-4 space-y-3">
              {loading ? (
                <div className="space-y-3">{[...Array(3)].map((_,i)=><div key={i} className="h-14 shimmer rounded-xl"/>)}</div>
              ) : !summary || !summary.upcoming_renewals?.length ? (
                <p className="text-xs text-center py-6" style={{ color:'var(--on-surface-variant)' }}>No renewals in next 60 days</p>
              ) : summary.upcoming_renewals.map(r => {
                const urgColor = r.days_until <= 7 ? '#ba1a1a' : r.days_until <= 30 ? '#d4932a' : '#2ab5a0'
                return (
                  <div key={r.id} className="flex items-center justify-between p-3 rounded-xl gap-3"
                    style={{ border:`1px solid ${urgColor}25`, backgroundColor:`${urgColor}06` }}>
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                      <TypeIcon val={r.policy_type} size={16} />
                      <div className="min-w-0">
                        <p className="text-xs font-semibold truncate" style={{ color:'var(--on-surface)' }}>{r.policy_name}</p>
                        <p className="text-xs font-mono mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{formatINR(r.annual_premium)}</p>
                      </div>
                    </div>
                    <DayBadge days={r.days_until} />
                  </div>
                )
              })}
            </div>
          </Card>

          {/* Tax Benefits */}
          {summary && (
            <Card className="overflow-hidden">
              <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Tax Benefits</p>
              </div>
              <div className="p-4 space-y-4">
                {[
                  { label:'Section 80C', used:section80cUsed, limit:section80cLimit },
                  { label:'Section 80D', used:section80dUsed, limit:section80dLimit },
                ].map(({ label, used, limit }) => {
                  const pct = Math.min((used/limit)*100, 100)
                  return (
                    <div key={label}>
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-xs font-semibold" style={{ color:'var(--on-surface)' }}>{label}</span>
                        <span className="text-xs font-mono" style={{ color:'var(--on-surface-variant)' }}>
                          {formatINRCompact(used)} / {formatINRCompact(limit)}
                        </span>
                      </div>
                      <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container)' }}>
                        <div className="h-full rounded-full" style={{ width:`${pct}%`, backgroundColor:'#2ab5a0' }} />
                      </div>
                      <p className="text-xs font-mono mt-1" style={{ color:'var(--on-surface-variant)' }}>
                        {formatINRCompact(Math.max(0,limit-used))} remaining
                      </p>
                    </div>
                  )
                })}
                <div className="pt-3 flex items-center justify-between" style={{ borderTop:'1px solid var(--outline-variant)' }}>
                  <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>Total saved</span>
                  <span className="text-sm font-bold font-mono" style={{ color:'#2ab5a0' }}>{formatINR(summary.total_tax_benefit)}</span>
                </div>
              </div>
            </Card>
          )}
        </div>

        {/* RIGHT — All Policies Table */}
        <Card className="lg:col-span-8 overflow-hidden">
          <div className="px-5 py-4 flex items-center justify-between" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
            <div className="flex items-center gap-3">
              <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>All Policies</span>
              <div className="flex rounded-lg overflow-hidden" style={{ border:'1px solid var(--outline-variant)' }}>
                <button onClick={() => setShowActive(true)}
                  className="px-3 py-1 text-xs font-semibold transition-colors"
                  style={{ backgroundColor:showActive?'#2ab5a0':'transparent', color:showActive?'white':'var(--on-surface-variant)' }}>
                  Active
                </button>
                <button onClick={() => setShowActive(false)}
                  className="px-3 py-1 text-xs font-semibold transition-colors"
                  style={{ backgroundColor:!showActive?'var(--surface-container-low)':'transparent', color:'var(--on-surface-variant)' }}>
                  Expired
                </button>
              </div>
            </div>
            <div className="flex items-center gap-1.5 text-xs" style={{ color:'var(--on-surface-variant)' }}>
              <Filter size={13} />
              <span>{filteredPolicies.length} policies</span>
            </div>
          </div>
          {loading ? (
            <div className="py-16 text-center text-sm" style={{ color:'var(--on-surface-variant)' }}>Loading…</div>
          ) : filteredPolicies.length === 0 ? (
            <div className="py-16 text-center">
              <Shield size={32} className="mx-auto mb-3 opacity-30" style={{ color:'var(--on-surface-variant)' }} />
              <p className="text-sm" style={{ color:'var(--on-surface-variant)' }}>No {showActive?'active':'expired'} policies. <button onClick={openAdd} className="underline" style={{ color:'#2ab5a0' }}>Add one</button></p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                    {['Type','Policy Name','Insurer','Sum Assured','Premium','Next Renewal','Tax','Actions'].map(h => (
                      <th key={h} className={`px-4 py-3 text-xs font-semibold uppercase tracking-wider ${h==='Actions'?'text-right':'text-left'}`}
                        style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {filteredPolicies.map(p => {
                    const t = typeInfo(p.policy_type)
                    const days = daysUntil(p.next_due_date)
                    return (
                      <tr key={p.id} className="group" style={{ borderBottom:'1px solid var(--outline-variant)', cursor:'pointer' }}
                        onClick={() => setDetail(p)}
                        onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                        onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                        <td className="px-4 py-3.5">
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor:`${t.color}18` }}>
                              <TypeIcon val={p.policy_type} size={14} />
                            </div>
                            <span className="text-xs font-semibold px-1.5 py-0.5 rounded-full capitalize"
                              style={{ backgroundColor:`${t.color}18`, color:t.color }}>{p.policy_type}</span>
                          </div>
                        </td>
                        <td className="px-4 py-3.5">
                          <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{p.policy_name}</p>
                          {p.policy_number && <p className="text-xs font-mono mt-0.5" style={{ color:'var(--on-surface-variant)' }}>#{p.policy_number}</p>}
                        </td>
                        <td className="px-4 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{p.insurer_name||'—'}</td>
                        <td className="px-4 py-3.5 text-sm font-mono font-semibold" style={{ color:'var(--on-surface)' }}>
                          {p.sum_assured!=null?formatINRCompact(p.sum_assured):'—'}
                        </td>
                        <td className="px-4 py-3.5">
                          <p className="text-sm font-mono font-semibold" style={{ color:'var(--error)' }}>{formatINR(p.annual_premium)}</p>
                          <p className="text-xs capitalize" style={{ color:'var(--on-surface-variant)' }}>{FREQ_LABELS[p.premium_frequency]||p.premium_frequency}</p>
                        </td>
                        <td className="px-4 py-3.5">
                          <p className="text-xs mb-1" style={{ color:'var(--on-surface)' }}>{formatDate(p.next_due_date)}</p>
                          <DueBadge dateStr={p.next_due_date} />
                        </td>
                        <td className="px-4 py-3.5">
                          {p.tax_section ? (
                            <span className="rounded-full px-2.5 py-0.5 text-xs font-semibold"
                              style={{ color:'#2ab5a0', background:'rgba(42,181,160,0.1)', border:'1px solid rgba(42,181,160,0.2)' }}>
                              {p.tax_section}
                            </span>
                          ) : <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>—</span>}
                        </td>
                        <td className="px-4 py-3.5 text-right" onClick={e => e.stopPropagation()}>
                          <button onClick={() => openEdit(p)}
                            className="p-1.5 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"
                            style={{ color:'var(--on-surface-variant)' }}
                            onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container)'}
                            onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                            <Pencil size={13} />
                          </button>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.policy_name || 'Policy Detail'}
        color={typeInfo(detail?.policy_type)?.color || '#2ab5a0'}
        badge={detail?.policy_type}
        rows={detail ? [
          { label: 'Policy Name', value: detail.policy_name },
          { label: 'Policy Type', value: detail.policy_type },
          { label: 'Insurer', value: detail.insurer_name || '—' },
          { label: 'Policy Number', value: detail.policy_number || '—' },
          { label: 'Sum Assured', value: detail.sum_assured != null ? formatINR(detail.sum_assured) : '—', valueStyle: { fontFamily: 'monospace' } },
          { label: 'Annual Premium', value: formatINR(detail.annual_premium), valueStyle: { fontFamily: 'monospace', color: 'var(--error)' } },
          { label: 'Frequency', value: FREQ_LABELS[detail.premium_frequency] || detail.premium_frequency },
          { label: 'Start Date', value: detail.start_date ? formatDate(detail.start_date) : '—' },
          { label: 'End Date', value: detail.end_date ? formatDate(detail.end_date) : '—' },
          { label: 'Next Due Date', value: detail.next_due_date ? formatDate(detail.next_due_date) : '—' },
          { label: 'Tax Section', value: detail.tax_section || '—' },
          { label: 'Tax Benefit', value: detail.tax_benefit_amount ? formatINR(detail.tax_benefit_amount) : '—', valueStyle: { fontFamily: 'monospace' } },
          { label: 'Status', value: detail.is_active !== false ? 'Active' : 'Expired' },
          { label: 'Notes', value: detail.notes || '—' },
        ] : []}
      />

      <PolicyModal isOpen={showModal} onClose={() => setShowModal(false)} editPolicy={editPolicy} onSaved={load} />
    </div>
  )
}
