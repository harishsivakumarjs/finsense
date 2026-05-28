import { useEffect, useState } from 'react'
import {
  Plus, DollarSign, CreditCard, Activity, TrendingUp, TrendingDown,
  Utensils, Car, Zap, Heart, Film, ShoppingBag, BookOpen, BarChart2, ArrowDownCircle, CalendarClock,
} from 'lucide-react'
import toast from 'react-hot-toast'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import useStore from '../store/useStore'
import api from '../api/axios'
import MetricCard from '../components/MetricCard'
import AlertCard from '../components/AlertCard'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatRelativeDate } from '../utils/format'

const SOURCE_TYPES = ['salary','pocket_money','freelance','youtube','trading','investment','other']
const TAX_CATEGORIES = ['salary','business','capital_gains','exempt','other']

const QUICK_ADD_TYPES = ['expense', 'income']

const CAT_ICONS = {
  food:          { Icon:Utensils,     color:'#d4932a', bg:'rgba(212,147,42,0.12)' },
  transport:     { Icon:Car,          color:'#4a8ed4', bg:'rgba(74,142,212,0.12)' },
  bills:         { Icon:Zap,          color:'var(--error)', bg:'rgba(186,26,26,0.12)' },
  health:        { Icon:Heart,        color:'var(--error)', bg:'rgba(186,26,26,0.12)' },
  entertainment: { Icon:Film,         color:'#8b7fd4', bg:'rgba(139,127,212,0.12)' },
  shopping:      { Icon:ShoppingBag,  color:'#2ab5a0', bg:'rgba(42,181,160,0.12)' },
  education:     { Icon:BookOpen,     color:'#4a8ed4', bg:'rgba(74,142,212,0.12)' },
  subscriptions: { Icon:Activity,     color:'#8b7fd4', bg:'rgba(139,127,212,0.12)' },
}

function getActivityMeta(item) {
  if (item.type === 'income')     return { Icon:ArrowDownCircle, color:'var(--positive)', bg:'rgba(0,107,93,0.12)' }
  if (item.type === 'trade')      return { Icon:BarChart2,       color:'#4a8ed4', bg:'rgba(74,142,212,0.12)' }
  if (item.type === 'investment') return { Icon:TrendingUp,      color:'#8b7fd4', bg:'rgba(139,127,212,0.12)' }
  return CAT_ICONS[item.category] || { Icon:TrendingDown, color:'var(--error)', bg:'rgba(186,26,26,0.12)' }
}

function dtiColor(v) {
  if (v < 20) return '#006b5d'
  if (v < 40) return '#4a8ed4'
  if (v < 70) return '#d4932a'
  return '#ba1a1a'
}

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

function IncomeExpenseChart({ data, loading }) {
  if (loading) return <div className="h-44 shimmer rounded-xl" />
  if (!data?.length) return (
    <div className="h-44 flex items-center justify-center text-sm" style={{ color:'var(--on-surface-variant)' }}>
      No data yet — add income &amp; expenses
    </div>
  )
  return (
    <ResponsiveContainer width="100%" height={160}>
      <BarChart data={data} barSize={10} barGap={2}>
        <CartesianGrid strokeDasharray="3 3" stroke="var(--outline-variant)" vertical={false} />
        <XAxis dataKey="month" tick={{ fontSize:10, fill:'var(--on-surface-variant)' }} axisLine={false} tickLine={false} />
        <YAxis tick={{ fontSize:10, fill:'var(--on-surface-variant)' }} axisLine={false} tickLine={false} tickFormatter={v => v>=1000?`${Math.round(v/1000)}k`:v} width={32} />
        <Tooltip
          formatter={(v, name) => [formatINR(v), name === 'income' ? 'Income' : 'Expense']}
          contentStyle={{ backgroundColor:'var(--surface)', border:'1px solid var(--outline-variant)', borderRadius:8, fontSize:12 }}
        />
        <Bar dataKey="income" fill="rgba(42,181,160,0.7)" radius={[3,3,0,0]} name="income" />
        <Bar dataKey="expense" fill="rgba(186,26,26,0.65)" radius={[3,3,0,0]} name="expense" />
      </BarChart>
    </ResponsiveContainer>
  )
}

