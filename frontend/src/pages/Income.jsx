import { useEffect, useState } from 'react'
import { Plus, Search, Pencil, Trash2, TrendingUp, Wallet, ArrowUpRight } from 'lucide-react'
import toast from 'react-hot-toast'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate, getYearDateRange } from '../utils/format'
import useStore from '../store/useStore'

const SOURCE_TYPES = ['salary', 'pocket_money', 'freelance', 'youtube', 'trading', 'investment', 'other']
const TAX_CATEGORIES = ['salary', 'business', 'capital_gains', 'exempt', 'other']
const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

const SOURCE_COLORS = {
  salary: '#2ab5a0', pocket_money: '#8b7fd4', freelance: '#d4932a',
  youtube: '#ba1a1a', trading: '#4a8ed4', investment: '#006b5d', other: '#6c7a76',
}

const Card = ({ children, className = '', style = {} }) => (
  <div className={`rounded-xl bg-white ${className}`}
    style={{ boxShadow: '0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

const SLabel = ({ children }) => (
  <p className="text-xs font-semibold uppercase tracking-wider mb-1" style={{ color: 'var(--on-surface-variant)' }}>{children}</p>
)

export default function Income() {
  const { selectedFY } = useStore()
  const isAll = selectedFY === 'all'
  const today = new Date()
  const [month, setMonth] = useState(today.getMonth() + 1)
  const [year, setYear] = useState(today.getFullYear())
  const [pickerYear, setPickerYear] = useState(today.getFullYear())

  useEffect(() => {
    if (isAll) return
    const y = parseInt(selectedFY, 10)
    if (year !== y) { setYear(y); setPickerYear(y) }
  }, [selectedFY])
  const [incomes, setIncomes] = useState([])
  const [summary, setSummary] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showModal, setShowModal] = useState(false)
  const [showPicker, setShowPicker] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [detail, setDetail] = useState(null)
  const [form, setForm] = useState({
    amount: '', source_type: 'salary', description: '',
    received_on: today.toISOString().split('T')[0], tax_category: 'salary', is_taxable: true,
  })

  const load = async () => {
    setLoading(true)
    try {
      const [incRes, sumRes] = await Promise.all([
        api.get('/income', { params: { month, year } }),
        api.get('/income/streams', { params: { month, year } }),
      ])
      setIncomes(incRes.data)
      setSummary(Array.isArray(sumRes.data) ? sumRes.data : [])
    } catch { toast.error('Failed to load income') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [month, year])

  const totalIncome = incomes.reduce((s, i) => s + parseFloat(i.amount), 0)
  const topSource = summary.reduce((best, s) => (!best || s.total > best.total) ? s : best, null)
  const avgPerEntry = incomes.length ? totalIncome / incomes.length : 0
  const monthName = new Date(year, month - 1).toLocaleString('default', { month: 'long' })

  const openAdd = () => {
    setEditItem(null)
    setForm({ amount: '', source_type: 'salary', description: '', received_on: today.toISOString().split('T')[0], tax_category: 'salary', is_taxable: true })
    setShowModal(true)
  }
  const openEdit = (item) => {
    setEditItem(item)
    setForm({ amount: item.amount, source_type: item.source_type, description: item.description || '', received_on: item.received_on, tax_category: item.tax_category || 'salary', is_taxable: item.is_taxable !== false })
    setShowModal(true)
  }
  const handleSave = async () => {
    if (!form.amount) return toast.error('Amount required')
    try {
      if (editItem) { await api.put(`/income/${editItem.id}`, form); toast.success('Updated') }
      else { await api.post('/income', form); toast.success('Added') }
      setShowModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const handleDelete = async (id) => {
    if (!confirm('Delete this entry?')) return
    try { await api.delete(`/income/${id}`); toast.success('Deleted'); setShowModal(false); load() }
    catch { toast.error('Failed to delete') }
  }

  const filtered = incomes.filter(i =>
    (i.description || '').toLowerCase().includes(search.toLowerCase()) ||
    i.source_type.toLowerCase().includes(search.toLowerCase())
  )

  const barData = summary.map(s => ({ name: s.source_type.replace('_', ' '), value: s.total, fill: SOURCE_COLORS[s.source_type] || '#6c7a76' }))

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor: 'var(--background)', minHeight: '100%' }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: 'var(--on-surface)' }}>Income</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>Track your income sources</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Month picker */}
          <div className="relative">
            <button onClick={() => { setPickerYear(year); setShowPicker(!showPicker) }}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border transition-colors"
              style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {monthName} {year} <span className="text-xs opacity-60">▾</span>
            </button>
            {showPicker && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowPicker(false)} />
                <div className="absolute top-full mt-2 right-0 z-50 rounded-xl p-4 w-64"
                  style={{ backgroundColor: 'var(--surface)', boxShadow: 'var(--shadow-md)', border: '1px solid var(--outline-variant)' }}>
                  <div className="flex items-center justify-between mb-3">
                    <button onClick={() => isAll && setPickerYear(y => y-1)} style={{ color:'var(--on-surface-variant)', opacity:isAll?1:0.3 }} className="w-7 h-7 flex items-center justify-center rounded-lg text-lg">‹</button>
                    <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{pickerYear}</span>
                    <button onClick={() => isAll && setPickerYear(y => y+1)} style={{ color:'var(--on-surface-variant)', opacity:isAll?1:0.3 }} className="w-7 h-7 flex items-center justify-center rounded-lg text-lg">›</button>
                  </div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider mb-2 text-center" style={{ color:'var(--primary-container)' }}>
                    {isAll ? 'All Years (Jan–Dec)' : `Year ${selectedFY} (Jan–Dec)`}
                  </p>
                  <div className="grid grid-cols-4 gap-1.5">
                    {MONTHS.map((m, i) => {
                      const active = month === i+1 && year === pickerYear
                      return (
                        <button key={m}
                          onClick={() => { setMonth(i+1); setYear(pickerYear); setShowPicker(false) }}
                          className="py-1.5 rounded-lg text-xs font-medium transition-all"
                          style={{ backgroundColor:active?'var(--primary-container)':'var(--surface-container-low)', color:active?'white':'var(--on-surface-variant)' }}>
                          {m}
                        </button>
                      )
                    })}
                  </div>
                </div>
              </>
            )}
          </div>
          <button onClick={openAdd}
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all"
            style={{ backgroundColor: '#2ab5a0', color: 'white' }}>
            <Plus size={16} /> Add Income
          </button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: 'Total Income', value: formatINR(totalIncome), icon: <TrendingUp size={18} />, color: '#2ab5a0', sub: `${incomes.length} entries` },
          { label: 'Top Source', value: topSource ? formatINR(topSource.total) : '₹0', icon: <ArrowUpRight size={18} />, color:'var(--positive)', sub: topSource?.source_type?.replace('_', ' ') || 'No data' },
          { label: 'Avg Per Entry', value: formatINR(avgPerEntry), icon: <Wallet size={18} />, color: '#d4932a', sub: 'Average amount' },
          { label: 'Income Streams', value: summary.length.toString(), icon: <TrendingUp size={18} />, color: '#4a8ed4', sub: 'Active sources' },
        ].map(({ label, value, icon, color, sub }) => (
          <Card key={label} className="p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ backgroundColor: `${color}15`, color }}>
                {icon}
              </div>
            </div>
            <p className="text-2xl font-bold font-mono" style={{ color: 'var(--on-surface)' }}>{loading ? '—' : value}</p>
            <p className="text-xs mt-1 capitalize" style={{ color: 'var(--on-surface-variant)' }}>{sub}</p>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-5">
        {/* Bar Chart */}
        <Card className="col-span-2 p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>Income By Source</h3>
          {loading || barData.length === 0 ? (
            <div className="h-48 flex items-center justify-center" style={{ color: 'var(--on-surface-variant)' }}>
              {loading ? 'Loading...' : 'No data this month'}
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={180}>
              <BarChart data={barData} barSize={28}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--outline-variant)" vertical={false} />
                <XAxis dataKey="name" tick={{ fontSize: 11, fill: 'var(--on-surface-variant)' }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fontSize: 11, fill: 'var(--on-surface-variant)' }} axisLine={false} tickLine={false} tickFormatter={v => `₹${v >= 1000 ? (v/1000).toFixed(0)+'k' : v}`} />
                <Tooltip formatter={(v) => formatINR(v)} contentStyle={{ backgroundColor: 'var(--surface)', border: '1px solid var(--outline-variant)', borderRadius: 8, fontSize: 12 }} />
                <Bar dataKey="value" radius={[4,4,0,0]} fill="var(--primary-container)" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </Card>

        {/* Source Breakdown */}
        <Card className="p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>Source Breakdown</h3>
          {loading ? (
            <div className="space-y-3">{[...Array(4)].map((_, i) => <div key={i} className="h-8 rounded shimmer" />)}</div>
          ) : summary.length === 0 ? (
            <p className="text-sm text-center py-8" style={{ color: 'var(--on-surface-variant)' }}>No income this month</p>
          ) : (
            <div className="space-y-4">
              {summary.map(s => {
                const pct = totalIncome > 0 ? (s.total / totalIncome) * 100 : 0
                const color = SOURCE_COLORS[s.source_type] || '#6c7a76'
                return (
                  <div key={s.source_type}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-sm capitalize font-medium" style={{ color: 'var(--on-surface)' }}>{s.source_type.replace('_', ' ')}</span>
                      <span className="text-sm font-mono font-semibold" style={{ color }}>{formatINR(s.total)}</span>
                    </div>
                    <div className="h-1.5 rounded-full" style={{ backgroundColor: 'var(--surface-container)' }}>
                      <div className="h-full rounded-full transition-all" style={{ width: `${pct}%`, backgroundColor: color }} />
                    </div>
                    <p className="text-xs mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>{pct.toFixed(1)}% of total</p>
                  </div>
                )
              })}
            </div>
          )}
        </Card>
      </div>

      {/* All Income Entries Table */}
      <Card className="overflow-hidden">
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
          <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>All Income Entries</h3>
          <div className="relative">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: 'var(--on-surface-variant)' }} />
            <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..."
              className="pl-9 pr-4 py-2 rounded-lg text-sm focus:outline-none"
              style={{ width: 200, backgroundColor: 'var(--surface-container-low)', border: '1px solid var(--outline-variant)', color: 'var(--on-surface)' }} />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor: 'var(--surface-container-low)' }}>
                {['Date','Description','Source','Tax Cat.','Amount','Actions'].map(h => (
                  <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${h === 'Amount' || h === 'Actions' ? 'text-right' : 'text-left'}`}
                    style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i}><td colSpan={6} className="px-5 py-3"><div className="h-5 rounded shimmer" /></td></tr>
                ))
              ) : filtered.length === 0 ? (
                <tr><td colSpan={6} className="px-5 py-12 text-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>
                  No income entries for {monthName} {year}.{' '}
                  <button onClick={openAdd} style={{ color: 'var(--primary-container)' }} className="underline">Add one</button>
                </td></tr>
              ) : filtered.map(i => (
                <tr key={i.id} className="group transition-colors" style={{ borderBottom: '1px solid var(--outline-variant)', cursor: 'pointer' }}
                  onClick={() => setDetail(i)}
                  onMouseEnter={e => e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
                  onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}>
                  <td className="px-5 py-3.5 text-sm" style={{ color: 'var(--on-surface-variant)' }}>{formatDate(i.received_on)}</td>
                  <td className="px-5 py-3.5 text-sm font-medium" style={{ color: 'var(--on-surface)' }}>{i.description || '—'}</td>
                  <td className="px-5 py-3.5">
                    <span className="px-2.5 py-1 rounded-full text-xs font-semibold capitalize"
                      style={{ backgroundColor: `${SOURCE_COLORS[i.source_type] || '#6c7a76'}18`, color: SOURCE_COLORS[i.source_type] || '#6c7a76' }}>
                      {i.source_type.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-5 py-3.5 text-sm capitalize" style={{ color: 'var(--on-surface-variant)' }}>{(i.tax_category || 'other').replace('_', ' ')}</td>
                  <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color: 'var(--primary)' }}>+{formatINR(i.amount)}</td>
                  <td className="px-5 py-3.5 text-right">
                    <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={e => e.stopPropagation()}>
                      <button onClick={() => openEdit(i)} className="p-1.5 rounded-lg transition-colors"
                        style={{ color: 'var(--on-surface-variant)' }}
                        onMouseEnter={e => e.currentTarget.style.color = 'var(--primary-container)'}
                        onMouseLeave={e => e.currentTarget.style.color = 'var(--on-surface-variant)'}>
                        <Pencil size={13} />
                      </button>
                      <button onClick={() => handleDelete(i.id)} className="p-1.5 rounded-lg transition-colors"
                        style={{ color: 'var(--on-surface-variant)' }}
                        onMouseEnter={e => e.currentTarget.style.color = 'var(--error)'}
                        onMouseLeave={e => e.currentTarget.style.color = 'var(--on-surface-variant)'}>
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.description || detail?.source_type || 'Income Detail'}
        color={SOURCE_COLORS[detail?.source_type] || '#2ab5a0'}
        badge={detail?.source_type?.replace('_', ' ')}
        rows={detail ? [
          { label: 'Date', value: formatDate(detail.received_on) },
          { label: 'Description', value: detail.description || '—' },
          { label: 'Source Type', value: detail.source_type?.replace('_', ' ') },
          { label: 'Tax Category', value: detail.tax_category?.replace('_', ' ') },
          { label: 'Taxable', value: detail.is_taxable ? 'Yes' : 'No' },
          { label: 'Amount', value: `+${formatINR(detail.amount)}`, valueStyle: { color: '#2ab5a0', fontFamily: 'monospace' } },
        ] : []}
      />

      {/* Modal */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={editItem ? 'Edit Income' : 'Add Income'}>
        <div className="space-y-4">
          <div>
            <SLabel>Amount (₹)</SLabel>
            <input type="number" value={form.amount} onChange={e => setForm(p => ({ ...p, amount: e.target.value }))}
              placeholder="25000" className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
          </div>
          <div>
            <SLabel>Source Type</SLabel>
            <select value={form.source_type} onChange={e => setForm(p => ({ ...p, source_type: e.target.value }))}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {SOURCE_TYPES.map(s => <option key={s} value={s}>{s.replace('_',' ').replace(/^\w/,c=>c.toUpperCase())}</option>)}
            </select>
          </div>
          <div>
            <SLabel>Description</SLabel>
            <input type="text" value={form.description} onChange={e => setForm(p => ({ ...p, description: e.target.value }))}
              placeholder="Salary for May 2026" className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
          </div>
          <div>
            <SLabel>Received On</SLabel>
            <DatePickerInput value={form.received_on} onChange={v => setForm(p => ({ ...p, received_on: v }))} />
          </div>
          <div>
            <SLabel>Tax Category</SLabel>
            <select value={form.tax_category} onChange={e => setForm(p => ({ ...p, tax_category: e.target.value }))}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {TAX_CATEGORIES.map(t => <option key={t} value={t}>{t.replace('_',' ').replace(/^\w/,c=>c.toUpperCase())}</option>)}
            </select>
          </div>
          <div className="flex items-center gap-3">
            <label className="toggle-switch">
              <input type="checkbox" checked={form.is_taxable} onChange={e => setForm(p => ({ ...p, is_taxable: e.target.checked }))} />
              <span className="toggle-slider" />
            </label>
            <span className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>Taxable income</span>
          </div>
          <div className="flex gap-3 pt-2">
            {editItem && (
              <button onClick={() => handleDelete(editItem.id)}
                className="px-5 py-3 rounded-lg text-sm font-medium border"
                style={{ color: 'var(--error)', borderColor: 'var(--error)', backgroundColor: 'var(--error-container)' }}>
                Delete
              </button>
            )}
            <button onClick={() => setShowModal(false)}
              className="flex-1 py-3 rounded-lg text-sm font-medium border transition-colors"
              style={{ borderColor: 'var(--outline-variant)', color: 'var(--on-surface-variant)', backgroundColor: 'transparent' }}>
              Cancel
            </button>
            <button onClick={handleSave}
              className="flex-1 py-3 rounded-lg text-sm font-semibold transition-all"
              style={{ backgroundColor: '#2ab5a0', color: 'white' }}>
              {editItem ? 'Save Changes' : 'Add Income'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
