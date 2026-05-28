import { useState, useEffect, useCallback } from 'react'
import { Sliders, Shield, RefreshCw, Calculator } from 'lucide-react'
import api from '../api/axios'
import { formatINR } from '../utils/format'
import toast from 'react-hot-toast'

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

function SliderField({ label, value, min, max, step=1000, onChange }) {
  const [editing, setEditing] = useState(false)
  const [inputVal, setInputVal] = useState('')

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface-variant)' }}>{label}</label>
        {editing ? (
          <input type="number" value={inputVal} autoFocus
            onChange={e => { setInputVal(e.target.value); const p=parseFloat(e.target.value); if(!isNaN(p)) onChange(Math.min(max,Math.max(min,p))) }}
            onBlur={e => { const p=parseFloat(e.target.value); if(!isNaN(p)) onChange(Math.min(max,Math.max(min,p))); setEditing(false) }}
            onKeyDown={e => { if(e.key==='Enter'||e.key==='Tab') e.target.blur() }}
            className="text-sm font-mono rounded-lg px-2 py-0.5 w-28 focus:outline-none text-right border"
            style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--primary-container)', color:'var(--on-surface)' }}
          />
        ) : (
          <button onClick={() => { setEditing(true); setInputVal(String(value)) }}
            className="text-sm font-mono font-semibold px-2 py-0.5 rounded transition-colors"
            style={{ color:'var(--primary-container)' }}
            onMouseEnter={e => e.currentTarget.style.backgroundColor='rgba(42,181,160,0.08)'}
            onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
            {formatINR(value)}
          </button>
        )}
      </div>
      <input type="range" min={min} max={max} step={step} value={value}
        onChange={e => onChange(parseFloat(e.target.value))}
        className="w-full slider-thumb" />
      <div className="flex justify-between text-xs" style={{ color:'var(--on-surface-variant)' }}>
        <span>{formatINR(min)}</span><span>{formatINR(max)}</span>
      </div>
    </div>
  )
}

function DTIBars({ data }) {
  if (!data?.length) return null
  const maxDti = Math.max(...data.map(d => d.dti||0), 60)
  const barColor = (v) => v > 50 ? '#ba1a1a' : v > 30 ? '#d4932a' : '#006b5d'
  return (
    <div className="space-y-2.5">
      {data.map(d => (
        <div key={d.month} className="flex items-center gap-3">
          <span className="text-xs w-8 flex-shrink-0" style={{ color:'var(--on-surface-variant)' }}>{d.month}</span>
          <div className="flex-1 h-5 rounded-full overflow-hidden" style={{ backgroundColor:'var(--surface-container)' }}>
            <div className="h-full rounded-full transition-all flex items-center justify-end pr-2"
              style={{ width:`${Math.min(((d.dti||0)/maxDti)*100,100)}%`, backgroundColor:barColor(d.dti||0) }}>
            </div>
          </div>
          <span className="text-xs font-mono w-10 text-right flex-shrink-0" style={{ color:barColor(d.dti||0) }}>
            {(d.dti||0).toFixed(1)}%
          </span>
        </div>
      ))}
    </div>
  )
}

