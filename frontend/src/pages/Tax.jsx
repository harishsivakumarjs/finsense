import { useEffect, useState } from 'react'
import { Download, Plus, Check, AlertCircle, ChevronDown } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import Modal from '../components/Modal'
import useStore from '../store/useStore'
import { formatINR, formatDate, getFinancialYear } from '../utils/format'

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

const DEDUCTION_LIMITS = { '80C':150000, '80D':25000, '80CCD':50000, '24B':200000 }
const DEDUCTION_COLORS = { '80C':'#2ab5a0', '80D':'#4a8ed4', '80CCD':'#8b7fd4', '24B':'#006b5d' }

const currentFY = getFinancialYear()
const FY_OPTIONS = (() => {
  const now = new Date()
  const base = now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1
  const options = []
  for (let y = base - 3; y <= base + 2; y++) {
    options.push(`${y}-${String(y + 1).slice(2)}`)
  }
  return options
})()

export default function Tax() {
  const { selectedFY } = useStore()
  const [taxData, setTaxData] = useState(null)
  const [deductions, setDeductions] = useState([])
  const [advance, setAdvance] = useState([])
  const [carryforward, setCarryforward] = useState([])
  const [suggestions, setSuggestions] = useState([])
  const [loading, setLoading] = useState(true)
  const [regime, setRegime] = useState('new')
  const [taxFY, setTaxFY] = useState(currentFY)
  const [showFYDrop, setShowFYDrop] = useState(false)
  const [showDedModal, setShowDedModal] = useState(false)
  const [dedForm, setDedForm] = useState({ section:'80C', description:'', amount:'', financial_year:currentFY })

  const load = async () => {
    setLoading(true)
    try {
      const [taxR, dedR, advR, cfR, sugR] = await Promise.all([
        api.get('/tax/summary', { params:{ regime, financial_year: taxFY } }),
        api.get('/tax/deductions', { params:{ financial_year: taxFY } }),
        api.get('/tax/advance', { params:{ regime, financial_year: taxFY } }),
        api.get('/tax/carryforward'),
        api.get('/tax/suggestions'),
      ])
      console.log("API response tax:", taxR.data, "deductions:", dedR.data)
      setTaxData(taxR.data)
      setDeductions(Array.isArray(dedR.data) ? dedR.data : [])
      setAdvance(Array.isArray(advR.data) ? advR.data : [])
      setCarryforward(Array.isArray(cfR.data) ? cfR.data : [])
      setSuggestions(Array.isArray(sugR.data) ? sugR.data : [])
    } catch { toast.error('Failed to load tax data') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [regime, selectedFY, taxFY])

  const addDeduction = async () => {
    if (!dedForm.amount) return toast.error('Amount required')
    try { await api.post('/tax/deductions', dedForm); toast.success('Deduction added'); setShowDedModal(false); load() }
    catch { toast.error('Failed to add') }
  }
  const markPaid = async (id) => {
    try { await api.put(`/tax/advance/${id}/pay`, { amount_paid:advance.find(a=>a.id===id)?.amount_due }); toast.success('Marked as paid'); load() }
    catch { toast.error('Failed to update') }
  }
  const downloadPdf = async (type) => {
    try {
      const res = await api.get(type==='itr'?'/reports/tax/pdf':'/reports/monthly/pdf', { responseType:'blob', params:{ regime } })
      const url = URL.createObjectURL(new Blob([res.data], { type:'application/pdf' }))
      const a = document.createElement('a'); a.href = url; a.download = type==='itr'?`tax_${getFinancialYear()}.pdf`:`report.pdf`; a.click()
    } catch { toast.error('Failed to download') }
  }

  const t = taxData
  const totalPaid = advance.filter(a=>a.is_paid).reduce((s,a)=>s+parseFloat(a.amount_paid||0),0)
  const netPayable = t ? Math.max(t.total_tax - totalPaid, 0) : 0
  const usedBySection = {}
  deductions.forEach(d => { usedBySection[d.section] = (usedBySection[d.section]||0) + parseFloat(d.amount) })

  return (
    <div className="p-4 md:p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Tax Planner</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>
            {selectedFY === 'all' ? 'All years' : `Year ${selectedFY}`} — plan and track your taxes
          </p>
        </div>
        <div className="flex items-center gap-3">
          {/* FY picker */}
          <div className="relative">
            <button onClick={() => setShowFYDrop(v => !v)}
              className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium border"
              style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)', backgroundColor:'var(--surface)' }}>
              FY {taxFY}
              <ChevronDown size={13} style={{ transition:'transform 0.15s', transform:showFYDrop?'rotate(180deg)':'rotate(0deg)' }} />
            </button>
            {showFYDrop && (
              <>
                <div className="fixed inset-0 z-40" onClick={() => setShowFYDrop(false)} />
                <div className="absolute top-full mt-1.5 right-0 z-50 rounded-xl border overflow-hidden"
                  style={{ backgroundColor:'var(--surface)', borderColor:'var(--outline-variant)', boxShadow:'var(--shadow-md)', minWidth:120 }}>
                  {FY_OPTIONS.map(fy => {
                    const fyStart = parseInt(fy.split('-')[0], 10)
                    const isFuture = fyStart > parseInt(currentFY.split('-')[0], 10)
                    return (
                      <button key={fy} onClick={() => { setTaxFY(fy); setShowFYDrop(false) }}
                        disabled={isFuture}
                        className="w-full flex items-center justify-between px-4 py-2.5 text-left text-xs font-mono transition-colors"
                        style={{ color: isFuture ? 'var(--on-surface-variant)' : fy === taxFY ? '#2ab5a0' : 'var(--on-surface)', opacity: isFuture ? 0.4 : 1, borderBottom:'1px solid var(--outline-variant)' }}
                        onMouseEnter={e => { if (!isFuture) e.currentTarget.style.backgroundColor='var(--surface-container-low)' }}
                        onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                        FY {fy}
                        {fy === taxFY && !isFuture && <Check size={11} style={{ color:'#2ab5a0' }} />}
                      </button>
                    )
                  })}
                </div>
              </>
            )}
          </div>
          {/* Regime toggle */}
          <div className="flex rounded-lg overflow-hidden" style={{ border:'1px solid var(--outline-variant)' }}>
            {['new','old'].map(r => (
              <button key={r} onClick={() => setRegime(r)}
                className="px-5 py-2 text-sm font-semibold uppercase transition-colors"
                style={{ backgroundColor:regime===r?'#2ab5a0':'transparent', color:regime===r?'white':'var(--on-surface-variant)' }}>
                {r} Regime
              </button>
            ))}
          </div>
          <button onClick={() => downloadPdf('itr')} className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium border transition-colors"
            style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
            <Download size={13} /> ITR PDF
          </button>
          <button onClick={() => downloadPdf('monthly')} className="flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium border"
            style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
            <Download size={13} /> CA Report
          </button>
        </div>
      </div>

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {[
          { label:'Estimated Tax Due', val:formatINR(t?.total_tax), color:'var(--error)', sub:`FY ${getFinancialYear()} (${regime.toUpperCase()})` },
          { label:'Tax Paid (Advance)', val:formatINR(totalPaid), color:'var(--positive)', sub:'Via advance tax' },
          { label:'Net Payable', val:formatINR(netPayable), color:netPayable>0?'#ba1a1a':'#006b5d', sub:netPayable>0?'Still to pay':'Fully paid' },
        ].map(({ label, val, color, sub }) => (
          <Card key={label} className="p-5" style={{ borderTop:`3px solid ${color}` }}>
            <p className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
            <p className="text-2xl font-bold font-mono" style={{ color:'var(--on-surface)' }}>{loading ? '—' : val}</p>
            <p className="text-xs mt-1" style={{ color:'var(--on-surface-variant)' }}>{sub}</p>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Left: Income by Head + Deductions — col-span-8 */}
        <div className="lg:col-span-8 space-y-5">
          <Card className="overflow-hidden">
            <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
              <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Income by Head</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                    {['Head','Income','Tax Rate','Tax Amount'].map(h => (
                      <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${['Income','Tax Amount'].includes(h)?'text-right':'text-left'}`}
                        style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    [...Array(4)].map((_,i)=><tr key={i}><td colSpan={4} className="px-5 py-3"><div className="h-5 shimmer rounded"/></td></tr>)
                  ) : [
                    { head:'Salary Income', income:t?.salary_income, rate:'Slab', tax:t?.salary_tax },
                    { head:'Business Income', income:t?.business_income, rate:'Slab', tax:t?.business_tax },
                    { head:'STCG (Equity)', income:(t?.capital_gains||0)/2, rate:'15%', tax:t?.stcg_tax },
                    { head:'LTCG (Equity)', income:(t?.capital_gains||0)/2, rate:'10%', tax:t?.ltcg_tax },
                  ].map(({ head, income, rate, tax }) => (
                    <tr key={head} style={{ borderBottom:'1px solid var(--outline-variant)' }}
                      onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                      onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                      <td className="px-5 py-3.5 text-sm font-medium" style={{ color:'var(--on-surface)' }}>{head}</td>
                      <td className="px-5 py-3.5 text-right text-sm font-mono" style={{ color:'var(--on-surface)' }}>{formatINR(income||0)}</td>
                      <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{rate}</td>
                      <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:'var(--error)' }}>{formatINR(tax||0)}</td>
                    </tr>
                  ))}
                  <tr style={{ backgroundColor:'var(--surface-container-low)', borderTop:'2px solid var(--outline-variant)' }}>
                    <td className="px-5 py-3 text-sm font-bold" style={{ color:'var(--on-surface)' }}>TOTAL</td>
                    <td className="px-5 py-3 text-right text-sm font-bold font-mono" style={{ color:'var(--on-surface)' }}>{formatINR(t?.total_income||0)}</td>
                    <td />
                    <td className="px-5 py-3 text-right text-sm font-bold font-mono" style={{ color:'var(--error)' }}>{formatINR(t?.total_tax||0)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </Card>

          {/* Deductions */}
          <Card className="p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Deductions Strategy</h3>
              <button onClick={() => setShowDedModal(true)} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold" style={{ backgroundColor:'rgba(42,181,160,0.12)', color:'var(--primary-container)', border:'1px solid rgba(42,181,160,0.2)' }}>
                <Plus size={12} /> Add
              </button>
            </div>
            <div className="space-y-4">
              {Object.entries(DEDUCTION_LIMITS).map(([section, limit]) => {
                const used = usedBySection[section] || 0
                const pct = Math.min((used/limit)*100, 100)
                const color = DEDUCTION_COLORS[section]
                return (
                  <div key={section}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Section {section}</span>
                      <span className="text-xs font-mono">
                        <span style={{ color }}>{formatINR(used)}</span>
                        <span style={{ color:'var(--on-surface-variant)' }}> / {formatINR(limit)}</span>
                      </span>
                    </div>
                    <div className="h-2 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container)' }}>
                      <div className="h-full rounded-full transition-all" style={{ width:`${pct}%`, backgroundColor:color }} />
                    </div>
                    <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{pct.toFixed(0)}% of limit used</p>
                  </div>
                )
              })}
            </div>
          </Card>
        </div>

        {/* Right: Advance Tax + Suggestions + Carryforward — col-span-4 */}
        <div className="lg:col-span-4 space-y-5">
          <Card className="p-5">
            <h3 className="text-base font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Advance Tax Calendar</h3>
            {loading ? <div className="space-y-3">{[...Array(4)].map((_,i)=><div key={i} className="h-14 shimmer rounded"/>)}</div> : (
              <div className="space-y-3">
                {advance.map(p => {
                  const dueDate = new Date(p.due_date)
                  const daysLeft = Math.floor((dueDate - new Date()) / 86400000)
                  const isOverdue = !p.is_paid && daysLeft < 0
                  const accentColor = p.is_paid ? '#006b5d' : isOverdue ? '#ba1a1a' : '#d4932a'
                  return (
                    <div key={p.id} className="flex items-center justify-between p-4 rounded-lg"
                      style={{ borderLeft:`3px solid ${accentColor}`, backgroundColor:`${accentColor}08`, border:`1px solid ${accentColor}25`, borderLeftWidth:3 }}>
                      <div>
                        <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Installment #{p.installment}</p>
                        <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Due: {formatDate(p.due_date)}</p>
                        <p className="text-xs font-mono font-semibold" style={{ color:accentColor }}>
                          {p.is_paid ? '✓ Paid' : daysLeft > 0 ? `${daysLeft} days left` : 'Overdue'}
                        </p>
                      </div>
                      <div className="flex items-center gap-3">
                        <span className="text-sm font-mono font-semibold" style={{ color:'#d4932a' }}>{formatINR(p.amount_due)}</span>
                        {p.is_paid ? (
                          <span className="flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold" style={{ backgroundColor:'rgba(0,107,93,0.12)', color:'var(--positive)' }}>
                            <Check size={10} /> PAID
                          </span>
                        ) : (
                          <button onClick={() => markPaid(p.id)} className="flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold" style={{ backgroundColor:'#2ab5a0', color:'white' }}>
                            <Check size={10} /> Pay
                          </button>
                        )}
                      </div>
                    </div>
                  )
                })}
                {advance.length === 0 && <p className="text-sm text-center py-6" style={{ color:'var(--on-surface-variant)' }}>No advance tax data</p>}
              </div>
            )}
          </Card>

          {/* Tax Saving Suggestions */}
          {suggestions.length > 0 && (
            <Card className="p-5">
              <h3 className="text-base font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Tax Saving Suggestions</h3>
              <div className="space-y-3">
                {suggestions.map((s,i) => (
                  <div key={i} className="flex items-start gap-3 p-3 rounded-lg" style={{ backgroundColor:'rgba(212,147,42,0.08)', border:'1px solid rgba(212,147,42,0.2)' }}>
                    <AlertCircle size={15} className="mt-0.5 flex-shrink-0" style={{ color:'#d4932a' }} />
                    <div>
                      <p className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{s.section}</p>
                      <p className="text-xs mt-0.5" style={{ color:'var(--on-surface-variant)' }}>{s.message}</p>
                      {s.potential_saving > 0 && <p className="text-xs mt-1 font-mono font-semibold" style={{ color:'var(--positive)' }}>Save ~{formatINR(s.potential_saving)}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          )}

          {/* Loss Carryforward */}
          {carryforward.length > 0 && (
            <Card className="overflow-hidden">
              <div className="px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                <h3 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>Loss Carry Forward</h3>
              </div>
              <table className="w-full">
                <thead>
                  <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                    {['FY','Type','Remaining','Expires'].map(h => (
                      <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${['Remaining','Expires'].includes(h)?'text-right':'text-left'}`}
                        style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {carryforward.map(cf => (
                    <tr key={cf.id} style={{ borderBottom:'1px solid var(--outline-variant)' }}>
                      <td className="px-5 py-3 text-sm" style={{ color:'var(--on-surface-variant)' }}>{cf.financial_year}</td>
                      <td className="px-5 py-3 text-sm capitalize" style={{ color:'var(--on-surface)' }}>{cf.loss_type.replace('_',' ')}</td>
                      <td className="px-5 py-3 text-right text-sm font-mono font-semibold" style={{ color:'var(--error)' }}>{formatINR(cf.remaining_loss)}</td>
                      <td className="px-5 py-3 text-right text-sm" style={{ color:'var(--on-surface-variant)' }}>{cf.expiry_year}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Card>
          )}
        </div>
      </div>

      {/* Add Deduction Modal */}
      <Modal isOpen={showDedModal} onClose={() => setShowDedModal(false)} title="Add Tax Deduction">
        <div className="space-y-4">
          {[
            { label:'Section', key:'section', type:'select', options:['80C','80D','80CCD','24B','80E','Other'] },
            { label:'Description', key:'description', type:'text', placeholder:'PPF investment' },
            { label:'Amount (₹)', key:'amount', type:'number', placeholder:'150000' },
            { label:'Financial Year', key:'financial_year', type:'text', placeholder:'2025-26' },
          ].map(({ label, key, type, placeholder, options }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
              {type === 'select' ? (
                <select value={dedForm[key]} onChange={e => setDedForm(p => ({ ...p, [key]:e.target.value }))}
                  className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                  style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }}>
                  {options.map(o => <option key={o} value={o}>{o}</option>)}
                </select>
              ) : (
                <input type={type} value={dedForm[key]} onChange={e => setDedForm(p => ({ ...p, [key]:e.target.value }))}
                  placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                  style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
              )}
            </div>
          ))}
          <div className="flex gap-3 pt-2">
            <button onClick={() => setShowDedModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={addDeduction} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor:'#2ab5a0', color:'white' }}>Add Deduction</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
