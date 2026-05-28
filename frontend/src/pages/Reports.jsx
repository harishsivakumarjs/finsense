import { useEffect, useState } from 'react'
import { Download, FileText, BarChart3, TrendingUp, Calendar, ChevronLeft, ChevronRight, X } from 'lucide-react'
import toast from 'react-hot-toast'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import api from '../api/axios'
import { formatINR, formatINRCompact, formatDate } from '../utils/format'

const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']

const EXPENSE_COLORS = {
  food:'#d4932a', transport:'#4a8ed4', health:'#E05A5A',
  entertainment:'#8b7fd4', shopping:'#2ab5a0', subscriptions:'#8b7fd4',
  education:'#4a8ed4', bills:'#d4932a', other:'#6c7a76',
}
const SOURCE_COLORS = {
  salary:'#2ab5a0', pocket_money:'#8b7fd4', freelance:'#d4932a',
  youtube:'#E05A5A', trading:'#4a8ed4', investment:'#8b7fd4', other:'#6c7a76',
}

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

export default function Reports() {
  const today = new Date()
  const [month, setMonth] = useState(today.getMonth() + 1)
  const [year, setYear] = useState(today.getFullYear())
  const [pickerYear, setPickerYear] = useState(today.getFullYear())
  const [showPicker, setShowPicker] = useState(false)
  const [monthlyData, setMonthlyData] = useState(null)
  const [taxData, setTaxData] = useState(null)
  const [nwData, setNwData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [downloading, setDownloading] = useState(null)
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [fyYear] = useState(() => {
    const now = new Date()
    return now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1
  })

  const load = async () => {
    setLoading(true)
    try {
      const [mRes, tRes, nRes] = await Promise.all([
        api.get('/reports/monthly', { params:{ month, year } }),
        api.get('/reports/tax'),
        api.get('/reports/networth'),
      ])
      setMonthlyData(mRes.data)
      setTaxData(tRes.data)
      setNwData(nRes.data)
    } catch { toast.error('Failed to load reports') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [month, year])

  const selectMonth = (m) => { setMonth(m); setYear(pickerYear); setShowPicker(false) }

  const downloadCA = async () => {
    setDownloading('ca')
    try {
      const res = await api.get('/reports/tax/pdf', { params: { year: fyYear }, responseType: 'blob' })
      const blob = new Blob([res.data], { type: 'application/pdf' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `finsense_ca_report_${fyYear}-${String(fyYear + 1).slice(2)}.pdf`
      document.body.appendChild(a); a.click(); document.body.removeChild(a)
      URL.revokeObjectURL(url)
      toast.success('CA Report downloaded')
    } catch { toast.error('Failed to download CA Report') }
    finally { setDownloading(null) }
  }

  const downloadPDF = async (type) => {
    setDownloading(type)
    try {
      const params = type === 'monthly' ? { month, year } : { year:fyYear }
      const res = await api.get(`/reports/${type}/pdf`, { params, responseType:'blob' })
      const blob = new Blob([res.data], { type:'application/pdf' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = type === 'monthly'
        ? `finsense_report_${year}_${String(month).padStart(2,'0')}.pdf`
        : `finsense_tax_${fyYear}-${String(fyYear+1).slice(2)}.pdf`
      a.click()
      URL.revokeObjectURL(url)
      toast.success('PDF downloaded!')
    } catch { toast.error('Failed to download PDF') }
    finally { setDownloading(null) }
  }

  const monthName = new Date(year, month - 1).toLocaleString('default', { month:'long' })
  const m = monthlyData
  const totalIncome = m?.income_streams?.reduce((s, i) => s + i.total, 0) ?? 0
  const totalExpenses = m?.expense_summary?.reduce((s, e) => s + e.total, 0) ?? 0
  const netSavings = totalIncome - totalExpenses
  const savingsRate = totalIncome > 0 ? ((netSavings / totalIncome) * 100).toFixed(1) : '0'

  const t = taxData?.tax_data
  const taxDue = t?.final_tax ?? 0
  const nwSnapshots = nwData?.snapshots ?? []
  const latestSnap = nwSnapshots[nwSnapshots.length - 1]
  const prevSnap = nwSnapshots[nwSnapshots.length - 2]
  const nwTrend = prevSnap ? latestSnap?.net_worth - prevSnap?.net_worth : null

  const nwChartData = nwSnapshots.map(s => ({
    date: s.date?.split('T')[0] || '',
    nw: parseFloat(s.net_worth || 0),
  }))

  return (
    <div className="p-4 md:p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Reports</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Financial snapshots and export tools</p>
        </div>
        {/* Filters: date range + month picker */}
        <div className="flex items-center gap-2">
          <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
            title="From date"
            className="px-2 py-2 rounded-lg text-xs focus:outline-none border"
            style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
          <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>–</span>
          <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
            title="To date"
            className="px-2 py-2 rounded-lg text-xs focus:outline-none border"
            style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
          {(dateFrom || dateTo) && (
            <button onClick={() => { setDateFrom(''); setDateTo('') }}
              className="p-1.5 rounded-lg transition-colors"
              style={{ color:'var(--on-surface-variant)' }}>
              <X size={13} />
            </button>
          )}
        {/* Month Picker */}
        <div className="relative">
          <button onClick={() => { setPickerYear(year); setShowPicker(!showPicker) }}
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border"
            style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)', backgroundColor:'var(--surface)' }}>
            <Calendar size={14} style={{ color:'var(--primary-container)' }} />
            {monthName} {year}
          </button>
          {showPicker && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setShowPicker(false)} />
              <div className="absolute top-full mt-2 right-0 z-50 rounded-xl p-4 w-64"
                style={{ backgroundColor:'var(--surface)', boxShadow:'0 8px 32px rgba(0,0,0,0.12)', border:'1px solid var(--outline-variant)' }}>
                <div className="flex items-center justify-between mb-3">
                  <button onClick={() => setPickerYear(y => y-1)} className="w-7 h-7 flex items-center justify-center rounded-lg"
                    style={{ color:'var(--on-surface-variant)' }} onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'} onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                    <ChevronLeft size={14} />
                  </button>
                  <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{pickerYear}</span>
                  <button onClick={() => setPickerYear(y => y+1)} className="w-7 h-7 flex items-center justify-center rounded-lg"
                    style={{ color:'var(--on-surface-variant)' }} onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'} onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                    <ChevronRight size={14} />
                  </button>
                </div>
                <div className="grid grid-cols-4 gap-1.5">
                  {MONTHS.map((mo, i) => (
                    <button key={mo} onClick={() => selectMonth(i+1)}
                      className="py-1.5 rounded-lg text-xs font-medium transition-all"
                      style={{ backgroundColor:month===i+1&&year===pickerYear?'#2ab5a0':'var(--surface-container-low)', color:month===i+1&&year===pickerYear?'#fff':'var(--on-surface-variant)' }}>
                      {mo}
                    </button>
                  ))}
                </div>
              </div>
            </>
          )}
        </div>
        </div>
      </div>

      {/* 3 Report Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Monthly Report */}
        <Card className="p-5 flex flex-col gap-4" style={{ borderTop:'3px solid #2ab5a0' }}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FileText size={16} style={{ color:'#2ab5a0' }} />
              <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Monthly Report</h3>
            </div>
            <span className="text-xs font-medium px-2 py-0.5 rounded-full" style={{ backgroundColor:'rgba(42,181,160,0.1)', color:'#2ab5a0' }}>{monthName} {year}</span>
          </div>

          {loading ? (
            <div className="space-y-2">{[...Array(4)].map((_,i) => <div key={i} className="h-12 rounded-lg shimmer" />)}</div>
          ) : (
            <div className="grid grid-cols-2 gap-2">
              {[
                { label:'Income', val:formatINRCompact(totalIncome), color:'var(--positive)' },
                { label:'Expenses', val:formatINRCompact(totalExpenses), color:'var(--error)' },
                { label:'Net Savings', val:formatINRCompact(Math.abs(netSavings)), color:netSavings>=0?'#006b5d':'#ba1a1a' },
                { label:'Savings Rate', val:`${savingsRate}%`, color:'#4a8ed4' },
              ].map(({ label, val, color }) => (
                <div key={label} className="p-3 rounded-lg" style={{ backgroundColor:'var(--surface-container-low)' }}>
                  <p className="text-xs mb-1" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
                  <p className="text-base font-bold font-mono" style={{ color }}>{val}</p>
                </div>
              ))}
            </div>
          )}

          <div className="flex gap-2 mt-auto">
            <button onClick={() => downloadPDF('monthly')} disabled={downloading==='monthly'}
              className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-semibold transition-all"
              style={{ backgroundColor:'rgba(42,181,160,0.1)', color:'#2ab5a0', border:'1px solid rgba(42,181,160,0.2)', opacity:downloading==='monthly'?0.7:1 }}>
              <Download size={12} /> PDF
            </button>
            <button onClick={() => toast('CSV coming soon')}
              className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-semibold"
              style={{ backgroundColor:'var(--surface-container-low)', color:'var(--on-surface-variant)', border:'1px solid var(--outline-variant)' }}>
              <Download size={12} /> CSV
            </button>
          </div>
        </Card>

        {/* Tax Summary */}
        <Card className="p-5 flex flex-col gap-4" style={{ borderTop:'3px solid #8b7fd4' }}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <FileText size={16} style={{ color:'#8b7fd4' }} />
              <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Tax Summary</h3>
            </div>
            <span className="text-xs font-medium px-2 py-0.5 rounded-full" style={{ backgroundColor:'rgba(139,127,212,0.1)', color:'#8b7fd4' }}>FY {fyYear}-{String(fyYear+1).slice(2)}</span>
          </div>

          {loading ? (
            <div className="space-y-2">{[...Array(3)].map((_,i) => <div key={i} className="h-10 rounded-lg shimmer" />)}</div>
          ) : (
            <div className="space-y-2 flex-1">
              {[
                { label:'Gross Income', val:formatINRCompact(t?.gross_income||0), color:'var(--on-surface)' },
                { label:'Total Deductions', val:formatINRCompact(t?.total_deductions||0), color:'var(--positive)' },
                { label:'Taxable Income', val:formatINRCompact(t?.taxable_income||0), color:'var(--on-surface)' },
                { label:'Tax Liability', val:formatINRCompact(taxDue), color:taxDue>0?'#ba1a1a':'#006b5d' },
              ].map(({ label, val, color }) => (
                <div key={label} className="flex items-center justify-between py-1.5" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                  <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>{label}</span>
                  <span className="text-sm font-bold font-mono" style={{ color }}>{val}</span>
                </div>
              ))}
              <div className="flex items-center justify-between py-1 mt-1">
                <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>Regime</span>
                <span className="text-xs font-semibold px-2 py-0.5 rounded-full uppercase" style={{ backgroundColor:'rgba(139,127,212,0.1)', color:'#8b7fd4' }}>{taxData?.regime||'new'}</span>
              </div>
            </div>
          )}

          <div className="flex gap-2 mt-auto">
            <button onClick={() => downloadPDF('tax')} disabled={downloading==='tax'}
              className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-semibold transition-all"
              style={{ backgroundColor:'rgba(139,127,212,0.1)', color:'#8b7fd4', border:'1px solid rgba(139,127,212,0.2)', opacity:downloading==='tax'?0.7:1 }}>
              <Download size={12} /> ITR PDF
            </button>
            <button onClick={downloadCA} disabled={downloading==='ca'}
              className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-semibold transition-all"
              style={{ backgroundColor:'var(--surface-container-low)', color:'var(--on-surface-variant)', border:'1px solid var(--outline-variant)', opacity:downloading==='ca'?0.7:1 }}>
              <Download size={12} /> {downloading==='ca' ? 'Downloading…' : 'CA Report'}
            </button>
          </div>
        </Card>

        {/* Net Worth Report */}
        <Card className="p-5 flex flex-col gap-4" style={{ borderTop:'3px solid #4a8ed4' }}>
          <div className="flex items-center gap-2">
            <BarChart3 size={16} style={{ color:'#4a8ed4' }} />
            <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Net Worth Report</h3>
          </div>

          {loading ? (
            <div className="space-y-2">{[...Array(3)].map((_,i) => <div key={i} className="h-12 rounded-lg shimmer" />)}</div>
          ) : (
            <div className="flex-1 space-y-3">
              <div className="p-4 rounded-lg text-center" style={{ backgroundColor:'rgba(74,142,212,0.06)', border:'1px solid rgba(74,142,212,0.15)' }}>
                <p className="text-xs uppercase tracking-wider mb-1" style={{ color:'var(--on-surface-variant)' }}>Current Net Worth</p>
                <p className="text-2xl font-bold font-mono" style={{ color:'#4a8ed4' }}>{formatINRCompact(latestSnap?.net_worth||0)}</p>
                {nwTrend !== null && (
                  <p className="text-xs font-semibold mt-1" style={{ color:nwTrend>=0?'#006b5d':'#ba1a1a' }}>
                    {nwTrend>=0?'▲':'▼'} {formatINRCompact(Math.abs(nwTrend))} vs last snapshot
                  </p>
                )}
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div className="p-3 rounded-lg" style={{ backgroundColor:'var(--surface-container-low)' }}>
                  <p className="text-xs mb-1" style={{ color:'var(--on-surface-variant)' }}>Total Assets</p>
                  <p className="text-sm font-bold font-mono" style={{ color:'var(--positive)' }}>{formatINRCompact(latestSnap?.total_assets||0)}</p>
                </div>
                <div className="p-3 rounded-lg" style={{ backgroundColor:'var(--surface-container-low)' }}>
                  <p className="text-xs mb-1" style={{ color:'var(--on-surface-variant)' }}>Liabilities</p>
                  <p className="text-sm font-bold font-mono" style={{ color:'var(--error)' }}>{formatINRCompact(latestSnap?.total_liabilities||0)}</p>
                </div>
              </div>
              <p className="text-xs" style={{ color:'var(--on-surface-variant)' }}>{nwSnapshots.length} snapshots taken</p>
            </div>
          )}

          <button onClick={() => {
            const blob = new Blob([JSON.stringify(nwData, null, 2)], { type:'application/json' })
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a'); a.href = url; a.download = `networth_${year}.json`; a.click()
          }} className="flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-semibold"
            style={{ backgroundColor:'rgba(74,142,212,0.1)', color:'#4a8ed4', border:'1px solid rgba(74,142,212,0.2)' }}>
            <Download size={12} /> Export JSON
          </button>
        </Card>
      </div>

      {/* Monthly Detail Grid */}
      {!loading && m && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {/* Income Breakdown */}
          <Card className="overflow-hidden">
            <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
              <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Income by Source — {monthName} {year}</h3>
            </div>
            <div className="p-5">
              {(m.income_streams??[]).length === 0 ? (
                <p className="text-sm text-center py-6" style={{ color:'var(--on-surface-variant)' }}>No income recorded</p>
              ) : (
                <div className="space-y-3">
                  {(m.income_streams).sort((a,b) => b.total-a.total).map(s => {
                    const pct = totalIncome > 0 ? (s.total/totalIncome)*100 : 0
                    const color = SOURCE_COLORS[s.source_type] || '#6c7a76'
                    return (
                      <div key={s.source_type}>
                        <div className="flex items-center justify-between text-sm mb-1.5">
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 rounded-full" style={{ backgroundColor:color }} />
                            <span className="capitalize" style={{ color:'var(--on-surface)' }}>{s.source_type.replace(/_/g,' ')}</span>
                          </div>
                          <span className="font-mono font-semibold" style={{ color }}>{formatINRCompact(s.total)}</span>
                        </div>
                        <div className="h-1.5 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container)' }}>
                          <div className="h-full rounded-full" style={{ width:`${pct}%`, backgroundColor:color }} />
                        </div>
                      </div>
                    )
                  })}
                  <div className="flex items-center justify-between pt-3" style={{ borderTop:'1px solid var(--outline-variant)' }}>
                    <span className="text-sm" style={{ color:'var(--on-surface-variant)' }}>Total</span>
                    <span className="text-sm font-bold font-mono" style={{ color:'var(--positive)' }}>{formatINR(totalIncome)}</span>
                  </div>
                </div>
              )}
            </div>
          </Card>

          {/* Expense Breakdown */}
          <Card className="overflow-hidden">
            <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
              <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Spending by Category — {monthName} {year}</h3>
            </div>
            <div className="p-5">
              {(m.expense_summary??[]).length === 0 ? (
                <p className="text-sm text-center py-6" style={{ color:'var(--on-surface-variant)' }}>No expenses recorded</p>
              ) : (
                <div className="space-y-3">
                  {(m.expense_summary).sort((a,b) => b.total-a.total).map(e => {
                    const pct = totalExpenses > 0 ? (e.total/totalExpenses)*100 : 0
                    const color = EXPENSE_COLORS[e.category] || '#6c7a76'
                    return (
                      <div key={e.category}>
                        <div className="flex items-center justify-between text-sm mb-1.5">
                          <div className="flex items-center gap-2">
                            <div className="w-2 h-2 rounded-full" style={{ backgroundColor:color }} />
                            <span className="capitalize" style={{ color:'var(--on-surface)' }}>{e.category}</span>
                          </div>
                          <span className="font-mono font-semibold" style={{ color }}>{formatINRCompact(e.total)}</span>
                        </div>
                        <div className="h-1.5 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container)' }}>
                          <div className="h-full rounded-full" style={{ width:`${pct}%`, backgroundColor:color }} />
                        </div>
                      </div>
                    )
                  })}
                  <div className="flex items-center justify-between pt-3" style={{ borderTop:'1px solid var(--outline-variant)' }}>
                    <span className="text-sm" style={{ color:'var(--on-surface-variant)' }}>Total</span>
                    <span className="text-sm font-bold font-mono" style={{ color:'var(--error)' }}>{formatINR(totalExpenses)}</span>
                  </div>
                </div>
              )}
            </div>
          </Card>
        </div>
      )}

      {/* Net Worth Trend Chart */}
      {!loading && nwChartData.length >= 2 && (
        <Card className="p-5">
          <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Net Worth Trend</h3>
          <ResponsiveContainer width="100%" height={180}>
            <LineChart data={nwChartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--outline-variant)" vertical={false} />
              <XAxis dataKey="date" tick={{ fontSize:11, fill:'var(--on-surface-variant)' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize:11, fill:'var(--on-surface-variant)' }} axisLine={false} tickLine={false}
                tickFormatter={v => `₹${v>=100000?(v/100000).toFixed(0)+'L':v>=1000?(v/1000).toFixed(0)+'K':v}`} />
              <Tooltip formatter={v => formatINR(v)} contentStyle={{ backgroundColor:'var(--surface)', border:'1px solid var(--outline-variant)', borderRadius:8, fontSize:12 }} />
              <Line type="monotone" dataKey="nw" stroke="#4a8ed4" strokeWidth={2.5} dot={{ fill:'#4a8ed4', r:3 }} />
            </LineChart>
          </ResponsiveContainer>
        </Card>
      )}

      {/* Report History Table */}
      <Card className="overflow-hidden">
        <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
          <h3 className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Report History</h3>
        </div>
        <table className="w-full">
          <thead>
            <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
              {['Date','Type','Period','Format','Download'].map(h => (
                <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${h==='Download'?'text-right':'text-left'}`}
                  style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            <tr style={{ borderBottom:'1px solid var(--outline-variant)' }}
              onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
              onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{new Date().toLocaleDateString('en-IN')}</td>
              <td className="px-5 py-3.5">
                <span className="text-xs font-semibold px-2.5 py-1 rounded-full" style={{ backgroundColor:'rgba(42,181,160,0.1)', color:'#2ab5a0' }}>Monthly</span>
              </td>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface)' }}>{monthName} {year}</td>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>PDF</td>
              <td className="px-5 py-3.5 text-right">
                <button onClick={() => downloadPDF('monthly')} className="text-xs font-semibold" style={{ color:'#2ab5a0' }}>Download</button>
              </td>
            </tr>
            <tr style={{ borderBottom:'1px solid var(--outline-variant)' }}
              onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
              onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{new Date().toLocaleDateString('en-IN')}</td>
              <td className="px-5 py-3.5">
                <span className="text-xs font-semibold px-2.5 py-1 rounded-full" style={{ backgroundColor:'rgba(139,127,212,0.1)', color:'#8b7fd4' }}>Tax</span>
              </td>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface)' }}>FY {fyYear}-{String(fyYear+1).slice(2)}</td>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>PDF</td>
              <td className="px-5 py-3.5 text-right">
                <button onClick={() => downloadPDF('tax')} className="text-xs font-semibold" style={{ color:'#8b7fd4' }}>Download</button>
              </td>
            </tr>
            <tr onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
              onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{new Date().toLocaleDateString('en-IN')}</td>
              <td className="px-5 py-3.5">
                <span className="text-xs font-semibold px-2.5 py-1 rounded-full" style={{ backgroundColor:'rgba(74,142,212,0.1)', color:'#4a8ed4' }}>Net Worth</span>
              </td>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface)' }}>Current</td>
              <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>JSON</td>
              <td className="px-5 py-3.5 text-right">
                <button onClick={() => {
                  const blob = new Blob([JSON.stringify(nwData,null,2)],{type:'application/json'})
                  const url = URL.createObjectURL(blob)
                  const a = document.createElement('a'); a.href=url; a.download=`networth_${year}.json`; a.click()
                }} className="text-xs font-semibold" style={{ color:'#4a8ed4' }}>Download</button>
              </td>
            </tr>
          </tbody>
        </table>
      </Card>
    </div>
  )
}
