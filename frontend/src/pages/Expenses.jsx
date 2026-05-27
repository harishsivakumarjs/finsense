import { useEffect, useState } from 'react'
import { Plus, Search, Pencil, Trash2, Receipt, Target, DollarSign } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate, getYearDateRange } from '../utils/format'
import useStore from '../store/useStore'

const CATEGORIES = ['food','transport','bills','health','entertainment','shopping','subscriptions','education','other']
const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
const BUDGET_KEY = 'finsense_monthly_budget'

const CAT_COLORS = {
  food: '#d4932a', transport: '#4a8ed4', health: '#ba1a1a',
  entertainment: '#8b7fd4', shopping: '#2ab5a0', subscriptions: '#006b5d',
  education: '#4f5e80', bills: '#9a442c', other: '#6c7a76',
}

const Card = ({ children, className = '', style = {} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow: '0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

export default function Expenses() {
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
  const [showPicker, setShowPicker] = useState(false)
  const [expenses, setExpenses] = useState([])
  const [summary, setSummary] = useState([])
  const [subscriptions, setSubscriptions] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [catFilter, setCatFilter] = useState('all')
  const [showModal, setShowModal] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [detail, setDetail] = useState(null)
  const [budget, setBudget] = useState(() => parseInt(localStorage.getItem(BUDGET_KEY) || '50000', 10))
  const [form, setForm] = useState({
    amount: '', category: 'food', description: '',
    spent_on: today.toISOString().split('T')[0], is_recurring: false, is_creator_expense: false,
  })

  const load = async () => {
    setLoading(true)
    try {
      const [expRes, sumRes, subRes] = await Promise.all([
        api.get('/expenses', { params: { month, year } }),
        api.get('/expenses/summary', { params: { month, year } }),
        api.get('/expenses/subscriptions'),
      ])
      setExpenses(expRes.data)
      setSummary(sumRes.data)
      setSubscriptions(subRes.data)
    } catch { toast.error('Failed to load') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [month, year])

  const totalSpent = expenses.reduce((s, e) => s + parseFloat(e.amount), 0)
  const remaining = budget - totalSpent
  const monthName = new Date(year, month - 1).toLocaleString('default', { month: 'long' })

  const openAdd = () => {
    setEditItem(null)
    setForm({ amount: '', category: 'food', description: '', spent_on: today.toISOString().split('T')[0], is_recurring: false, is_creator_expense: false })
    setShowModal(true)
  }
  const openEdit = (item) => {
    setEditItem(item)
    setForm({ amount: item.amount, category: item.category, description: item.description || '', spent_on: item.spent_on, is_recurring: item.is_recurring || false, is_creator_expense: item.is_creator_expense || false })
    setShowModal(true)
  }
  const handleSave = async () => {
    if (!form.amount) return toast.error('Amount required')
    try {
      if (editItem) { await api.put(`/expenses/${editItem.id}`, form); toast.success('Updated') }
      else { await api.post('/expenses', form); toast.success('Added') }
      setShowModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const handleDelete = async (id) => {
    if (!confirm('Delete this expense?')) return
    try { await api.delete(`/expenses/${id}`); toast.success('Deleted'); setShowModal(false); load() }
    catch { toast.error('Failed to delete') }
  }
  const toggleSub = async (id, active) => {
    try {
      await api.patch(`/expenses/subscriptions/${id}`, { is_active: !active })
      load()
    } catch { toast.error('Failed to update') }
  }

  const filtered = expenses.filter(e => {
    const matchSearch = (e.description || '').toLowerCase().includes(search.toLowerCase()) || e.category.toLowerCase().includes(search.toLowerCase())
    const matchCat = catFilter === 'all' || e.category === catFilter
    return matchSearch && matchCat
  })

  // Group by date
  const grouped = filtered.reduce((acc, e) => {
    if (!acc[e.spent_on]) acc[e.spent_on] = []
    acc[e.spent_on].push(e)
    return acc
  }, {})
  const sortedDates = Object.keys(grouped).sort((a, b) => new Date(b) - new Date(a))

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor: 'var(--background)', minHeight: '100%' }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: 'var(--on-surface)' }}>Expenses</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>Track and manage your spending</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="relative">
            <button onClick={() => { setPickerYear(year); setShowPicker(!showPicker) }}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border"
              style={{ backgroundColor: 'var(--surface)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {monthName} {year} <span className="text-xs opacity-60">▾</span>
            </button>
            {showPicker && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowPicker(false)} />
                <div className="absolute top-full mt-2 right-0 z-50 rounded-xl p-4 w-64"
                  style={{ backgroundColor: 'var(--surface)', boxShadow: 'var(--shadow-md)', border: '1px solid var(--outline-variant)' }}>
                  <div className="flex items-center justify-between mb-3">
                    <button onClick={() => !isAll ? null : setPickerYear(y => y-1)} style={{ color:'var(--on-surface-variant)', opacity:isAll?1:0.3 }} className="w-7 h-7 flex items-center justify-center text-lg">‹</button>
                    <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{pickerYear}</span>
                    <button onClick={() => !isAll ? null : setPickerYear(y => y+1)} style={{ color:'var(--on-surface-variant)', opacity:isAll?1:0.3 }} className="w-7 h-7 flex items-center justify-center text-lg">›</button>
                  </div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider mb-2 text-center" style={{ color:'var(--primary-container)' }}>
                    {isAll ? 'All Years (Jan–Dec)' : `Year ${selectedFY} (Jan–Dec)`}
                  </p>
                  <div className="grid grid-cols-4 gap-1.5">
                    {MONTHS.map((m,i) => {
                      const active = month===i+1 && year===pickerYear
                      return (
                        <button key={m}
                          onClick={() => { setMonth(i+1); setYear(pickerYear); setShowPicker(false) }}
                          className="py-1.5 rounded-lg text-xs font-medium"
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
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold"
            style={{ backgroundColor: '#2ab5a0', color: 'white' }}>
            <Plus size={16} /> Add Expense
          </button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Total Spent', value: formatINR(totalSpent), icon: <Receipt size={18} />, color:'var(--error)', sub: `${expenses.length} transactions` },
          { label: 'Monthly Budget', value: formatINR(budget), icon: <Target size={18} />, color: '#2ab5a0', sub: 'Set budget limit' },
          { label: remaining >= 0 ? 'Remaining' : 'Over Budget', value: formatINR(Math.abs(remaining)), icon: <DollarSign size={18} />, color: remaining >= 0 ? '#006b5d' : '#ba1a1a', sub: remaining >= 0 ? `${((totalSpent/budget)*100).toFixed(0)}% used` : 'Budget exceeded' },
        ].map(({ label, value, icon, color, sub }) => (
          <Card key={label} className="p-5">
            <div className="flex items-center justify-between mb-3">
              <p className="text-xs font-semibold uppercase tracking-wider" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ backgroundColor: `${color}15`, color }}>
                {icon}
              </div>
            </div>
            <p className="text-2xl font-bold font-mono" style={{ color: 'var(--on-surface)' }}>{loading ? '—' : value}</p>
            <p className="text-xs mt-1" style={{ color: 'var(--on-surface-variant)' }}>{sub}</p>
          </Card>
        ))}
      </div>

      {/* Main content: col-span-5 left, col-span-7 right */}
      <div className="grid grid-cols-12 gap-5">
        {/* LEFT — Category bars + Subscriptions */}
        <div className="col-span-5 space-y-4">
          <Card className="p-5">
            <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>Spending by Category</h3>
            {loading ? (
              <div className="space-y-3">{[...Array(5)].map((_,i)=><div key={i} className="h-8 shimmer rounded"/>)}</div>
            ) : summary.length === 0 ? (
              <p className="text-sm py-8 text-center" style={{ color: 'var(--on-surface-variant)' }}>No expenses this month</p>
            ) : (
              <div className="space-y-3">
                {[...summary].sort((a,b) => b.total - a.total).map(s => {
                  const pct = totalSpent > 0 ? (s.total/totalSpent)*100 : 0
                  const color = CAT_COLORS[s.category] || '#6c7a76'
                  return (
                    <div key={s.category}>
                      <div className="flex items-center justify-between mb-1">
                        <div className="flex items-center gap-2">
                          <div className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
                          <span className="text-sm font-medium capitalize" style={{ color: 'var(--on-surface)' }}>{s.category}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-mono font-semibold" style={{ color }}>{formatINR(s.total)}</span>
                          <span className="text-xs w-8 text-right" style={{ color: 'var(--on-surface-variant)' }}>{pct.toFixed(0)}%</span>
                        </div>
                      </div>
                      <div className="h-1.5 rounded-full" style={{ backgroundColor: 'var(--surface-container)' }}>
                        <div className="h-full rounded-full" style={{ width: `${pct}%`, backgroundColor: color }} />
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </Card>

          <Card className="p-5">
            <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>Subscriptions</h3>
            {loading ? (
              <div className="space-y-3">{[...Array(3)].map((_,i)=><div key={i} className="h-10 shimmer rounded"/>)}</div>
            ) : subscriptions.length === 0 ? (
              <p className="text-sm py-6 text-center" style={{ color: 'var(--on-surface-variant)' }}>No subscriptions</p>
            ) : (
              <div className="space-y-3">
                {subscriptions.slice(0, 8).map(sub => {
                  const color = CAT_COLORS[sub.category] || '#6c7a76'
                  return (
                    <div key={sub.id} className="flex items-center justify-between py-1">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-lg flex items-center justify-center text-xs font-bold"
                          style={{ backgroundColor: `${color}18`, color }}>
                          {sub.description?.slice(0,2).toUpperCase()||'SB'}
                        </div>
                        <div>
                          <p className="text-sm font-medium leading-tight" style={{ color: 'var(--on-surface)' }}>{sub.description||sub.category}</p>
                          <p className="text-xs capitalize" style={{ color: 'var(--on-surface-variant)' }}>{sub.category} · {formatINR(sub.amount)}/mo</p>
                        </div>
                      </div>
                      <label className="toggle-switch flex-shrink-0">
                        <input type="checkbox" checked={sub.is_active !== false} onChange={() => toggleSub(sub.id, sub.is_active !== false)} />
                        <span className="toggle-slider" />
                      </label>
                    </div>
                  )
                })}
              </div>
            )}
          </Card>
        </div>

        {/* RIGHT — Expenses Table */}
        <Card className="col-span-7 overflow-hidden">
          <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
            <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>All Expenses</h3>
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color: 'var(--on-surface-variant)' }} />
              <input type="text" value={search} onChange={e => setSearch(e.target.value)} placeholder="Search..."
                className="pl-9 pr-4 py-2 rounded-lg text-sm focus:outline-none"
                style={{ width: 180, backgroundColor: 'var(--surface-container-low)', border: '1px solid var(--outline-variant)', color: 'var(--on-surface)' }} />
            </div>
          </div>
          {/* Category filter chips */}
          <div className="px-5 py-3 flex items-center gap-2 overflow-x-auto" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
            {['all', ...CATEGORIES].map(cat => (
              <button key={cat} onClick={() => setCatFilter(cat)}
                className="px-3 py-1 rounded-full text-xs font-semibold capitalize whitespace-nowrap transition-all"
                style={{
                  backgroundColor: catFilter === cat ? (cat === 'all' ? '#2ab5a0' : `${CAT_COLORS[cat]}20`) : 'var(--surface-container-low)',
                  color: catFilter === cat ? (cat === 'all' ? 'white' : CAT_COLORS[cat]) : 'var(--on-surface-variant)',
                  border: `1px solid ${catFilter === cat ? (cat === 'all' ? '#2ab5a0' : CAT_COLORS[cat]) : 'var(--outline-variant)'}`,
                }}>
                {cat}
              </button>
            ))}
          </div>
          <div className="overflow-x-auto" style={{ maxHeight:600 }}>
            <table className="w-full">
              <thead className="sticky top-0" style={{ backgroundColor:'var(--surface)' }}>
                <tr style={{ backgroundColor: 'var(--surface-container-low)' }}>
                  {['Date','Description','Category','Amount','Actions'].map(h => (
                    <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${h==='Amount'||h==='Actions'?'text-right':'text-left'}`}
                      style={{ color: 'var(--on-surface-variant)', borderBottom: '1px solid var(--outline-variant)' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  [...Array(5)].map((_,i) => <tr key={i}><td colSpan={5} className="px-5 py-3"><div className="h-5 rounded shimmer" /></td></tr>)
                ) : sortedDates.length === 0 ? (
                  <tr><td colSpan={5} className="px-5 py-12 text-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>
                    No expenses found. <button onClick={openAdd} style={{ color: 'var(--primary-container)' }} className="underline">Add one</button>
                  </td></tr>
                ) : sortedDates.map(date => (
                  <>
                    <tr key={`date-${date}`}>
                      <td colSpan={5} className="px-5 py-2 text-xs font-semibold uppercase tracking-wider"
                        style={{ backgroundColor: 'var(--surface-container)', color: 'var(--on-surface-variant)' }}>
                        {formatDate(date)}
                      </td>
                    </tr>
                    {grouped[date].map(e => (
                      <tr key={e.id} className="group transition-colors" style={{ borderBottom: '1px solid var(--outline-variant)', cursor: 'pointer' }}
                        onClick={() => setDetail(e)}
                        onMouseEnter={ev => ev.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
                        onMouseLeave={ev => ev.currentTarget.style.backgroundColor = 'transparent'}>
                        <td className="px-5 py-3.5 text-xs" style={{ color: 'var(--on-surface-variant)' }}>{formatDate(e.spent_on)}</td>
                        <td className="px-5 py-3.5 text-sm font-medium" style={{ color: 'var(--on-surface)' }}>{e.description || '—'}</td>
                        <td className="px-5 py-3.5">
                          <span className="px-2.5 py-1 rounded-full text-xs font-semibold capitalize"
                            style={{ backgroundColor: `${CAT_COLORS[e.category]||'#6c7a76'}18`, color: CAT_COLORS[e.category]||'#6c7a76' }}>
                            {e.category}
                          </span>
                        </td>
                        <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color: 'var(--error)' }}>-{formatINR(e.amount)}</td>
                        <td className="px-5 py-3.5 text-right">
                          <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={ev => ev.stopPropagation()}>
                            <button onClick={() => openEdit(e)} className="p-1.5 rounded-lg"
                              style={{ color: 'var(--on-surface-variant)' }}
                              onMouseEnter={ev => ev.currentTarget.style.color = 'var(--primary-container)'}
                              onMouseLeave={ev => ev.currentTarget.style.color = 'var(--on-surface-variant)'}>
                              <Pencil size={13} />
                            </button>
                            <button onClick={() => handleDelete(e.id)} className="p-1.5 rounded-lg"
                              style={{ color: 'var(--on-surface-variant)' }}
                              onMouseEnter={ev => ev.currentTarget.style.color = 'var(--error)'}
                              onMouseLeave={ev => ev.currentTarget.style.color = 'var(--on-surface-variant)'}>
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      </div>

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.description || detail?.category || 'Expense Detail'}
        color={CAT_COLORS[detail?.category] || '#6c7a76'}
        badge={detail?.category}
        rows={detail ? [
          { label: 'Date', value: formatDate(detail.spent_on) },
          { label: 'Description', value: detail.description || '—' },
          { label: 'Category', value: detail.category },
          { label: 'Recurring', value: detail.is_recurring ? 'Yes' : 'No' },
          { label: 'Amount', value: `-${formatINR(detail.amount)}`, valueStyle: { color: 'var(--error)', fontFamily: 'monospace' } },
        ] : []}
      />

      {/* Modal */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={editItem ? 'Edit Expense' : 'Add Expense'}>
        <div className="space-y-4">
          {[
            { label: 'Amount (₹)', key: 'amount', type: 'number', placeholder: '500' },
            { label: 'Description', key: 'description', type: 'text', placeholder: 'Lunch at restaurant' },
          ].map(({ label, key, type, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <input type={type} value={form[key]} onChange={e => setForm(p => ({ ...p, [key]: e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
            </div>
          ))}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Category</p>
            <select value={form.category} onChange={e => setForm(p => ({ ...p, category: e.target.value }))}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {CATEGORIES.map(c => <option key={c} value={c}>{c.replace(/^\w/,s=>s.toUpperCase())}</option>)}
            </select>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Date</p>
            <DatePickerInput value={form.spent_on} onChange={v => setForm(p => ({ ...p, spent_on: v }))} />
          </div>
          <div className="flex items-center gap-3">
            <label className="toggle-switch">
              <input type="checkbox" checked={form.is_recurring} onChange={e => setForm(p => ({ ...p, is_recurring: e.target.checked }))} />
              <span className="toggle-slider" />
            </label>
            <span className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>Recurring expense</span>
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
              className="flex-1 py-3 rounded-lg text-sm font-medium border"
              style={{ borderColor: 'var(--outline-variant)', color: 'var(--on-surface-variant)' }}>
              Cancel
            </button>
            <button onClick={handleSave}
              className="flex-1 py-3 rounded-lg text-sm font-semibold"
              style={{ backgroundColor: '#2ab5a0', color: 'white' }}>
              {editItem ? 'Save Changes' : 'Add Expense'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
