import { useEffect, useState } from 'react'
import { Camera, Download, Flag, TrendingUp, BarChart2, AlertCircle, Pencil, Plus, Trash2, X } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import { formatINR, formatINRCompact } from '../utils/format'

const ASSET_COLORS = {
  mutual_fund:'#4a8ed4', stocks:'#2ab5a0', gold:'#d4932a', silver:'#a8a8a8',
  land:'#006b5d', fd:'#8b7fd4', ppf:'#4f5e80', insurance:'#6c7a76', other:'#9a442c',
}

const DEFAULT_MILESTONES = [
  { id:1, label:'₹1L Saved',     target:100000   },
  { id:2, label:'₹5L Portfolio', target:500000   },
  { id:3, label:'₹10L Worth',    target:1000000  },
  { id:4, label:'₹25L Club',     target:2500000  },
  { id:5, label:'₹50L Mark',     target:5000000  },
  { id:6, label:'Crorepati',     target:10000000 },
]

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

function NWChart({ data }) {
  if (!data || data.length < 2) return null
  const W = 600, H = 160
  const vals = data.map(d => d.nw)
  const minV = Math.min(...vals)
  const maxV = Math.max(...vals)
  const range = maxV - minV || 1
  const pad = 12
  const pts = data.map((d, i) => ({
    x: (i / (data.length-1)) * W,
    y: pad + (H - 2*pad) - ((d.nw - minV) / range) * (H - 2*pad),
    nw: d.nw,
    date: d.date,
  }))
  const pathD = pts.map((p,i) => `${i===0?'M':'L'}${p.x} ${p.y}`).join(' ')
  const areaD = `${pathD} L${pts[pts.length-1].x} ${H} L${pts[0].x} ${H} Z`
  const avgNw = vals.reduce((s,v)=>s+v,0)/vals.length
  const avgY = pad + (H - 2*pad) - ((avgNw - minV) / range) * (H - 2*pad)
  const labelEvery = Math.max(1, Math.floor(data.length / 6))

  return (
    <svg width="100%" viewBox={`0 0 ${W} ${H+20}`} style={{ overflow:'visible' }}>
      <defs>
        <linearGradient id="nwGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#2ab5a0" stopOpacity="0.3" />
          <stop offset="100%" stopColor="#2ab5a0" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={areaD} fill="url(#nwGrad)" />
      <path d={pathD} fill="none" stroke="#2ab5a0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      <line x1="0" y1={avgY} x2={W} y2={avgY} stroke="rgba(74,142,212,0.5)" strokeWidth="1.5" strokeDasharray="6 3" />
      {pts.map((p,i) => (
        <circle key={i} cx={p.x} cy={p.y} r="4" fill="#2ab5a0" stroke="white" strokeWidth="2" />
      ))}
      {pts.filter((_,i) => i===0 || i===pts.length-1 || i%labelEvery===0).map((p,i) => (
        <text key={i} x={p.x} y={H+16} textAnchor="middle" fontSize="10" fill="var(--on-surface-variant)">
          {p.date?.slice(5) || ''}
        </text>
      ))}
    </svg>
  )
}

