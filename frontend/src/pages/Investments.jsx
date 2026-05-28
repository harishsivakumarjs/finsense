import { useEffect, useState } from 'react'
import { Plus, Pencil, Trash2, TrendingUp, PieChart, BarChart2, ArrowUpRight } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate } from '../utils/format'
import useStore from '../store/useStore'

const ASSET_TYPES = ['mutual_fund','gold','silver','land','fd','ppf','stocks','insurance','other']
const UNIT_MAP = { mutual_fund:'units', gold:'grams', silver:'grams', land:'sqft', stocks:'shares', fd:'₹', ppf:'₹', insurance:'₹', other:'' }
const LTCG_DAYS = { stocks:365, mutual_fund:365, gold:730, silver:730, land:730 }
const ASSET_COLORS = {
  mutual_fund:'#4a8ed4', stocks:'#2ab5a0', gold:'#d4932a', silver:'#a8a8a8',
  land:'#006b5d', fd:'#8b7fd4', ppf:'#4f5e80', insurance:'#6c7a76', other:'#9a442c',
}

const BLANK_FORM = {
  asset_type:'mutual_fund', name:'', invested_amount:'', current_value:'',
  purchase_date: new Date().toISOString().split('T')[0], quantity:'', unit:'units', notes:'',
}

function getTaxInfo(assetType, daysHeld) {
  const threshold = LTCG_DAYS[assetType]
  if (!threshold) return { label:'Slab', isLTCG:false }
  if (daysHeld >= threshold) return { label:'LTCG', isLTCG:true }
  return { label:'STCG', isLTCG:false }
}

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

function polarToCartesian(cx, cy, r, deg) {
  const rad = (deg - 90) * Math.PI / 180
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) }
}

function donutArcPath(cx, cy, outerR, innerR, startDeg, endDeg) {
  const s = polarToCartesian(cx, cy, outerR, startDeg)
  const e = polarToCartesian(cx, cy, outerR, endDeg)
  const si = polarToCartesian(cx, cy, innerR, endDeg)
  const ei = polarToCartesian(cx, cy, innerR, startDeg)
  const large = endDeg - startDeg > 180 ? 1 : 0
  return `M${s.x},${s.y} A${outerR},${outerR} 0 ${large} 1 ${e.x},${e.y} L${si.x},${si.y} A${innerR},${innerR} 0 ${large} 0 ${ei.x},${ei.y} Z`
}