function DebtRatioChart({ data, loading }) {
  if (loading) return <div className="h-44 shimmer rounded-xl" />
  if (!data?.length) return (
    <div className="h-44 flex items-center justify-center text-sm" style={{ color:'var(--on-surface-variant)' }}>
      No active loans found
    </div>
  )
  const W = 400, H = 140
  const maxDti = Math.max(...data.map(d => d.dti||0), 80)
  const pts = data.map((d, i) => ({
    x: data.length === 1 ? W/2 : (i / (data.length-1)) * W,
    y: 8 + (H - 8) - ((d.dti||0)/maxDti)*(H - 16),
    dti: d.dti||0,
    month: d.month,
  }))
  const pathD = pts.map((p,i) => `${i===0?'M':'L'}${p.x} ${p.y}`).join(' ')
  const areaD = `${pathD} L${pts[pts.length-1].x} ${H+8} L${pts[0].x} ${H+8} Z`
  const y50 = 8 + (H - 8) - (50/maxDti)*(H - 16)

  return (
    <svg width="100%" viewBox={`0 0 ${W} ${H+28}`} style={{ overflow:'visible' }}>
      <defs>
        <linearGradient id="dtiGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#2ab5a0" stopOpacity="0.25" />
          <stop offset="100%" stopColor="#2ab5a0" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={areaD} fill="url(#dtiGrad)" />
      <path d={pathD} fill="none" stroke="#2ab5a0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
      {maxDti >= 50 && <line x1="0" y1={y50} x2={W} y2={y50} stroke="rgba(212,147,42,0.5)" strokeWidth="1.5" strokeDasharray="6 3" />}
      {pts.map((p,i) => (
        <circle key={i} cx={p.x} cy={p.y} r="4" fill={dtiColor(p.dti)} stroke="white" strokeWidth="2" />
      ))}
      {pts.map((p,i) => (
        <text key={i} x={p.x} y={H+24} textAnchor="middle" fontSize="10" fill="var(--on-surface-variant)">{p.month}</text>
      ))}
    </svg>
  )
}

const SHORT_MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