export default function NetWorth() {
  const [current, setCurrent] = useState(null)
  const [history, setHistory] = useState([])
  const [investments, setInvestments] = useState([])
  const [loans, setLoans] = useState([])
  const [cards, setCards] = useState([])
  const [loading, setLoading] = useState(true)

  const [milestones, setMilestones] = useState(() => {
    try {
      const saved = localStorage.getItem('finsense_milestones')
      return saved ? JSON.parse(saved) : DEFAULT_MILESTONES
    } catch { return DEFAULT_MILESTONES }
  })
  const [showMilestoneModal, setShowMilestoneModal] = useState(false)
  const [newLabel, setNewLabel] = useState('')
  const [newTarget, setNewTarget] = useState('')

  const saveMilestones = (updated) => {
    setMilestones(updated)
    localStorage.setItem('finsense_milestones', JSON.stringify(updated))
  }
  const deleteMilestone = (id) => saveMilestones(milestones.filter(m => m.id !== id))
  const addMilestone = () => {
    const t = parseFloat(newTarget)
    if (!newLabel.trim() || !t || t <= 0) return
    const updated = [...milestones, { id: Date.now(), label: newLabel.trim(), target: t }]
      .sort((a, b) => a.target - b.target)
    saveMilestones(updated)
    setNewLabel(''); setNewTarget('')
  }

  const load = async () => {
    setLoading(true)
    try {
      const [curR, histR, invR, loanR, cardR] = await Promise.all([
        api.get('/networth'),
        api.get('/networth/history'),
        api.get('/investments'),
        api.get('/loans'),
        api.get('/loans/cards'),
      ])
      setCurrent(curR.data)
      setHistory(histR.data)
      setInvestments(invR.data)
      setLoans(loanR.data)
      setCards(cardR.data)
    } catch { toast.error('Failed to load net worth data') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  const takeSnapshot = async () => {
    try { await api.post('/networth/snapshot'); toast.success('Snapshot saved!'); load() }
    catch { toast.error('Failed to take snapshot') }
  }

  const downloadReport = async () => {
    try {
      const res = await api.get('/reports/networth')
      const blob = new Blob([JSON.stringify(res.data, null, 2)], { type:'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a'); a.href = url; a.download = `networth_${new Date().getFullYear()}.json`; a.click()
    } catch { toast.error('Failed to download') }
  }

  const nw = current?.net_worth || 0
  const totalAssets = current?.total_assets || 0
  const totalLiabilities = current?.total_liabilities || 0

  const histArr = Array.isArray(history) ? history : []
  const prevNw = histArr.length >= 2 ? histArr[histArr.length - 2]?.net_worth : null
  const trendPct = prevNw && prevNw !== 0 ? ((nw - prevNw) / Math.abs(prevNw)) * 100 : null

  const assetGroups = investments.reduce((acc, inv) => {
    const type = inv.asset_type
    if (!acc[type]) acc[type] = 0
    acc[type] += parseFloat(inv.current_value || 0)
    return acc
  }, {})

  const loanLiabilities = loans.filter(l => l.is_active).map(l => ({
    name:l.loan_name, type:l.loan_type,
    value:parseFloat(l.principal) - (parseFloat(l.principal) * Math.min(((new Date()-new Date(l.start_date))/(1000*60*60*24*30))/l.months_total,1))
  }))
  const cardLiabilities = cards.map(c => ({ name:c.card_name, type:'credit_card', value:parseFloat(c.outstanding||0) }))
  const allLiabilities = [...loanLiabilities, ...cardLiabilities].filter(l => l.value > 0)

  const chartData = histArr.map(h => ({
    date: h.date || h.recorded_at?.split('T')[0],
    nw: parseFloat(h.net_worth||0),
  }))

  const assetTotal = Object.values(assetGroups).reduce((s,v) => s+v, 0)
  const liabilityTotal = allLiabilities.reduce((s,l) => s+l.value, 0)

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>Consolidated Overview</p>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Net Worth</h1>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={takeSnapshot} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border"
            style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
            <Camera size={15} /> Take Snapshot
          </button>
          <button onClick={downloadReport} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border"
            style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
            <Download size={15} /> Export
          </button>
        </div>
      </div>

      {/* Hero Cards */}
      <div className="grid grid-cols-3 gap-4">
        <Card className="p-5">
          <div className="flex items-center justify-between mb-2">
            <p className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>Net Worth</p>
            <TrendingUp size={18} style={{ color:'var(--primary-container)' }} />
          </div>
          <p className="text-3xl font-bold font-mono" style={{ color:'var(--on-surface)' }}>{loading ? '—' : formatINR(nw)}</p>
          {trendPct !== null && (
            <p className="text-xs mt-1 font-semibold" style={{ color:trendPct>=0?'#006b5d':'#ba1a1a' }}>
              {trendPct>=0?'▲':'▼'} {Math.abs(trendPct).toFixed(1)}% vs last snapshot
            </p>
          )}
        </Card>
        <Card className="p-5">
          <div className="flex items-center justify-between mb-2">
            <p className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>Total Assets</p>
            <BarChart2 size={18} style={{ color:'#2ab5a0' }} />
          </div>
          <p className="text-3xl font-bold font-mono" style={{ color:'var(--on-surface)' }}>{loading ? '—' : formatINR(totalAssets)}</p>
          <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>{investments.length} holdings</p>
        </Card>
        <Card className="p-5">
          <div className="flex items-center justify-between mb-2">
            <p className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>Total Liabilities</p>
            <AlertCircle size={18} style={{ color:'var(--error)' }} />
          </div>
          <p className="text-3xl font-bold font-mono" style={{ color:'var(--on-surface)' }}>{loading ? '—' : formatINR(totalLiabilities)}</p>
          <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>{loans.filter(l=>l.is_active).length} loans + {cards.length} cards</p>
        </Card>
      </div>

      {/* Net Worth Trend Chart (SVG) */}
      <Card className="p-5">
        <h3 className="text-base font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Net Worth Trend</h3>
        {loading ? <div className="h-48 shimmer rounded" /> : chartData.length < 2 ? (
          <div className="h-48 flex flex-col items-center justify-center text-sm" style={{ color:'var(--on-surface-variant)' }}>
            <p>No history yet.</p>
            <button onClick={takeSnapshot} className="mt-2 text-xs font-semibold underline" style={{ color:'var(--primary-container)' }}>Take your first snapshot</button>
          </div>
        ) : (
          <div style={{ paddingBottom:4 }}>
            <NWChart data={chartData} />
            <div className="flex items-center gap-4 mt-2">
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-[2px] rounded" style={{ backgroundColor:'#2ab5a0' }} />
                <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>Net Worth</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-5 h-px border-t border-dashed" style={{ borderColor:'rgba(74,142,212,0.5)' }} />
                <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>Average</span>
              </div>
            </div>
          </div>
        )}
      </Card>

      <div className="grid grid-cols-2 gap-5">
        {/* Assets Breakdown */}
        <Card className="overflow-hidden">
          <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
            <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Assets Breakdown</h3>
          </div>
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                {['Type','Current Value','%'].map(h => (
                  <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${h!=='Type'?'text-right':'text-left'}`}
                    style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(4)].map((_,i)=><tr key={i}><td colSpan={3} className="px-5 py-3"><div className="h-4 shimmer rounded"/></td></tr>)
              ) : Object.entries(assetGroups).length === 0 ? (
                <tr><td colSpan={3} className="px-5 py-8 text-center text-sm" style={{ color:'var(--on-surface-variant)' }}>No assets tracked</td></tr>
              ) : Object.entries(assetGroups).map(([type, val]) => {
                const pct = assetTotal > 0 ? (val/assetTotal)*100 : 0
                const color = ASSET_COLORS[type] || '#6c7a76'
                return (
                  <tr key={type} style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2">
                        <div className="w-2.5 h-2.5 rounded-full" style={{ backgroundColor:color }} />
                        <span className="text-sm capitalize font-medium" style={{ color:'var(--on-surface)' }}>{type.replace('_',' ')}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:'var(--on-surface)' }}>{formatINR(val)}</td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <div className="w-16 h-1.5 rounded-full" style={{ backgroundColor:'var(--surface-container)' }}>
                          <div className="h-full rounded-full" style={{ width:`${pct}%`, backgroundColor:color }} />
                        </div>
                        <span className="text-xs font-mono" style={{ color:'var(--on-surface-variant)' }}>{pct.toFixed(1)}%</span>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
            {Object.entries(assetGroups).length > 0 && (
              <tfoot>
                <tr style={{ backgroundColor:'var(--surface-container-low)', borderTop:'2px solid var(--outline-variant)' }}>
                  <td className="px-5 py-3 text-sm font-bold" style={{ color:'var(--on-surface)' }}>Total</td>
                  <td className="px-5 py-3 text-right text-sm font-bold font-mono" style={{ color:'var(--on-surface)' }}>{formatINR(assetTotal)}</td>
                  <td className="px-5 py-3 text-right text-xs font-mono" style={{ color:'var(--on-surface-variant)' }}>100%</td>
                </tr>
              </tfoot>
            )}
          </table>
        </Card>

        {/* Liabilities Breakdown */}
        <Card className="overflow-hidden">
          <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
            <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Liabilities Breakdown</h3>
          </div>
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                {['Name','Type','Balance'].map(h => (
                  <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${h==='Balance'?'text-right':'text-left'}`}
                    style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(3)].map((_,i)=><tr key={i}><td colSpan={3} className="px-5 py-3"><div className="h-4 shimmer rounded"/></td></tr>)
              ) : allLiabilities.length === 0 ? (
                <tr><td colSpan={3} className="px-5 py-8 text-center text-sm" style={{ color:'var(--on-surface-variant)' }}>No liabilities — debt-free! 🎉</td></tr>
              ) : allLiabilities.map((l, i) => (
                <tr key={i} style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                  <td className="px-5 py-3.5 text-sm font-medium" style={{ color:'var(--on-surface)' }}>{l.name}</td>
                  <td className="px-5 py-3.5 text-sm capitalize" style={{ color:'var(--on-surface-variant)' }}>{l.type.replace('_',' ')}</td>
                  <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:'var(--error)' }}>{formatINR(l.value)}</td>
                </tr>
              ))}
            </tbody>
            {allLiabilities.length > 0 && (
              <tfoot>
                <tr style={{ backgroundColor:'var(--surface-container-low)', borderTop:'2px solid var(--outline-variant)' }}>
                  <td className="px-5 py-3 text-sm font-bold" style={{ color:'var(--on-surface)' }}>Total</td>
                  <td />
                  <td className="px-5 py-3 text-right text-sm font-bold font-mono" style={{ color:'var(--error)' }}>{formatINR(liabilityTotal)}</td>
                </tr>
              </tfoot>
            )}
          </table>
        </Card>
      </div>

      {/* Financial Milestones — compact 6-card row */}
      <Card className="p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Flag size={16} style={{ color:'var(--primary-container)' }} />
            <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Financial Milestones</h3>
          </div>
          <button onClick={() => setShowMilestoneModal(true)}
            className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border transition-colors"
            style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}
            onMouseEnter={e => { e.currentTarget.style.borderColor='var(--primary-container)'; e.currentTarget.style.color='var(--primary-container)' }}
            onMouseLeave={e => { e.currentTarget.style.borderColor='var(--outline-variant)'; e.currentTarget.style.color='var(--on-surface-variant)' }}
          >
            <Pencil size={12} /> Edit
          </button>
        </div>
        <div className="grid grid-cols-6 gap-3">
          {milestones.map(m => {
            const pct = Math.min((nw / m.target) * 100, 100)
            const achieved = nw >= m.target
            const remaining = m.target - nw
            const monthlyGrowth = 5000
            const monthsToGo = remaining > 0 && monthlyGrowth > 0 ? Math.ceil(remaining / monthlyGrowth) : 0
            const estYear = new Date().getFullYear() + Math.floor(monthsToGo / 12)
            const estMonth = new Date(new Date().getFullYear(), new Date().getMonth() + monthsToGo).toLocaleString('default',{month:'short'})
            return (
              <div key={m.id} className="p-3 rounded-xl"
                style={{ backgroundColor:'var(--surface-container-low)', border:`1px solid ${achieved?'rgba(0,107,93,0.3)':'var(--outline-variant)'}` }}>
                <div className="flex items-center justify-between mb-2">
                  <Flag size={13} style={{ color:achieved?'#006b5d':'var(--on-surface-variant)' }} />
                  {achieved
                    ? <span className="text-[9px] font-bold px-1.5 py-0.5 rounded-full uppercase" style={{ backgroundColor:'rgba(0,107,93,0.1)', color:'var(--positive)' }}>Achieved</span>
                    : <span className="text-[9px]" style={{ color:'var(--on-surface-variant)' }}>Est. {estMonth} {estYear}</span>
                  }
                </div>
                <p className="text-lg font-bold font-mono leading-none mb-0.5" style={{ color:achieved?'#006b5d':'var(--on-surface)' }}>{formatINRCompact(m.target)}</p>
                <p className="text-[10px] mb-2 truncate" style={{ color:'var(--on-surface-variant)' }}>{m.label}</p>
                <div className="h-1 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container-high)' }}>
                  <div className="h-full rounded-full transition-all" style={{ width:`${pct}%`, backgroundColor:achieved?'#006b5d':'#2ab5a0' }} />
                </div>
                <p className="text-[9px] mt-1 text-right font-mono" style={{ color:achieved?'#006b5d':'var(--on-surface-variant)' }}>{pct.toFixed(0)}%</p>
              </div>
            )
          })}
        </div>
      </Card>

      {/* Milestones Edit Modal */}
      {showMilestoneModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center" style={{ backgroundColor:'rgba(0,0,0,0.4)' }}
          onClick={e => { if (e.target === e.currentTarget) setShowMilestoneModal(false) }}>
          <div className="rounded-2xl w-full max-w-md mx-4 overflow-hidden"
            style={{ backgroundColor:'var(--surface)', boxShadow:'0 20px 60px rgba(0,0,0,0.2)' }}>
            {/* Modal header */}
            <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
              <div className="flex items-center gap-2">
                <Flag size={15} style={{ color:'var(--primary-container)' }} />
                <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Financial Milestones</span>
              </div>
              <button onClick={() => setShowMilestoneModal(false)} style={{ color:'var(--on-surface-variant)' }}>
                <X size={16} />
              </button>
            </div>

            {/* Milestone list */}
            <div className="max-h-64 overflow-y-auto" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
              {milestones.length === 0 ? (
                <div className="py-8 text-center text-sm" style={{ color:'var(--on-surface-variant)' }}>No milestones yet. Add one below.</div>
              ) : milestones.map((m) => (
                <div key={m.id} className="flex items-center justify-between px-5 py-3"
                  style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate" style={{ color:'var(--on-surface)' }}>{m.label}</p>
                    <p className="text-xs font-mono mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{formatINR(m.target)}</p>
                  </div>
                  <button onClick={() => deleteMilestone(m.id)}
                    className="ml-3 p-1.5 rounded-lg transition-colors flex-shrink-0"
                    style={{ color:'var(--error)' }}
                    onMouseEnter={e => e.currentTarget.style.backgroundColor='rgba(186,26,26,0.1)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}
                  >
                    <Trash2 size={13} />
                  </button>
                </div>
              ))}
            </div>

            {/* Add new milestone */}
            <div className="px-5 py-4">
              <p className="text-xs font-semibold uppercase tracking-wider mb-3" style={{ color:'var(--on-surface-variant)' }}>Add Milestone</p>
              <div className="space-y-2">
                <input
                  type="text"
                  placeholder="Label (e.g. Emergency Fund)"
                  value={newLabel}
                  onChange={e => setNewLabel(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && addMilestone()}
                  className="w-full px-3 py-2 rounded-lg text-sm focus:outline-none"
                  style={{
                    border:'1px solid var(--outline-variant)', backgroundColor:'var(--surface-container-low)',
                    color:'var(--on-surface)',
                  }}
                />
                <div className="flex gap-2">
                  <input
                    type="number"
                    placeholder="Target amount (₹)"
                    value={newTarget}
                    onChange={e => setNewTarget(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && addMilestone()}
                    className="flex-1 px-3 py-2 rounded-lg text-sm focus:outline-none font-mono"
                    style={{
                      border:'1px solid var(--outline-variant)', backgroundColor:'var(--surface-container-low)',
                      color:'var(--on-surface)',
                    }}
                  />
                  <button onClick={addMilestone}
                    className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium"
                    style={{ backgroundColor:'var(--primary-container)', color:'white' }}
                  >
                    <Plus size={14} /> Add
                  </button>
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="px-5 pb-4 pt-0 flex justify-end">
              <button onClick={() => setShowMilestoneModal(false)}
                className="px-5 py-2 rounded-lg text-sm font-medium"
                style={{ backgroundColor:'var(--surface-container-low)', color:'var(--on-surface)' }}>
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
