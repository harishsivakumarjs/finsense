import { useEffect, useState } from 'react'
import { Plus, Pencil, Trash2, Youtube, DollarSign, Users, ShoppingBag } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate } from '../utils/format'
import useStore from '../store/useStore'

const INCOME_TYPES = ['adsense','sponsorship','membership','merch','course','other']
const TYPE_COLORS = {
  adsense:'#ba1a1a', sponsorship:'#d4932a', membership:'#4a8ed4',
  merch:'#2ab5a0', course:'#8b7fd4', other:'#6c7a76',
}

const BLANK_FORM = { amount:'', brand_name:'', video_title:'', received_on:new Date().toISOString().split('T')[0], rpm:'', notes:'' }

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

function AdSenseChart({ data, loading }) {
  if (loading) return <div className="h-40 shimmer rounded-xl" />
  const filtered = (data || []).filter(d => (d.income||0) > 0)
  if (!filtered.length) return (
    <div className="h-40 flex items-center justify-center text-sm" style={{ color:'var(--on-surface-variant)' }}>
      No AdSense data yet
    </div>
  )
  const W = 400, H = 120
  const maxIncome = Math.max(...filtered.map(d => d.income||0), 1)
  const pts = filtered.map((d, i) => ({
    x: filtered.length === 1 ? W/2 : (i / (filtered.length-1)) * W,
    y: 10 + (H-10) - ((d.income||0)/maxIncome)*(H-20),
    income: d.income,
    month: d.month,
  }))
  const pathD = pts.map((p,i) => `${i===0?'M':'L'}${p.x} ${p.y}`).join(' ')
  const areaD = `${pathD} L${pts[pts.length-1].x} ${H+10} L${pts[0].x} ${H+10} Z`

  return (
    <svg width="100%" viewBox={`0 0 ${W} ${H+24}`} style={{ overflow:'visible' }}>
      <defs>
        <linearGradient id="adsGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#2ab5a0" stopOpacity="0.4" />
          <stop offset="100%" stopColor="#2ab5a0" stopOpacity="0.02" />
        </linearGradient>
      </defs>
      <path d={areaD} fill="url(#adsGrad)" />
      <path d={pathD} fill="none" stroke="#2ab5a0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      {pts.map((p,i) => (
        <circle key={i} cx={p.x} cy={p.y} r="4" fill="#2ab5a0" stroke="white" strokeWidth="2" />
      ))}
      {pts.map((p,i) => (
        <text key={i} x={p.x} y={H+20} textAnchor="middle" fontSize="10" fill="var(--on-surface-variant)">{p.month}</text>
      ))}
    </svg>
  )
}

const BRAND_COLORS = ['#4a8ed4','#d4932a','#8b7fd4','#2ab5a0','#ba1a1a','#006b5d']