export default function Dashboard() {
  const { user, dashboard, dashboardLoading, fetchDashboard, selectedFY, debtLastUpdated } = useStore()
  const [quickType, setQuickType] = useState('expense')
  const [quickAmount, setQuickAmount] = useState('')
  const [quickDesc, setQuickDesc] = useState('')
  const [quickCategory, setQuickCategory] = useState('food')
  const [quickDate, setQuickDate] = useState(() => new Date().toISOString().split('T')[0])
  const [quickSourceType, setQuickSourceType] = useState('salary')
  const [quickTaxCategory, setQuickTaxCategory] = useState('salary')
  const [submitting, setSubmitting] = useState(false)
  const [upcomingPayments, setUpcomingPayments] = useState([])
  const [upcomingDetail, setUpcomingDetail] = useState(null)
  const [payingUpcoming, setPayingUpcoming] = useState(false)

  useEffect(() => { fetchDashboard().catch(() => {}) }, [selectedFY])

  useEffect(() => {
    const fetchUpcoming = async () => {
      try {
        const today = new Date()
        const upcoming = []
        const [loansR, cardsR, subsR] = await Promise.all([
          api.get('/loans').catch(() => ({ data: [] })),
          api.get('/loans/cards').catch(() => ({ data: [] })),
          api.get('/expenses/subscriptions').catch(() => ({ data: [] })),
        ])
        const isPaidThisMonth = (lastPaidDate) => {
          if (!lastPaidDate) return false
          const d = new Date(lastPaidDate)
          return d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth()
        }
        for (const loan of (Array.isArray(loansR.data) ? loansR.data : [])) {
          if (!loan.is_active) continue
          if (isPaidThisMonth(loan.last_paid_date)) continue
          const start = new Date(loan.start_date)
          const dueDay = start.getDate()
          const dueThisMonth = new Date(today.getFullYear(), today.getMonth(), dueDay)
          const dueNext = dueThisMonth < today ? new Date(today.getFullYear(), today.getMonth() + 1, dueDay) : dueThisMonth
          upcoming.push({ name: loan.loan_name || 'Loan EMI', amount: parseFloat(loan.emi_amount), due_date: dueNext.toISOString().split('T')[0], type: 'emi', loan_id: loan.id })
        }
        for (const card of (Array.isArray(cardsR.data) ? cardsR.data : [])) {
          if (!card.due_date || parseFloat(card.minimum_due) <= 0) continue
          if (isPaidThisMonth(card.last_paid_date)) continue
          const dueThisMonth = new Date(today.getFullYear(), today.getMonth(), card.due_date)
          const dueNext = dueThisMonth < today ? new Date(today.getFullYear(), today.getMonth() + 1, card.due_date) : dueThisMonth
          upcoming.push({ name: `${card.card_name} Bill`, amount: parseFloat(card.minimum_due), due_date: dueNext.toISOString().split('T')[0], type: 'card', card_id: card.id })
        }
        for (const sub of (Array.isArray(subsR.data) ? subsR.data : [])) {
          if (sub.is_active === false) continue
          const subDate = new Date(sub.spent_on || today)
          const dueThisMonth = new Date(today.getFullYear(), today.getMonth(), subDate.getDate())
          const dueNext = dueThisMonth < today ? new Date(today.getFullYear(), today.getMonth() + 1, subDate.getDate()) : dueThisMonth
          upcoming.push({ name: sub.description || sub.category, amount: parseFloat(sub.amount), due_date: dueNext.toISOString().split('T')[0], type: 'subscription' })
        }
        upcoming.sort((a, b) => new Date(a.due_date) - new Date(b.due_date))
        setUpcomingPayments(upcoming.slice(0, 8))
      } catch { /* silent */ }
    }
    fetchUpcoming()
  }, [selectedFY, debtLastUpdated])

  const greeting = () => {
    const h = new Date(new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })).getHours()
    if (h < 12) return 'Good morning'
    if (h < 17) return 'Good afternoon'
    return 'Good evening'
  }

  const today = new Date().toLocaleDateString('en-IN', { weekday:'long', year:'numeric', month:'long', day:'numeric' })

  const handleQuickAdd = async (e) => {
    e.preventDefault()
    if (!quickAmount) return toast.error('Enter amount')
    setSubmitting(true)
    try {
      if (quickType === 'expense') {
        await api.post('/expenses', {
          amount: parseFloat(quickAmount), category: quickCategory,
          description: quickDesc, spent_on: quickDate,
        })
        toast.success('Expense added!')
      } else {
        await api.post('/income', {
          amount: parseFloat(quickAmount), source_type: quickSourceType,
          description: quickDesc, received_on: quickDate, tax_category: quickTaxCategory,
        })
        toast.success('Income added!')
      }
      setQuickAmount(''); setQuickDesc('')
      fetchDashboard()
    } catch { toast.error('Failed to add') }
    finally { setSubmitting(false) }
  }

  const handlePayUpcoming = async () => {
    if (!upcomingDetail) return
    setPayingUpcoming(true)
    const today = new Date().toISOString().split('T')[0]
    try {
      const p = upcomingDetail
      if (p.type === 'emi' && p.loan_id) {
        await api.post(`/loans/${p.loan_id}/pay`, { amount: p.amount, paid_on: today, notes: p.name })
      } else if (p.type === 'card' && p.card_id) {
        await api.post(`/loans/cards/${p.card_id}/pay`, { amount: p.amount, paid_on: today, notes: p.name })
      } else {
        await api.post('/expenses', { amount: p.amount, category: 'bills', description: p.name, spent_on: today })
      }
      setUpcomingPayments(prev => prev.filter((_, i) => i !== p._idx))
      setUpcomingDetail(null)
      fetchDashboard()
      toast.success('Payment recorded!')
    } catch { toast.error('Failed to record payment') }
    finally { setPayingUpcoming(false) }
  }

  const d = dashboard
  const loading = dashboardLoading
  const debtColor = d?.debt_verdict?.color || 'teal'
  const savingsRate = Math.min(d?.savings_rate || 0, 100)

  const inputStyle = { backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }

  return (
    <div className="p-4 md:p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>

      {/* Row 1: Greeting */}
      <div>
        <h2 className="text-xl md:text-2xl font-bold" style={{ color:'var(--on-surface)' }}>
          {greeting()}, {user?.name?.split(' ')[0] || 'there'} 👋
        </h2>
        <p className="text-sm mt-1" style={{ color:'var(--on-surface-variant)' }}>{today}</p>
      </div>

      {/* Row 2: 4 Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard title="Net Worth" value={d?.net_worth} subtitle={`Assets ${formatINR(d?.total_assets)}`} color="teal" icon={TrendingUp} loading={loading} />
        <MetricCard title="Free Cash" value={d?.free_cash} subtitle="After EMIs & expenses" color={d?.free_cash<0?'red':'info'} icon={DollarSign} loading={loading} />
        <MetricCard title="Debt Score" value={`${d?.debt_score??0}/100`} subtitle={d?.debt_verdict?.message||'No debt'}
          color={debtColor==='teal'?'teal':debtColor==='amber'?'amber':'red'} icon={CreditCard} isAmount={false} loading={loading} />
        <MetricCard title="Tax Due (Est.)" value={d?.tax_due} subtitle={`FY ${selectedFY}`} color="red" icon={Activity} loading={loading} />
      </div>

      {/* Row 3: Charts + Quick Add */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <Card className="p-5">
          <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Income vs Expenses</h3>
          <IncomeExpenseChart data={d?.income_vs_expense_data} loading={loading} />
        </Card>

        <Card className="p-5">
          <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Debt Ratio Forecast</h3>
          <DebtRatioChart
            data={d?.debt_ratio_forecast?.map(r => ({ month:r.month, dti:r.dti }))}
            loading={loading}
          />
        </Card>

        <Card className="p-5">
          <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Quick Add</h3>
          <form onSubmit={handleQuickAdd} className="space-y-3">
            <div className="flex gap-1 p-1 rounded-lg" style={{ backgroundColor:'var(--surface-container-low)' }}>
              {QUICK_ADD_TYPES.map(t => (
                <button key={t} type="button" onClick={() => setQuickType(t)}
                  className="flex-1 py-2 rounded-lg text-xs font-semibold capitalize transition-all"
                  style={{ backgroundColor:quickType===t?'#2ab5a0':'transparent', color:quickType===t?'#fff':'var(--on-surface-variant)' }}>
                  {t}
                </button>
              ))}
            </div>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm" style={{ color:'var(--on-surface-variant)' }}>₹</span>
              <input type="number" value={quickAmount} onChange={e => setQuickAmount(e.target.value)} placeholder="Amount"
                className="w-full pl-8 pr-4 py-2.5 rounded-lg text-sm focus:outline-none border" style={inputStyle} />
            </div>
            {quickType === 'expense' ? (
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>Category</p>
                <select value={quickCategory} onChange={e => setQuickCategory(e.target.value)}
                  className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border" style={inputStyle}>
                  {['food','transport','bills','health','entertainment','shopping','subscriptions','education','other'].map(c => (
                    <option key={c} value={c}>{c.charAt(0).toUpperCase()+c.slice(1)}</option>
                  ))}
                </select>
              </div>
            ) : (
              <>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>Source</p>
                  <select value={quickSourceType} onChange={e => setQuickSourceType(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border" style={inputStyle}>
                    {SOURCE_TYPES.map(s => <option key={s} value={s}>{s.replace(/_/g,' ').replace(/^\w/,c=>c.toUpperCase())}</option>)}
                  </select>
                </div>
                <div>
                  <p className="text-[10px] font-semibold uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>Tax Category</p>
                  <select value={quickTaxCategory} onChange={e => setQuickTaxCategory(e.target.value)}
                    className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border" style={inputStyle}>
                    {TAX_CATEGORIES.map(t => <option key={t} value={t}>{t.replace(/_/g,' ').replace(/^\w/,c=>c.toUpperCase())}</option>)}
                  </select>
                </div>
              </>
            )}
            <input type="text" value={quickDesc} onChange={e => setQuickDesc(e.target.value)} placeholder="Description (optional)"
              className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border" style={inputStyle} />
            <DatePickerInput value={quickDate} onChange={setQuickDate} />
            <button type="submit" disabled={submitting}
              className="w-full py-2.5 rounded-lg text-sm font-semibold flex items-center justify-center gap-2 transition-all"
              style={{ backgroundColor:'#2ab5a0', color:'#fff', opacity:submitting?0.7:1 }}>
              <Plus size={15} />
              {submitting ? 'Adding…' : `Add ${quickType.charAt(0).toUpperCase()+quickType.slice(1)}`}
            </button>
          </form>
        </Card>
      </div>

      {/* Alert Card */}
      {d?.top_alert && <AlertCard level={d.top_alert.level} message={d.top_alert.message} />}

      {/* Row 4: Activity | This Month Summary | Upcoming Payments */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Recent Activity */}
        <Card className="p-5">
          <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Recent Activity</h3>
          {loading ? (
            <div className="space-y-4">
              {[...Array(5)].map((_,i) => (
                <div key={i} className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 shimmer rounded-full" />
                    <div className="space-y-1.5"><div className="h-3 w-32 shimmer rounded" /><div className="h-2.5 w-20 shimmer rounded" /></div>
                  </div>
                  <div className="h-4 w-20 shimmer rounded" />
                </div>
              ))}
            </div>
          ) : d?.recent_activity?.length ? (
            <div className="space-y-1">
              {d.recent_activity.map((item, i) => {
                const { Icon, color, bg } = getActivityMeta(item)
                return (
                  <div key={i} className="flex items-center justify-between py-2.5 px-2 rounded-xl transition-colors"
                    onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor:bg }}>
                        <Icon size={15} strokeWidth={2} style={{ color }} />
                      </div>
                      <div>
                        <p className="text-sm font-medium capitalize" style={{ color:'var(--on-surface)' }}>
                          {item.description || item.category || item.type}
                        </p>
                        <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{formatRelativeDate(item.date)}</p>
                      </div>
                    </div>
                    <span className="text-sm font-semibold font-mono" style={{ color:item.positive?'var(--positive)':'var(--error)' }}>
                      {formatINR(Math.abs(item.amount))}
                    </span>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="py-10 text-center">
              <p className="text-sm" style={{ color:'var(--on-surface-variant)' }}>No recent activity</p>
              <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>Start by adding income or expenses</p>
            </div>
          )}
        </Card>

        {/* This Month Summary */}
        <Card className="p-5">
          <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>This Month</h3>
          <div className="grid grid-cols-3 gap-3 mb-5">
            {[
              { label:'Income',   value:d?.monthly_income,   color:'var(--positive)' },
              { label:'Expenses', value:d?.monthly_expenses, color:'var(--error)'    },
              { label:'EMIs',     value:d?.total_emi,        color:'var(--warning)'  },
            ].map(({ label, value, color }) => (
              <div key={label} className="p-3 rounded-xl text-center" style={{ backgroundColor:'var(--surface-container-low)' }}>
                <p className="text-[10px] font-semibold uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
                <p className="text-sm font-bold font-mono" style={{ color }}>{loading ? '…' : formatINR(value)}</p>
              </div>
            ))}
          </div>
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold" style={{ color:'var(--on-surface-variant)' }}>Savings Rate</span>
              <span className="text-sm font-bold font-mono" style={{ color:'#8b7fd4' }}>{(d?.savings_rate||0).toFixed(1)}%</span>
            </div>
            <div className="h-2.5 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container)' }}>
              <div className="h-full rounded-full transition-all" style={{ width:`${savingsRate}%`, backgroundColor:'#8b7fd4' }} />
            </div>
            <p className="text-xs" style={{ color:'var(--on-surface-variant)' }}>
              {savingsRate >= 20 ? 'Great savings habit!' : savingsRate >= 10 ? 'Room to improve' : 'Try to save more'}
            </p>
          </div>
        </Card>

        {/* Upcoming Payments */}
        <Card className="p-5">
          <div className="flex items-center gap-2 mb-4">
            <CalendarClock size={16} style={{ color:'var(--primary-container)' }} />
            <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Upcoming Payments</h3>
          </div>
          {loading ? (
            <div className="space-y-3">
              {[...Array(4)].map((_,i) => <div key={i} className="h-12 shimmer rounded-xl" />)}
            </div>
          ) : upcomingPayments.length ? (
            <div className="space-y-3">
              {upcomingPayments.map((p, i) => {
                const dueDate = new Date(p.due_date)
                const daysLeft = Math.ceil((dueDate - new Date()) / 86400000)
                const urgColor = daysLeft <= 3 ? '#ba1a1a' : daysLeft <= 7 ? '#d4932a' : '#2ab5a0'
                return (
                  <div key={i} className="flex items-center gap-3 py-2 px-1 rounded-xl cursor-pointer transition-colors"
                    onClick={() => setUpcomingDetail({ ...p, _idx: i })}
                    onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                    <div className="w-11 h-11 rounded-xl flex flex-col items-center justify-center flex-shrink-0"
                      style={{ backgroundColor:`${urgColor}15` }}>
                      <span className="text-sm font-bold leading-none" style={{ color:urgColor }}>{dueDate.getDate()}</span>
                      <span className="text-[9px] uppercase font-semibold leading-none mt-0.5" style={{ color:urgColor }}>{SHORT_MONTHS[dueDate.getMonth()]}</span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate" style={{ color:'var(--on-surface)' }}>{p.name}</p>
                      <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{daysLeft === 0 ? 'Due today' : daysLeft > 0 ? `${daysLeft} days left` : 'Overdue'}</p>
                    </div>
                    <span className="text-sm font-semibold font-mono flex-shrink-0" style={{ color:'var(--error)' }}>{formatINR(p.amount)}</span>
                  </div>
                )
              })}
            </div>
          ) : (
            <div className="py-8 text-center">
              <p className="text-sm" style={{ color:'var(--on-surface-variant)' }}>No upcoming payments</p>
              <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>Add loans & insurance to track</p>
            </div>
          )}
        </Card>
      </div>

      {/* Upcoming Payment Detail Modal */}
      {upcomingDetail && (() => {
        const p = upcomingDetail
        const dueDate = new Date(p.due_date)
        const daysLeft = Math.ceil((dueDate - new Date()) / 86400000)
        const urgColor = daysLeft <= 3 ? '#ba1a1a' : daysLeft <= 7 ? '#d4932a' : '#2ab5a0'
        const typeLabel = p.type === 'emi' ? 'Loan EMI' : p.type === 'card' ? 'Credit Card Bill' : 'Subscription'
        return (
          <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center" style={{ backgroundColor:'rgba(0,0,0,0.45)' }}
            onClick={e => { if (e.target === e.currentTarget) setUpcomingDetail(null) }}>
            <div className="w-full sm:max-w-sm rounded-t-2xl sm:rounded-2xl overflow-hidden"
              style={{ backgroundColor:'var(--surface)', boxShadow:'0 20px 60px rgba(0,0,0,0.2)' }}>
              <div className="px-5 py-4 flex items-center justify-between" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                <div className="flex items-center gap-2">
                  <CalendarClock size={15} style={{ color:urgColor }} />
                  <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Payment Due</span>
                </div>
                <button onClick={() => setUpcomingDetail(null)} className="p-1 rounded" style={{ color:'var(--on-surface-variant)' }}>✕</button>
              </div>
              <div className="px-5 py-4 space-y-3">
                {[
                  { label:'Name', value:p.name },
                  { label:'Type', value:typeLabel },
                  { label:'Amount', value:formatINR(p.amount), style:{ fontFamily:'monospace', color:'var(--error)', fontWeight:700 } },
                  { label:'Due Date', value:`${dueDate.toLocaleDateString('en-IN', { day:'numeric', month:'long', year:'numeric' })}` },
                  { label:'Status', value:daysLeft < 0 ? '⚠ Overdue' : daysLeft === 0 ? '📅 Due Today' : `${daysLeft} days remaining`, style:{ color:urgColor, fontWeight:600 } },
                ].map(({ label, value, style }) => (
                  <div key={label} className="flex items-center justify-between py-2" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                    <span className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>{label}</span>
                    <span className="text-sm" style={{ color:'var(--on-surface)', ...style }}>{value}</span>
                  </div>
                ))}
              </div>
              <div className="px-5 pb-5 pt-2 flex gap-3">
                <button onClick={() => setUpcomingDetail(null)}
                  className="flex-1 py-2.5 rounded-lg text-sm font-medium border"
                  style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
                  Close
                </button>
                <button onClick={handlePayUpcoming} disabled={payingUpcoming}
                  className="flex-1 py-2.5 rounded-lg text-sm font-semibold flex items-center justify-center gap-2 transition-all"
                  style={{ backgroundColor:'#2ab5a0', color:'#fff', opacity:payingUpcoming?0.7:1 }}>
                  {payingUpcoming ? 'Recording…' : '✓ Mark as Paid'}
                </button>
              </div>
            </div>
          </div>
        )
      })()}
    </div>
  )
}