export default function Simulator() {
  const [income, setIncome] = useState(80000)
  const [emi, setEmi] = useState(20000)
  const [expenses, setExpenses] = useState(30000)
  const [savings, setSavings] = useState(10000)
  const [emergencyFund, setEmergencyFund] = useState(100000)
  const [skipEmiAmount, setSkipEmiAmount] = useState(15000)
  const [skipRate, setSkipRate] = useState(10)
  const [result, setResult] = useState(null)
  const [skipResult, setSkipResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [skipLoading, setSkipLoading] = useState(false)
  const [defaults] = useState({ income:80000, emi:20000, expenses:30000, savings:10000, emergencyFund:100000 })

  // Loan calculator
  const [loanCalc, setLoanCalc] = useState({ principal: '', rate: '', tenure: '' })
  const [loanResult, setLoanResult] = useState(null)

  const runScenario = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.post('/simulator/scenario', { income, emi, expenses, savings, emergency_fund:emergencyFund })
      setResult(res.data)
    } catch {} finally { setLoading(false) }
  }, [income, emi, expenses, savings, emergencyFund])

  const runSkipEmi = useCallback(async () => {
    setSkipLoading(true)
    try {
      const res = await api.post('/simulator/skipemi', { emi_amount:skipEmiAmount, interest_rate:skipRate })
      setSkipResult(res.data)
    } catch {} finally { setSkipLoading(false) }
  }, [skipEmiAmount, skipRate])

  useEffect(() => { const t = setTimeout(() => runScenario(), 400); return () => clearTimeout(t) }, [income, emi, expenses, savings, emergencyFund])
  useEffect(() => { runScenario(); runSkipEmi() }, [])

  const resetDefaults = () => {
    setIncome(defaults.income); setEmi(defaults.emi); setExpenses(defaults.expenses)
    setSavings(defaults.savings); setEmergencyFund(defaults.emergencyFund)
  }

  const calcLoan = () => {
    const P = parseFloat(loanCalc.principal)
    const annualRate = parseFloat(loanCalc.rate)
    const n = parseInt(loanCalc.tenure)
    if (!P || P <= 0 || !annualRate || annualRate <= 0 || !n || n <= 0) {
      toast.error('Fill all loan calculator fields')
      return
    }
    const r = annualRate / 12 / 100
    const emiVal = (P * r * Math.pow(1 + r, n)) / (Math.pow(1 + r, n) - 1)
    const totalPayment = emiVal * n
    const totalInterest = totalPayment - P
    setLoanResult({ emi: emiVal, totalInterest, totalPayment })
  }

  const r = result
  const scoreColor = r?.verdict?.color === 'teal' ? '#006b5d' : r?.verdict?.color === 'amber' ? '#d4932a' : '#ba1a1a'
  const dtiColor = (v) => v > 50 ? '#ba1a1a' : v > 30 ? '#d4932a' : '#006b5d'
  const forecastData = r?.forecast || []

  return (
    <div className="p-4 md:p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Financial Simulator</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Model scenarios and see live results</p>
        </div>
        <button onClick={resetDefaults} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border"
          style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
          <RefreshCw size={15} /> Reset
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-11 gap-5">
        {/* Left: Sliders */}
        <div className="lg:col-span-6">
          <Card className="p-6">
            <div className="flex items-center gap-2 mb-5">
              <Sliders size={16} style={{ color:'var(--primary-container)' }} />
              <h3 className="text-sm font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface)' }}>Adjust Scenario</h3>
            </div>
            <div className="space-y-6">
              <SliderField label="Monthly Income" value={income} min={10000} max={500000} step={5000} onChange={setIncome} />
              <SliderField label="Total EMIs" value={emi} min={0} max={200000} step={2000} onChange={setEmi} />
              <SliderField label="Monthly Expenses" value={expenses} min={5000} max={200000} step={2000} onChange={setExpenses} />
              <SliderField label="Monthly Savings" value={savings} min={0} max={200000} step={2000} onChange={setSavings} />
              <SliderField label="Emergency Fund" value={emergencyFund} min={0} max={1000000} step={10000} onChange={setEmergencyFund} />
            </div>
          </Card>
        </div>

        {/* Right: Live Results */}
        <div className="lg:col-span-5 space-y-4">
          {/* 2x2 Result Grid */}
          <div className="grid grid-cols-2 gap-3">
            {[
              { label:'DTI Ratio',    val:`${r?.dti || 0}%`,              color:dtiColor(r?.dti||0) },
              { label:'Free Cash',   val:formatINR(r?.free_cash||0),      color:(r?.free_cash||0)>=0?'#006b5d':'#ba1a1a' },
              { label:'Debt Score',  val:`${r?.debt_score||0}/100`,       color:scoreColor },
              { label:'Savings Rate',val:`${r?.savings_rate||0}%`,        color:(r?.savings_rate||0)>=20?'#006b5d':'#d4932a' },
            ].map(({ label, val, color }) => (
              <Card key={label} className="p-4">
                <p className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
                <p className="text-2xl font-mono font-bold" style={{ color }}>{loading ? '—' : val}</p>
              </Card>
            ))}
          </div>

          {/* Verdict */}
          {r?.verdict && (
            <Card className="p-5" style={{ borderLeft:`4px solid ${scoreColor}` }}>
              <div className="flex items-center gap-3">
                <Shield size={20} style={{ color:scoreColor, flexShrink:0 }} />
                <div>
                  <div className="flex items-center gap-2 mb-0.5">
                    <span className="text-2xl font-mono font-bold" style={{ color:scoreColor }}>{r.debt_score}</span>
                    <span className="text-sm font-semibold capitalize" style={{ color:scoreColor }}>{r.verdict.level} Zone</span>
                  </div>
                  <p className="text-sm" style={{ color:'var(--on-surface-variant)' }}>{r.verdict.message}</p>
                </div>
              </div>
            </Card>
          )}

          {/* Projected DTI Forecast (HTML bars) */}
          {forecastData.length > 0 && (
            <Card className="p-5">
              <h3 className="text-sm font-semibold mb-4" style={{ color:'var(--on-surface)' }}>Projected Debt Ratio (6 Months)</h3>
              <DTIBars data={forecastData} />
            </Card>
          )}
        </div>
      </div>

      {/* Bottom row: Skip EMI Scenario | Loan Calculator */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {/* Skip EMI Scenario */}
        <Card className="p-6">
          <h3 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color:'var(--error)' }}>
            Skip EMI Scenario
          </h3>
          <p className="text-xs mb-4" style={{ color:'var(--on-surface-variant)' }}>Extra cost if you skip one EMI payment</p>
          <div className="grid grid-cols-2 gap-3 mb-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>EMI Amount (₹)</p>
              <input type="number" value={skipEmiAmount} onChange={e => setSkipEmiAmount(parseFloat(e.target.value)||0)}
                className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Interest Rate (%)</p>
              <input type="number" value={skipRate} onChange={e => setSkipRate(parseFloat(e.target.value)||0)}
                className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
            </div>
          </div>
          <button onClick={runSkipEmi} disabled={skipLoading}
            className="w-full py-2.5 rounded-lg text-sm font-semibold flex items-center justify-center gap-2 transition-all"
            style={{ backgroundColor:'rgba(186,26,26,0.1)', color:'var(--error)', border:'1px solid rgba(186,26,26,0.2)', opacity:skipLoading?0.7:1 }}>
            {skipLoading ? 'Calculating…' : 'Calculate Impact'}
          </button>
          {skipResult && (
            <div className="grid grid-cols-2 gap-3 mt-4 pt-4" style={{ borderTop:'1px solid var(--outline-variant)' }}>
              {[
                { label:'Penalty',        val:formatINR(skipResult.penalty),        color:'var(--error)' },
                { label:'Extra Interest', val:formatINR(skipResult.extra_interest), color:'#d4932a' },
                { label:'CIBIL Impact',   val:`-${skipResult.cibil_impact} pts`,    color:'var(--error)' },
                { label:'Total Cost',     val:formatINR(skipResult.total_cost),      color:'var(--error)' },
              ].map(({ label, val, color }) => (
                <div key={label} className="p-3 rounded-lg text-center" style={{ backgroundColor:'var(--surface-container-low)' }}>
                  <p className="text-xs mb-1" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
                  <p className="text-sm font-mono font-bold" style={{ color }}>{val}</p>
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* Loan / EMI Calculator */}
        <Card className="p-6">
          <div className="flex items-center gap-2 mb-4">
            <Calculator size={16} style={{ color:'#2ab5a0' }} />
            <h3 className="text-sm font-semibold uppercase tracking-wider" style={{ color:'var(--on-surface)' }}>Loan Calculator</h3>
          </div>
          <p className="text-xs mb-4" style={{ color:'var(--on-surface-variant)' }}>Calculate monthly EMI, total interest and payment</p>
          <div className="space-y-3 mb-4">
            {[
              { key:'principal', label:'Loan Amount (₹)',         placeholder:'500000' },
              { key:'rate',      label:'Annual Interest Rate (%)', placeholder:'8.5' },
              { key:'tenure',    label:'Loan Tenure (months)',     placeholder:'60' },
            ].map(({ key, label, placeholder }) => (
              <div key={key}>
                <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
                <input type="number" value={loanCalc[key]} onChange={e => setLoanCalc(p => ({ ...p, [key]:e.target.value }))}
                  onKeyDown={e => e.key === 'Enter' && calcLoan()}
                  placeholder={placeholder} className="w-full px-4 py-2.5 rounded-lg text-sm focus:outline-none border"
                  style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
              </div>
            ))}
          </div>
          <button onClick={calcLoan}
            className="w-full py-2.5 rounded-lg text-sm font-semibold"
            style={{ backgroundColor:'#2ab5a0', color:'white' }}>
            Calculate EMI
          </button>
          {loanResult && (
            <div className="grid grid-cols-3 gap-3 mt-4 pt-4" style={{ borderTop:'1px solid var(--outline-variant)' }}>
              {[
                { label:'Monthly EMI',    val:formatINR(loanResult.emi),          color:'#2ab5a0' },
                { label:'Total Interest', val:formatINR(loanResult.totalInterest), color:'var(--error)' },
                { label:'Total Payment',  val:formatINR(loanResult.totalPayment),  color:'var(--on-surface)' },
              ].map(({ label, val, color }) => (
                <div key={label} className="p-3 rounded-lg text-center" style={{ backgroundColor:'var(--surface-container-low)' }}>
                  <p className="text-xs mb-1" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
                  <p className="text-sm font-mono font-bold" style={{ color }}>{val}</p>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </div>
  )
}