export default function Creator() {
  const { selectedFY } = useStore()
  const [entries, setEntries] = useState([])
  const [summary, setSummary] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [incomeType, setIncomeType] = useState('adsense')
  const [detail, setDetail] = useState(null)
  const [editEntry, setEditEntry] = useState(null)
  const [form, setForm] = useState(BLANK_FORM)

  const load = async () => {
    setLoading(true)
    try {
      const [entriesR, summaryR] = await Promise.all([
        api.get('/creator'),
        api.get('/creator/summary'),
      ])
      setEntries(entriesR.data)
      setSummary(summaryR.data)
    } catch { toast.error('Failed to load creator data') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [selectedFY])

  const openAdd = (type='adsense') => { setEditEntry(null); setIncomeType(type); setForm(BLANK_FORM); setShowModal(true) }
  const openEdit = (e) => {
    setEditEntry(e); setIncomeType(e.income_type)
    setForm({ amount:e.amount, brand_name:e.brand_name||'', video_title:e.video_title||'', received_on:e.received_on, rpm:e.rpm??'', notes:e.notes||'' })
    setShowModal(true)
  }
  const handleSave = async () => {
    if (!form.amount) return toast.error('Amount required')
    try {
      const payload = { income_type:incomeType, amount:parseFloat(form.amount), brand_name:form.brand_name||null, video_title:form.video_title||null, received_on:form.received_on, rpm:form.rpm!==''?parseFloat(form.rpm)||null:null, notes:form.notes||null }
      if (editEntry) { await api.put(`/creator/${editEntry.id}`, payload); toast.success('Updated') }
      else { await api.post('/creator', payload); toast.success('Logged') }
      setShowModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const handleDelete = async (id) => {
    if (!confirm('Delete this entry?')) return
    try { await api.delete(`/creator/${id}`); toast.success('Deleted'); setShowModal(false); load() }
    catch { toast.error('Failed') }
  }

  const filteredEntries = selectedFY === 'all' ? entries : entries.filter(e => e.received_on?.startsWith(selectedFY))
  const getTotal = (type) => {
    if (selectedFY === 'all') return summary.find(s => s.income_type === type)?.total || 0
    return filteredEntries.filter(e => e.income_type === type).reduce((s, e) => s + parseFloat(e.amount||0), 0)
  }
  const totalCreator = selectedFY === 'all'
    ? summary.reduce((s,i) => s + i.total, 0)
    : filteredEntries.reduce((s, e) => s + parseFloat(e.amount||0), 0)
  const sponsorships = filteredEntries.filter(e => e.income_type === 'sponsorship')
  const MONTH_ABBR = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
  const adsenseData = (() => {
    const byMonth = {}
    filteredEntries.filter(e => e.income_type === 'adsense').forEach(e => {
      const m = MONTH_ABBR[new Date(e.received_on).getMonth()]
      byMonth[m] = (byMonth[m] || 0) + parseFloat(e.amount || 0)
    })
    return Object.entries(byMonth).map(([month, income]) => ({ month, income }))
  })()
  const currentMonth = new Date().toLocaleString('default', { month: 'long' }).toUpperCase()

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>

      {/* Hero Header */}
      <Card className="p-8" style={{ background:'linear-gradient(135deg, #0B1426 0%, #1a3256 100%)' }}>
        <p className="text-xs font-bold uppercase tracking-[0.2em] mb-2" style={{ color:'rgba(255,255,255,0.5)' }}>
          Creator Economy
        </p>
        <p className="text-xs uppercase tracking-wider mb-1" style={{ color:'rgba(255,255,255,0.4)' }}>
          Total Estimated ({currentMonth})
        </p>
        <p className="font-bold font-mono leading-none" style={{ fontSize:48, color:'#2ab5a0' }}>
          {loading ? '—' : formatINR(totalCreator)}
        </p>
        <p className="text-sm mt-2" style={{ color:'rgba(255,255,255,0.4)' }}>
          {entries.length} entries across {summary.length} streams
        </p>
      </Card>

      {/* 4 Bento Cards */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { type:'adsense',     label:'AdSense',       icon:<Youtube size={20}/>,     trendLabel:'+12% MoM' },
          { type:'sponsorship', label:'Brand Deals',   icon:<DollarSign size={20}/>,  trendLabel:'2 deals' },
          { type:'membership',  label:'Memberships',   icon:<Users size={20}/>,       trendLabel:'Recurring' },
          { type:'merch',       label:'Merch & Others',icon:<ShoppingBag size={20}/>, trendLabel:'Passive' },
        ].map(({ type, label, icon, trendLabel }) => {
          const color = TYPE_COLORS[type]
          const total = getTotal(type) + (type === 'merch' ? getTotal('course') + getTotal('other') : 0)
          return (
            <Card key={type} className="p-5">
              <div className="flex items-start justify-between mb-4">
                <div className="w-11 h-11 rounded-xl flex items-center justify-center" style={{ backgroundColor:`${color}15` }}>
                  <span style={{ color }}>{icon}</span>
                </div>
                <span className="text-[10px] font-semibold px-2 py-1 rounded-full" style={{ backgroundColor:`${color}12`, color }}>
                  {trendLabel}
                </span>
              </div>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
              <p className="text-2xl font-bold font-mono" style={{ color:'var(--on-surface)' }}>
                {loading ? '—' : formatINR(total)}
              </p>
              <button onClick={() => openAdd(type)} className="mt-2 text-xs font-semibold" style={{ color }}>+ Add</button>
            </Card>
          )
        })}
      </div>

      <div className="grid grid-cols-2 gap-5">
        {/* AdSense Performance Chart */}
        <Card className="p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color:'var(--on-surface)' }}>AdSense Performance</h3>
          <AdSenseChart data={adsenseData} loading={loading} />
        </Card>

        {/* Brand Deals Table */}
        <Card className="overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
            <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Brand Deals</h3>
          </div>
          <div className="overflow-y-auto" style={{ maxHeight:300 }}>
            {loading ? (
              <div className="p-4 space-y-3">{[...Array(3)].map((_,i)=><div key={i} className="h-12 shimmer rounded"/>)}</div>
            ) : sponsorships.length === 0 ? (
              <p className="text-sm py-10 text-center" style={{ color:'var(--on-surface-variant)' }}>No brand deals yet</p>
            ) : (
              <table className="w-full">
                <tbody>
                  {sponsorships.map((e, idx) => {
                    const bgColor = BRAND_COLORS[idx % BRAND_COLORS.length]
                    const letter = (e.brand_name||'?').charAt(0).toUpperCase()
                    const daysAgo = Math.floor((new Date() - new Date(e.received_on)) / 86400000)
                    const statusLabel = daysAgo === 0 ? 'Today' : daysAgo < 7 ? `${daysAgo}d ago` : formatDate(e.received_on)
                    return (
                      <tr key={e.id} className="group" style={{ borderBottom:'1px solid var(--outline-variant)' }}
                        onMouseEnter={ev => ev.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                        onMouseLeave={ev => ev.currentTarget.style.backgroundColor='transparent'}>
                        <td className="px-4 py-3.5">
                          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold text-white"
                            style={{ backgroundColor:bgColor }}>
                            {letter}
                          </div>
                        </td>
                        <td className="px-2 py-3.5">
                          <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{e.brand_name||'—'}</p>
                          <p className="text-xs" style={{ color:'var(--on-surface-variant)' }}>{e.video_title||e.notes||'Brand Deal'}</p>
                        </td>
                        <td className="px-4 py-3.5">
                          <span className="text-xs px-2 py-0.5 rounded-full font-semibold" style={{ backgroundColor:'rgba(0,107,93,0.1)', color:'var(--positive)' }}>
                            {statusLabel}
                          </span>
                        </td>
                        <td className="px-4 py-3.5 text-right">
                          <p className="text-sm font-mono font-semibold" style={{ color:'var(--positive)' }}>+{formatINR(e.amount)}</p>
                        </td>
                        <td className="px-3 py-3.5 text-right" onClick={ev => ev.stopPropagation()}>
                          <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity justify-end">
                            <button onClick={() => openEdit(e)} className="p-1 rounded" style={{ color:'var(--on-surface-variant)' }}
                              onMouseEnter={ev => ev.currentTarget.style.color='var(--primary-container)'}
                              onMouseLeave={ev => ev.currentTarget.style.color='var(--on-surface-variant)'}>
                              <Pencil size={12} />
                            </button>
                            <button onClick={() => handleDelete(e.id)} className="p-1 rounded" style={{ color:'var(--on-surface-variant)' }}
                              onMouseEnter={ev => ev.currentTarget.style.color='var(--error)'}
                              onMouseLeave={ev => ev.currentTarget.style.color='var(--on-surface-variant)'}>
                              <Trash2 size={12} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            )}
          </div>
        </Card>
      </div>

      {/* All Entries + Action Buttons */}
      <Card className="overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
          <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>All Creator Income</h3>
          <div className="flex gap-3">
            <button onClick={() => openAdd('adsense')}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold border transition-all"
              style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
              <Plus size={14} /> Log Payout
            </button>
            <button onClick={() => openAdd('sponsorship')}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold"
              style={{ backgroundColor:'#2ab5a0', color:'white' }}>
              <Plus size={14} /> Log Brand Deal
            </button>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                {['Type','Description','Date','RPM','Amount','Actions'].map(h => (
                  <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${['Amount','Actions'].includes(h)?'text-right':'text-left'}`}
                    style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_,i)=><tr key={i}><td colSpan={6} className="px-5 py-3"><div className="h-5 shimmer rounded"/></td></tr>)
              ) : filteredEntries.length === 0 ? (
                <tr><td colSpan={6} className="px-5 py-12 text-center text-sm" style={{ color:'var(--on-surface-variant)' }}>
                  {selectedFY === 'all' ? 'No income logged.' : `No entries for ${selectedFY}.`}{' '}
                  <button onClick={() => openAdd()} style={{ color:'var(--primary-container)' }} className="underline">Add entry</button>
                </td></tr>
              ) : filteredEntries.map(e => {
                const color = TYPE_COLORS[e.income_type] || '#6c7a76'
                return (
                  <tr key={e.id} className="group" style={{ borderBottom:'1px solid var(--outline-variant)', cursor:'pointer' }}
                    onClick={() => setDetail(e)}
                    onMouseEnter={ev => ev.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                    onMouseLeave={ev => ev.currentTarget.style.backgroundColor='transparent'}>
                    <td className="px-5 py-3.5">
                      <span className="px-2.5 py-1 rounded-full text-xs font-semibold capitalize" style={{ backgroundColor:`${color}18`, color }}>{e.income_type.replace('_',' ')}</span>
                    </td>
                    <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface)' }}>{e.brand_name || e.video_title || e.notes || '—'}</td>
                    <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{formatDate(e.received_on)}</td>
                    <td className="px-5 py-3.5 text-sm font-mono" style={{ color:'var(--on-surface-variant)' }}>{e.rpm ? `₹${e.rpm}` : '—'}</td>
                    <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:'var(--primary)' }}>+{formatINR(e.amount)}</td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={ev => ev.stopPropagation()}>
                        <button onClick={() => openEdit(e)} className="p-1.5 rounded-lg" style={{ color:'var(--on-surface-variant)' }}
                          onMouseEnter={ev => ev.currentTarget.style.color='var(--primary-container)'}
                          onMouseLeave={ev => ev.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Pencil size={13} />
                        </button>
                        <button onClick={() => handleDelete(e.id)} className="p-1.5 rounded-lg" style={{ color:'var(--on-surface-variant)' }}
                          onMouseEnter={ev => ev.currentTarget.style.color='var(--error)'}
                          onMouseLeave={ev => ev.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </Card>

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.brand_name || detail?.video_title || detail?.income_type || 'Creator Income Detail'}
        color={TYPE_COLORS[detail?.income_type] || '#6c7a76'}
        badge={detail?.income_type?.replace('_', ' ')}
        rows={detail ? [
          { label: 'Income Type', value: detail.income_type?.replace('_', ' ') },
          { label: 'Brand / Channel', value: detail.brand_name || '—' },
          { label: 'Video / Campaign', value: detail.video_title || '—' },
          { label: 'Received On', value: formatDate(detail.received_on) },
          { label: 'RPM', value: detail.rpm ? `₹${detail.rpm}` : '—' },
          { label: 'Notes', value: detail.notes || '—' },
          { label: 'Amount', value: `+${formatINR(detail.amount)}`, valueStyle: { color: 'var(--positive)', fontFamily: 'monospace' } },
        ] : []}
      />

      {/* Modal */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={editEntry ? 'Edit Creator Income' : 'Log Creator Income'}>
        <div className="space-y-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Income Type</p>
            <select value={incomeType} onChange={e => setIncomeType(e.target.value)}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }}>
              {INCOME_TYPES.map(t => <option key={t} value={t}>{t.replace(/^\w/,c=>c.toUpperCase())}</option>)}
            </select>
          </div>
          {[
            { label:'Amount (₹)', key:'amount', type:'number', placeholder:'25000' },
            { label:'Brand / Channel', key:'brand_name', type:'text', placeholder:'MakeMyTrip' },
            { label:'Video / Campaign', key:'video_title', type:'text', placeholder:'Top 10 Travel Tips' },
            { label:'RPM (₹/1000 views)', key:'rpm', type:'number', placeholder:'35.50 (optional)' },
            { label:'Notes', key:'notes', type:'text', placeholder:'Any notes' },
          ].map(({ label, key, type, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
              <input type={type} value={form[key]} onChange={e => setForm(p => ({ ...p, [key]:e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
            </div>
          ))}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Received On</p>
            <DatePickerInput value={form.received_on} onChange={v => setForm(p => ({ ...p, received_on:v }))} />
          </div>
          <div className="flex gap-3 pt-2">
            {editEntry && <button onClick={() => handleDelete(editEntry.id)} className="px-5 py-3 rounded-lg text-sm font-medium" style={{ color:'var(--error)', border:'1px solid var(--error)', backgroundColor:'var(--error-container)' }}>Delete</button>}
            <button onClick={() => setShowModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={handleSave} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor:'#2ab5a0', color:'white' }}>{editEntry ? 'Save' : 'Log Income'}</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