function DonutChart({ allocation, totalAlloc }) {
  const [hovered, setHovered] = useState(null)

  if (!allocation.length) return (
    <p className="text-sm text-center py-12" style={{ color:'var(--on-surface-variant)' }}>No investments yet</p>
  )

  const cx = 90, cy = 90, outerR = 82, innerR = 56
  let cumAngle = 0
  const segments = allocation.map((a, i) => {
    const pct = totalAlloc > 0 ? (parseFloat(a.total_value||0)/totalAlloc)*100 : 0
    const angle = Math.min((pct / 100) * 360, 359.9)
    const startAngle = cumAngle
    const endAngle = cumAngle + angle
    cumAngle += (pct / 100) * 360
    const color = ASSET_COLORS[a.asset_type] || '#6c7a76'
    return { ...a, pct, startAngle, endAngle, color, idx: i }
  })

  const hovSeg = hovered !== null ? segments[hovered] : null

  return (
    <div>
      <div className="flex items-center justify-center mb-4">
        <svg width={180} height={180} viewBox="0 0 180 180" style={{ overflow:'visible' }}>
          {segments.map((seg, i) => {
            if (seg.endAngle - seg.startAngle < 0.3) return null
            const isHov = hovered === i
            const path = donutArcPath(cx, cy, outerR, innerR, seg.startAngle, seg.endAngle)
            const midAngle = (seg.startAngle + seg.endAngle) / 2
            const midRad = (midAngle - 90) * Math.PI / 180
            const tx = isHov ? Math.cos(midRad) * 4 : 0
            const ty = isHov ? Math.sin(midRad) * 4 : 0
            return (
              <path
                key={seg.asset_type}
                d={path}
                fill={seg.color}
                opacity={hovered === null || isHov ? 1 : 0.35}
                style={{ cursor:'pointer', transition:'opacity 0.15s, transform 0.15s', transform:`translate(${tx}px,${ty}px)` }}
                onMouseEnter={() => setHovered(i)}
                onMouseLeave={() => setHovered(null)}
              />
            )
          })}
          {hovSeg ? (
            <>
              <text x={cx} y={cy - 10} textAnchor="middle" fontSize="9" fontWeight="600"
                style={{ fill:'var(--on-surface-variant)', textTransform:'uppercase', letterSpacing:'0.05em' }}>
                {hovSeg.asset_type.replace('_',' ').toUpperCase()}
              </text>
              <text x={cx} y={cy + 5} textAnchor="middle" fontSize="12" fontWeight="700"
                style={{ fill:'var(--on-surface)', fontFamily:'monospace' }}>
                {formatINR(hovSeg.total_value)}
              </text>
              <text x={cx} y={cy + 19} textAnchor="middle" fontSize="10" fontWeight="600"
                style={{ fill: hovSeg.color }}>
                {hovSeg.pct.toFixed(1)}%
              </text>
            </>
          ) : (
            <>
              <text x={cx} y={cy - 4} textAnchor="middle" fontSize="9" fontWeight="600"
                style={{ fill:'var(--on-surface-variant)' }}>
                TOTAL
              </text>
              <text x={cx} y={cy + 12} textAnchor="middle" fontSize="11" fontWeight="700"
                style={{ fill:'var(--on-surface)', fontFamily:'monospace' }}>
                {formatINR(totalAlloc)}
              </text>
            </>
          )}
        </svg>
      </div>
      <div className="space-y-1.5">
        {allocation.map((a, i) => {
          const pct = totalAlloc > 0 ? (parseFloat(a.total_value||0)/totalAlloc)*100 : 0
          const color = ASSET_COLORS[a.asset_type] || '#6c7a76'
          const isHov = hovered === i
          return (
            <div key={a.asset_type}
              className="flex items-center justify-between rounded-lg px-2 py-1.5 cursor-pointer"
              style={{ backgroundColor: isHov ? `${color}18` : 'transparent', transition:'background-color 0.12s' }}
              onMouseEnter={() => setHovered(i)}
              onMouseLeave={() => setHovered(null)}>
              <div className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor:color }} />
                <span className="text-xs capitalize" style={{ color:'var(--on-surface)' }}>{a.asset_type.replace('_',' ')}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-xs font-mono" style={{ color:'var(--on-surface-variant)' }}>{pct.toFixed(1)}%</span>
                <span className="text-xs font-mono font-semibold" style={{ color }}>{formatINR(a.total_value)}</span>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

export default function Investments() {
  const { selectedFY } = useStore()
  const [investments, setInvestments] = useState([])
  const [allocation, setAllocation] = useState([])
  const [xirr, setXirr] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editInv, setEditInv] = useState(null)
  const [form, setForm] = useState(BLANK_FORM)
  const [activeTab, setActiveTab] = useState('all')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [detail, setDetail] = useState(null)

  const load = async () => {
    setLoading(true)
    try {
      const [invR, allocR, xirrR] = await Promise.all([
        api.get('/investments'),
        api.get('/investments/allocation'),
        api.get('/investments/xirr'),
      ])
      console.log("API response investments:", invR.data)
      setInvestments(Array.isArray(invR.data) ? invR.data : [])
      setAllocation(Array.isArray(allocR.data) ? allocR.data : [])
      setXirr(xirrR.data)
    } catch { toast.error('Failed to load investments') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [selectedFY])

  const openAdd = () => { setEditInv(null); setForm(BLANK_FORM); setShowModal(true) }
  const openEdit = (inv) => {
    setEditInv(inv)
    setForm({ asset_type:inv.asset_type, name:inv.name, invested_amount:inv.invested_amount, current_value:inv.current_value, purchase_date:inv.purchase_date, quantity:inv.quantity||'', unit:inv.unit||UNIT_MAP[inv.asset_type]||'', notes:inv.notes||'' })
    setShowModal(true)
  }
  const handleSave = async () => {
    if (!form.name || !form.invested_amount) return toast.error('Fill required fields')
    try {
      const payload = { ...form, current_value: form.current_value || form.invested_amount }
      if (editInv) { await api.put(`/investments/${editInv.id}`, payload); toast.success('Updated') }
      else { await api.post('/investments', payload); toast.success('Added') }
      setShowModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const handleDelete = async (id) => {
    if (!confirm('Delete this investment?')) return
    try { await api.delete(`/investments/${id}`); toast.success('Deleted'); setShowModal(false); load() }
    catch { toast.error('Failed') }
  }

  const totalInvested = investments.reduce((s,i) => s + parseFloat(i.invested_amount), 0)
  const totalCurrent = investments.reduce((s,i) => s + parseFloat(i.current_value), 0)
  const totalGain = totalCurrent - totalInvested
  const gainPct = totalInvested > 0 ? (totalGain/totalInvested)*100 : 0
  const xirrVal = xirr?.xirr
  const getDaysHeld = (d) => Math.floor((new Date() - new Date(d)) / 86400000)
  const totalAlloc = allocation.reduce((s,a) => s + parseFloat(a.total_value||0), 0)

  const yearInvs = (() => {
    let list = selectedFY === 'all' ? investments : investments.filter(i => i.purchase_date?.startsWith(selectedFY))
    if (dateFrom) list = list.filter(i => i.purchase_date >= dateFrom)
    if (dateTo) list = list.filter(i => i.purchase_date <= dateTo)
    return list
  })()
  const filteredInvs = activeTab === 'all' ? yearInvs : yearInvs.filter(i => {
    if (activeTab === 'equity') return ['stocks','mutual_fund'].includes(i.asset_type)
    if (activeTab === 'debt') return ['fd','ppf'].includes(i.asset_type)
    return true
  })

  return (
    <div className="p-4 md:p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Investments</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Track your portfolio performance</p>
        </div>
        <button onClick={openAdd} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold"
          style={{ backgroundColor:'#2ab5a0', color:'white' }}>
          <Plus size={16} /> Add Investment
        </button>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label:'Portfolio Value', val:formatINR(totalCurrent), icon:<PieChart size={18}/>,    color:'#2ab5a0', sub:`${investments.length} holdings` },
          { label:'Total Invested',  val:formatINR(totalInvested), icon:<BarChart2 size={18}/>,  color:'#4a8ed4', sub:'Capital deployed' },
          { label:'Gain / Loss',     val:`${totalGain>=0?'+':''}${formatINR(totalGain)}`, icon:<TrendingUp size={18}/>, color:totalGain>=0?'var(--positive)':'var(--error)', sub:`${gainPct>=0?'+':''}${gainPct.toFixed(2)}% overall` },
          { label:'XIRR',            val:xirrVal!=null?`${xirrVal}%`:'—', icon:<ArrowUpRight size={18}/>, color:parseFloat(xirrVal||0)>=0?'var(--positive)':'var(--error)', sub:'Annualized return' },
        ].map(({ label, val, icon, color, sub }) => (
          <Card key={label} className="p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
              <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ backgroundColor:`${color}15`, color }}>
                {icon}
              </div>
            </div>
            <p className="text-2xl font-bold font-mono" style={{ color:'var(--on-surface)' }}>{loading ? '—' : val}</p>
            <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>{sub}</p>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Asset Allocation Donut — col-span-4 */}
        <Card className="lg:col-span-4 p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Asset Allocation</h3>
          {loading ? <div className="h-48 shimmer rounded" /> : <DonutChart allocation={allocation} totalAlloc={totalAlloc} />}
        </Card>

        {/* Holdings Table — col-span-8 */}
        <Card className="lg:col-span-8 overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
            <div className="flex items-center gap-3">
              <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>All Assets</h3>
              <div className="flex rounded-lg overflow-hidden" style={{ border:'1px solid var(--outline-variant)' }}>
                {[['all','All Assets'],['equity','Equity'],['debt','Debt']].map(([t,l]) => (
                  <button key={t} onClick={() => setActiveTab(t)}
                    className="px-3 py-1 text-xs font-semibold transition-colors"
                    style={{ backgroundColor:activeTab===t?'#2ab5a0':'transparent', color:activeTab===t?'white':'var(--on-surface-variant)' }}>
                    {l}
                  </button>
                ))}
              </div>
            </div>
            <div className="flex items-center gap-1.5">
              <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
                title="From date"
                className="px-2 py-1.5 rounded-lg text-xs focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
              <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>–</span>
              <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
                title="To date"
                className="px-2 py-1.5 rounded-lg text-xs focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
              {(dateFrom || dateTo) && (
                <button onClick={() => { setDateFrom(''); setDateTo('') }}
                  className="text-xs px-1.5 py-1 rounded"
                  style={{ color:'var(--on-surface-variant)' }}>✕</button>
              )}
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                  {['Asset','Type','Invested','Current Value','Gain/Loss','Returns','Date',''].map(h => (
                    <th key={h} className={`px-4 py-3 text-xs font-semibold uppercase tracking-wider ${['Gain/Loss','Returns',''].includes(h)?'text-right':'text-left'}`}
                      style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  [...Array(5)].map((_,i)=><tr key={i}><td colSpan={7} className="px-4 py-3"><div className="h-5 shimmer rounded"/></td></tr>)
                ) : filteredInvs.length === 0 ? (
                  <tr><td colSpan={7} className="px-4 py-12 text-center text-sm" style={{ color:'var(--on-surface-variant)' }}>
                    No investments. <button onClick={openAdd} style={{ color:'var(--primary-container)' }} className="underline">Add one</button>
                  </td></tr>
                ) : filteredInvs.map(inv => {
                  const gain = parseFloat(inv.current_value) - parseFloat(inv.invested_amount)
                  const gPct = parseFloat(inv.invested_amount) > 0 ? (gain/parseFloat(inv.invested_amount))*100 : 0
                  const color = ASSET_COLORS[inv.asset_type] || '#6c7a76'
                  const letter = inv.name?.charAt(0).toUpperCase() || '?'
                  const days = getDaysHeld(inv.purchase_date)
                  const tax = getTaxInfo(inv.asset_type, days)
                  return (
                    <tr key={inv.id} className="group" style={{ borderBottom:'1px solid var(--outline-variant)', cursor:'pointer' }}
                      onClick={() => setDetail(inv)}
                      onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                      onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                      <td className="px-4 py-3.5">
                        <div className="flex items-center gap-2.5">
                          <div className="w-9 h-9 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
                            style={{ backgroundColor:color }}>
                            {letter}
                          </div>
                          <div>
                            <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{inv.name}</p>
                            <p className="text-xs" style={{ color:'var(--on-surface-variant)' }}>
                              {days >= 365 ? `${(days/365).toFixed(1)}y` : `${days}d`} held
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3.5">
                        <div>
                          <span className="px-2 py-0.5 rounded-full text-xs font-semibold capitalize"
                            style={{ backgroundColor:`${color}18`, color }}>{inv.asset_type.replace('_',' ')}</span>
                          <span className="ml-1.5 px-1.5 py-0.5 rounded text-[10px] font-semibold"
                            style={{ backgroundColor:tax.isLTCG?'rgba(42,181,160,0.12)':'rgba(212,147,42,0.1)', color:tax.isLTCG?'var(--positive)':'var(--warning)' }}>
                            {tax.label}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-3.5 text-sm font-mono" style={{ color:'var(--on-surface-variant)' }}>{formatINR(inv.invested_amount)}</td>
                      <td className="px-4 py-3.5 text-sm font-mono font-semibold" style={{ color:'var(--on-surface)' }}>{formatINR(inv.current_value)}</td>
                      <td className="px-4 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:gain>=0?'var(--positive)':'var(--error)' }}>
                        {gain>=0?'+':''}{formatINR(gain)}
                      </td>
                      <td className="px-4 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:gPct>=0?'var(--positive)':'var(--error)' }}>
                        {gPct>=0?'+':''}{gPct.toFixed(1)}%
                      </td>
                      <td className="px-4 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{formatDate(inv.purchase_date)}</td>
                      <td className="px-4 py-3.5 text-right">
                        <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={e => e.stopPropagation()}>
                          <button onClick={() => openEdit(inv)} className="p-1.5 rounded-lg" style={{ color:'var(--on-surface-variant)' }}
                            onMouseEnter={e => e.currentTarget.style.color='var(--primary-container)'}
                            onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                            <Pencil size={13} />
                          </button>
                          <button onClick={() => handleDelete(inv.id)} className="p-1.5 rounded-lg" style={{ color:'var(--on-surface-variant)' }}
                            onMouseEnter={e => e.currentTarget.style.color='var(--error)'}
                            onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
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
      </div>

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.name || 'Investment Detail'}
        color={ASSET_COLORS[detail?.asset_type] || '#6c7a76'}
        badge={detail?.asset_type?.replace('_', ' ')}
        rows={(() => {
          if (!detail) return []
          const gain = parseFloat(detail.current_value) - parseFloat(detail.invested_amount)
          const gPct = parseFloat(detail.invested_amount) > 0 ? (gain / parseFloat(detail.invested_amount)) * 100 : 0
          const days = getDaysHeld(detail.purchase_date)
          return [
            { label: 'Name', value: detail.name },
            { label: 'Asset Type', value: detail.asset_type?.replace('_', ' ') },
            { label: 'Invested', value: formatINR(detail.invested_amount), valueStyle: { fontFamily: 'monospace' } },
            { label: 'Current Value', value: formatINR(detail.current_value), valueStyle: { fontFamily: 'monospace' } },
            { label: 'Gain / Loss', value: `${gain >= 0 ? '+' : ''}${formatINR(gain)} (${gPct >= 0 ? '+' : ''}${gPct.toFixed(1)}%)`, valueStyle: { fontFamily: 'monospace', color: gain >= 0 ? 'var(--positive)' : 'var(--error)' } },
            { label: 'Purchase Date', value: formatDate(detail.purchase_date) },
            { label: 'Held For', value: days >= 365 ? `${(days / 365).toFixed(1)} years` : `${days} days` },
            { label: 'Quantity', value: detail.quantity ? `${detail.quantity} ${detail.unit || ''}`.trim() : '—' },
            { label: 'Notes', value: detail.notes || '—' },
          ]
        })()}
      />

      {/* Modal */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={editInv ? 'Edit Investment' : 'Add Investment'}>
        <div className="space-y-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Asset Type</p>
            <select value={form.asset_type} onChange={e => setForm(p => ({ ...p, asset_type:e.target.value, unit:UNIT_MAP[e.target.value]||'' }))}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }}>
              {ASSET_TYPES.map(t => <option key={t} value={t}>{t.replace('_',' ').replace(/^\w/,c=>c.toUpperCase())}</option>)}
            </select>
          </div>
          {[
            { label:'Name', key:'name', placeholder:'Mirae Asset Large Cap Fund' },
            { label:'Invested Amount (₹)', key:'invested_amount', placeholder:'50000' },
            { label:'Current Value (₹)', key:'current_value', placeholder:'55000' },
            { label:`Quantity (${form.unit||'units'})`, key:'quantity', placeholder:'100' },
          ].map(({ label, key, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
              <input type={key.includes('amount')||key.includes('value')||key.includes('quantity')?'number':'text'}
                value={form[key]} onChange={e => setForm(p => ({ ...p, [key]:e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
            </div>
          ))}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Purchase Date</p>
            <DatePickerInput value={form.purchase_date} onChange={v => setForm(p => ({ ...p, purchase_date:v }))} />
          </div>
          <div className="flex gap-3 pt-2">
            {editInv && <button onClick={() => handleDelete(editInv.id)} className="px-5 py-3 rounded-lg text-sm font-medium" style={{ color:'var(--error)', border:'1px solid var(--error)', backgroundColor:'var(--error-container)' }}>Delete</button>}
            <button onClick={() => setShowModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={handleSave} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor:'#2ab5a0', color:'white' }}>{editInv ? 'Save' : 'Add'}</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
