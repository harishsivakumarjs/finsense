import { useEffect, useState } from 'react'
import { Plus, Search, Pencil, Trash2, TrendingUp, TrendingDown, Award, AlertCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate } from '../utils/format'
import useStore from '../store/useStore'

const BLANK_FORM = {
  scrip: '', trade_type: 'delivery', buy_price: '', sell_price: '', quantity: '',
  buy_date: new Date().toISOString().split('T')[0], sell_date: '', charges: '0', notes: '',
}

const TYPE_COLORS = {
  intraday:  { color: '#d4932a', bg: 'rgba(212,147,42,0.12)' },
  delivery:  { color: '#4a8ed4', bg: 'rgba(74,142,212,0.12)' },
  futures:   { color: '#8b7fd4', bg: 'rgba(139,127,212,0.12)' },
  options:   { color: '#2ab5a0', bg: 'rgba(42,181,160,0.12)' },
}

const Card = ({ children, className = '', style = {} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow: '0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

export default function Trading() {
  const { selectedFY } = useStore()
  const [trades, setTrades] = useState([])
  const [analytics, setAnalytics] = useState(null)
  const [pnlData, setPnlData] = useState([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState('closed')
  const [search, setSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [editTrade, setEditTrade] = useState(null)
  const [detail, setDetail] = useState(null)
  const [form, setForm] = useState(BLANK_FORM)

  const load = async () => {
    setLoading(true)
    try {
      const [tradesR, analyticsR, pnlR] = await Promise.all([
        api.get('/trades'),
        api.get('/trades/analytics'),
        api.get('/trades/pnl'),
      ])
      setTrades(tradesR.data)
      setAnalytics(analyticsR.data)
      const months = Object.entries(pnlR.data).map(([month, data]) => ({ month, pnl: data.pnl }))
      setPnlData(months)
    } catch { toast.error('Failed to load trading data') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [selectedFY])

  const openAdd = () => { setEditTrade(null); setForm(BLANK_FORM); setShowModal(true) }
  const openEdit = (trade) => {
    setEditTrade(trade)
    setForm({ scrip: trade.scrip, trade_type: trade.trade_type, buy_price: trade.buy_price, sell_price: trade.sell_price ?? '', quantity: trade.quantity, buy_date: trade.buy_date, sell_date: trade.sell_date ?? '', charges: trade.charges ?? '0', notes: trade.notes ?? '' })
    setShowModal(true)
  }
  const handleSave = async () => {
    if (!form.scrip || !form.buy_price || !form.quantity) return toast.error('Fill required fields')
    try {
      const payload = { ...form, buy_price: parseFloat(form.buy_price), sell_price: form.sell_price !== '' ? parseFloat(form.sell_price) : null, sell_date: form.sell_date || null, quantity: parseInt(form.quantity, 10), charges: parseFloat(form.charges) || 0 }
      if (editTrade) { await api.put(`/trades/${editTrade.id}`, payload); toast.success('Updated') }
      else { await api.post('/trades', payload); toast.success('Trade logged') }
      setShowModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const handleDelete = async (id) => {
    if (!confirm('Delete this trade?')) return
    try { await api.delete(`/trades/${id}`); toast.success('Deleted'); setShowModal(false); load() }
    catch { toast.error('Failed') }
  }

  const yearTrades = (() => {
    let list = selectedFY === 'all' ? trades : trades.filter(t => t.buy_date?.startsWith(selectedFY))
    if (dateFrom) list = list.filter(t => t.buy_date >= dateFrom)
    if (dateTo) list = list.filter(t => t.buy_date <= dateTo)
    return list
  })()
  const closedTrades = yearTrades.filter(t => t.sell_price !== null && t.sell_price !== undefined)
  const openTrades = yearTrades.filter(t => t.sell_price === null || t.sell_price === undefined)
  const filtered = (tab === 'closed' ? closedTrades : openTrades).filter(t =>
    t.scrip.toLowerCase().includes(search.toLowerCase()) && (typeFilter === '' || t.trade_type === typeFilter)
  )

  const a = analytics
  const winRate = a?.win_rate || 0
  const winRateColor = winRate > 60 ? '#006b5d' : winRate >= 40 ? '#d4932a' : '#ba1a1a'

  const getLivePnl = () => {
    const bp = parseFloat(form.buy_price), sp = parseFloat(form.sell_price), qty = parseFloat(form.quantity), ch = parseFloat(form.charges || 0)
    if (form.sell_price && form.buy_price && form.quantity && !isNaN(bp) && !isNaN(sp) && !isNaN(qty)) return (sp - bp) * qty - ch
    return null
  }
  const livePnl = getLivePnl()

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor: 'var(--background)', minHeight: '100%' }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: 'var(--on-surface)' }}>Trading</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>Track your trades and performance</p>
        </div>
        <button onClick={openAdd} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#2ab5a0', color: 'white' }}>
          <Plus size={16} /> Log Trade
        </button>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Net P&L', val: formatINR(a?.total_pnl ?? 0), color: (a?.total_pnl ?? 0) >= 0 ? '#006b5d' : '#ba1a1a', prefix: (a?.total_pnl ?? 0) >= 0 ? '+' : '', icon: <TrendingUp size={18} />, sub: 'All time' },
          { label: 'Win Rate', val: `${winRate.toFixed(1)}%`, color: winRateColor, prefix: '', icon: <Award size={18} />, sub: `${a?.total_trades || 0} trades` },
          { label: 'Best Trade', val: formatINR(a?.best_trade ?? 0), color:'var(--positive)', prefix: '+', icon: <TrendingUp size={18} />, sub: 'Single trade' },
          { label: 'Worst Trade', val: formatINR(a?.worst_trade ?? 0), color:'var(--error)', prefix: '-', icon: <TrendingDown size={18} />, sub: 'Single trade' },
        ].map(({ label, val, color, prefix, icon, sub }) => (
          <Card key={label} className="p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ backgroundColor: `${color}15`, color }}>
                {icon}
              </div>
            </div>
            <p className="text-2xl font-bold font-mono" style={{ color: 'var(--on-surface)' }}>
              {loading ? '—' : `${prefix}${val}`}
            </p>
            <p className="text-xs mt-1" style={{ color: 'var(--on-surface-variant)' }}>{sub}</p>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-5">
        {/* Monthly P&L Chart */}
        <Card className="col-span-2 p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>Monthly P&L Distribution</h3>
          {pnlData.length === 0 ? (
            <div className="h-48 flex items-center justify-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>No trade data yet</div>
          ) : (
            <ResponsiveContainer width="100%" height={180}>
              <BarChart data={pnlData} barSize={28}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--outline-variant)" vertical={false} />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: 'var(--on-surface-variant)' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: 'var(--on-surface-variant)' }} axisLine={false} tickLine={false} tickFormatter={v => `₹${Math.abs(v)>=1000?Math.round(v/1000)+'k':v}`} />
                <Tooltip formatter={v => formatINR(v)} contentStyle={{ backgroundColor: 'var(--surface)', border: '1px solid var(--outline-variant)', borderRadius: 8, fontSize: 12 }} />
                <Bar dataKey="pnl" radius={[4,4,0,0]}>
                  {pnlData.map((entry, i) => <Cell key={i} fill={entry.pnl >= 0 ? '#2ab5a0' : '#ba1a1a'} />)}
                </Bar>
              </BarChart>
            </ResponsiveContainer>
          )}
        </Card>

        {/* Execution Analytics */}
        <Card className="p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>Execution Analytics</h3>
          {loading ? (
            <div className="space-y-3">{[...Array(4)].map((_,i)=><div key={i} className="h-8 shimmer rounded"/>)}</div>
          ) : (
            <div className="space-y-4">
              {/* Win rate ring */}
              <div className="flex items-center gap-3">
                <svg width="56" height="56" viewBox="0 0 56 56">
                  <circle cx="28" cy="28" r="22" fill="none" stroke="var(--surface-container)" strokeWidth="6" />
                  <circle cx="28" cy="28" r="22" fill="none" stroke={winRateColor} strokeWidth="6"
                    strokeDasharray={2*Math.PI*22} strokeDashoffset={2*Math.PI*22*(1-winRate/100)}
                    strokeLinecap="round" transform="rotate(-90 28 28)" />
                  <text x="28" y="32" textAnchor="middle" fontSize="11" fontFamily="JetBrains Mono" fontWeight="600" fill={winRateColor}>{winRate.toFixed(0)}%</text>
                </svg>
                <div>
                  <p className="text-sm font-semibold" style={{ color: 'var(--on-surface)' }}>Win Rate</p>
                  <p className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>{a?.winning_trades || 0}W / {a?.losing_trades || 0}L</p>
                </div>
              </div>
              {/* Stats */}
              <div className="space-y-2">
                {[
                  { label: 'Avg Win', val: formatINR(a?.avg_win || 0), color:'var(--positive)' },
                  { label: 'Avg Loss', val: formatINR(a?.avg_loss || 0), color:'var(--error)' },
                  { label: 'Profit Factor', val: a?.profit_factor?.toFixed(2) || '—', color: 'var(--on-surface)' },
                ].map(({ label, val, color }) => (
                  <div key={label} className="flex items-center justify-between">
                    <span className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>{label}</span>
                    <span className="text-sm font-mono font-semibold" style={{ color }}>{val}</span>
                  </div>
                ))}
              </div>
              {/* Sector breakdown */}
              {a?.by_type && Object.entries(a.by_type).map(([type, data]) => {
                const tc = TYPE_COLORS[type] || { color: '#6c7a76', bg: 'rgba(108,122,118,0.12)' }
                return (
                  <div key={type}>
                    <div className="flex items-center justify-between mb-0.5">
                      <span className="text-xs capitalize font-medium" style={{ color: 'var(--on-surface)' }}>{type}</span>
                      <span className="text-xs font-mono" style={{ color: tc.color }}>{formatINR(data.pnl || 0)}</span>
                    </div>
                    <div className="h-1.5 rounded-full" style={{ backgroundColor: 'var(--surface-container)' }}>
                      <div className="h-full rounded-full" style={{ width: `${Math.min((Math.abs(data.pnl||0)/Math.max(1,Math.abs(a?.total_pnl||1)))*100,100)}%`, backgroundColor: tc.color }} />
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </Card>
      </div>

      {/* Trades Table */}
      <Card className="overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
          <div className="flex items-center gap-3">
            <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>Trade Log</h3>
            <div className="flex rounded-lg overflow-hidden" style={{ border: '1px solid var(--outline-variant)' }}>
              {['closed','open'].map(t => (
                <button key={t} onClick={() => setTab(t)}
                  className="px-4 py-1.5 text-xs font-semibold capitalize transition-colors"
                  style={{ backgroundColor: tab === t ? '#2ab5a0' : 'transparent', color: tab === t ? 'white' : 'var(--on-surface-variant)' }}>
                  {t} ({t === 'closed' ? closedTrades.length : openTrades.length})
                </button>
              ))}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)}
              className="px-3 py-2 rounded-lg text-xs focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              <option value="">All Types</option>
              {['intraday','delivery','futures','options'].map(t => <option key={t} value={t}>{t}</option>)}
            </select>
            <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
              title="From date"
              className="px-2 py-2 rounded-lg text-xs focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
            <span className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>–</span>
            <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
              title="To date"
              className="px-2 py-2 rounded-lg text-xs focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
            {(dateFrom || dateTo) && (
              <button onClick={() => { setDateFrom(''); setDateTo('') }}
                className="text-xs px-2 py-1 rounded"
                style={{ color: 'var(--on-surface-variant)' }}>✕</button>
            )}
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: 'var(--on-surface-variant)' }} />
              <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Search scrip..."
                className="pl-9 pr-4 py-2 rounded-lg text-sm focus:outline-none"
                style={{ width: 160, backgroundColor: 'var(--surface-container-low)', border: '1px solid var(--outline-variant)', color: 'var(--on-surface)' }} />
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor: 'var(--surface-container-low)' }}>
                {['Scrip','Type','Buy','Sell','Qty','P&L','Date','Actions'].map(h => (
                  <th key={h} className={`px-4 py-3 text-xs font-semibold uppercase tracking-wider ${['P&L','Actions'].includes(h)?'text-right':'text-left'}`}
                    style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_,i)=><tr key={i}><td colSpan={8} className="px-4 py-3"><div className="h-5 shimmer rounded" /></td></tr>)
              ) : filtered.length === 0 ? (
                <tr><td colSpan={8} className="px-4 py-12 text-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>
                  No {tab} trades. <button onClick={openAdd} style={{ color: 'var(--primary-container)' }} className="underline">Log a trade</button>
                </td></tr>
              ) : filtered.map(t => {
                const pnl = t.sell_price ? (parseFloat(t.sell_price) - parseFloat(t.buy_price)) * parseInt(t.quantity) - parseFloat(t.charges || 0) : null
                const tc = TYPE_COLORS[t.trade_type] || { color: '#6c7a76', bg: 'rgba(108,122,118,0.12)' }
                return (
                  <tr key={t.id} className="group" style={{ borderBottom: '1px solid var(--outline-variant)', cursor: 'pointer' }}
                    onClick={() => setDetail(t)}
                    onMouseEnter={e => e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}>
                    <td className="px-4 py-3.5 text-sm font-semibold" style={{ color: 'var(--on-surface)' }}>{t.scrip}</td>
                    <td className="px-4 py-3.5">
                      <span className="px-2 py-0.5 rounded-full text-xs font-semibold capitalize" style={{ backgroundColor: tc.bg, color: tc.color }}>{t.trade_type}</span>
                    </td>
                    <td className="px-4 py-3.5 text-sm font-mono" style={{ color: 'var(--on-surface)' }}>{formatINR(t.buy_price)}</td>
                    <td className="px-4 py-3.5 text-sm font-mono" style={{ color: 'var(--on-surface)' }}>{t.sell_price ? formatINR(t.sell_price) : <span style={{ color: 'var(--on-surface-variant)' }}>Open</span>}</td>
                    <td className="px-4 py-3.5 text-sm font-mono" style={{ color: 'var(--on-surface)' }}>{t.quantity}</td>
                    <td className="px-4 py-3.5 text-right text-sm font-mono font-semibold" style={{ color: pnl === null ? 'var(--on-surface-variant)' : pnl >= 0 ? '#006b5d' : '#ba1a1a' }}>
                      {pnl === null ? '—' : `${pnl >= 0 ? '+' : ''}${formatINR(pnl)}`}
                    </td>
                    <td className="px-4 py-3.5 text-sm" style={{ color: 'var(--on-surface-variant)' }}>{formatDate(t.buy_date)}</td>
                    <td className="px-4 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={e => e.stopPropagation()}>
                        <button onClick={() => openEdit(t)} className="p-1.5 rounded-lg" style={{ color: 'var(--on-surface-variant)' }}
                          onMouseEnter={e => e.currentTarget.style.color='var(--primary-container)'}
                          onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Pencil size={13} />
                        </button>
                        <button onClick={() => handleDelete(t.id)} className="p-1.5 rounded-lg" style={{ color: 'var(--on-surface-variant)' }}
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

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.scrip || 'Trade Detail'}
        color={TYPE_COLORS[detail?.trade_type]?.color || '#2ab5a0'}
        badge={detail?.trade_type}
        rows={(() => {
          if (!detail) return []
          const pnl = detail.sell_price ? (parseFloat(detail.sell_price) - parseFloat(detail.buy_price)) * parseInt(detail.quantity) - parseFloat(detail.charges || 0) : null
          return [
            { label: 'Scrip', value: detail.scrip },
            { label: 'Trade Type', value: detail.trade_type },
            { label: 'Buy Price', value: formatINR(detail.buy_price), valueStyle: { fontFamily: 'monospace' } },
            { label: 'Sell Price', value: detail.sell_price ? formatINR(detail.sell_price) : 'Open', valueStyle: { fontFamily: 'monospace' } },
            { label: 'Quantity', value: detail.quantity },
            { label: 'Buy Date', value: formatDate(detail.buy_date) },
            { label: 'Sell Date', value: detail.sell_date ? formatDate(detail.sell_date) : '—' },
            { label: 'Charges', value: formatINR(detail.charges || 0), valueStyle: { fontFamily: 'monospace' } },
            { label: 'P&L', value: pnl !== null ? `${pnl >= 0 ? '+' : ''}${formatINR(pnl)}` : '—', valueStyle: { fontFamily: 'monospace', color: pnl === null ? undefined : pnl >= 0 ? '#006b5d' : '#ba1a1a' } },
            { label: 'Notes', value: detail.notes || '—' },
          ]
        })()}
      />

      {/* Modal */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={editTrade ? 'Edit Trade' : 'Log Trade'}>
        <div className="space-y-4">
          {livePnl !== null && (
            <div className="p-3 rounded-lg text-center" style={{ backgroundColor: livePnl >= 0 ? 'rgba(0,107,93,0.08)' : 'rgba(186,26,26,0.08)' }}>
              <p className="text-xs mb-0.5" style={{ color: 'var(--on-surface-variant)' }}>Live P&L Preview</p>
              <p className="text-xl font-mono font-bold" style={{ color: livePnl >= 0 ? '#006b5d' : '#ba1a1a' }}>
                {livePnl >= 0 ? '+' : ''}{formatINR(livePnl)}
              </p>
            </div>
          )}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Trade Type</p>
            <select value={form.trade_type} onChange={e => setForm(p => ({ ...p, trade_type: e.target.value }))}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {['delivery','intraday','futures','options'].map(t => <option key={t} value={t}>{t.replace(/^\w/,c=>c.toUpperCase())}</option>)}
            </select>
          </div>
          {[
            { label: 'Scrip (e.g. RELIANCE)', key: 'scrip', type: 'text', placeholder: 'RELIANCE' },
            { label: 'Buy Price (₹)', key: 'buy_price', type: 'number', placeholder: '2500' },
            { label: 'Sell Price (₹)', key: 'sell_price', type: 'number', placeholder: '2650 (leave blank if still holding)' },
            { label: 'Quantity', key: 'quantity', type: 'number', placeholder: '10' },
            { label: 'Charges (₹)', key: 'charges', type: 'number', placeholder: '0' },
          ].map(({ label, key, type, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <input type={type} value={form[key]} onChange={e => setForm(p => ({ ...p, [key]: e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
            </div>
          ))}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Buy Date</p>
              <DatePickerInput value={form.buy_date} onChange={v => setForm(p => ({ ...p, buy_date: v }))} />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Sell Date</p>
              <DatePickerInput value={form.sell_date} onChange={v => setForm(p => ({ ...p, sell_date: v }))} />
            </div>
          </div>
          <div className="flex gap-3 pt-2">
            {editTrade && <button onClick={() => handleDelete(editTrade.id)} className="px-5 py-3 rounded-lg text-sm font-medium" style={{ color: 'var(--error)', border: '1px solid var(--error)', backgroundColor: 'var(--error-container)' }}>Delete</button>}
            <button onClick={() => setShowModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor: 'var(--outline-variant)', color: 'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={handleSave} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#2ab5a0', color: 'white' }}>{editTrade ? 'Save' : 'Log Trade'}</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
