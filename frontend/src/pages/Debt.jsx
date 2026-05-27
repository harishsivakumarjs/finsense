import { useEffect, useState } from 'react'
import { Plus, Pencil, Trash2, CreditCard, AlertTriangle } from 'lucide-react'
import toast from 'react-hot-toast'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate } from '../utils/format'
import useStore from '../store/useStore'

const BLANK_LOAN = {
  loan_type: 'personal', loan_name: '', bank_name: '', principal: '', emi_amount: '',
  interest_rate: '', start_date: new Date().toISOString().split('T')[0], months_total: '',
}
const BLANK_CARD = {
  card_name: '', bank_name: '', credit_limit: '', outstanding: '', minimum_due: '', due_date: '', statement_date: '',
}

const Card = ({ children, className = '', style = {} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow: '0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

export default function Debt() {
  const { selectedFY } = useStore()
  const [loans, setLoans] = useState([])
  const [cards, setCards] = useState([])
  const [score, setScore] = useState(null)
  const [forecast, setForecast] = useState([])
  const [debtFree, setDebtFree] = useState(null)
  const [loading, setLoading] = useState(true)
  const [showLoanModal, setShowLoanModal] = useState(false)
  const [editLoan, setEditLoan] = useState(null)
  const [loanForm, setLoanForm] = useState(BLANK_LOAN)
  const [showCardModal, setShowCardModal] = useState(false)
  const [editCard, setEditCard] = useState(null)
  const [cardForm, setCardForm] = useState(BLANK_CARD)
  const [detailLoan, setDetailLoan] = useState(null)
  const [detailCard, setDetailCard] = useState(null)

  const load = async () => {
    setLoading(true)
    try {
      const [loansR, cardsR, scoreR, forecastR, dfR] = await Promise.all([
        api.get('/loans'),
        api.get('/loans/cards'),
        api.get('/loans/score'),
        api.get('/loans/forecast'),
        api.get('/loans/debtfree'),
      ])
      setLoans(loansR.data)
      setCards(cardsR.data)
      setScore(scoreR.data)
      setForecast(forecastR.data)
      setDebtFree(dfR.data?.debt_free)
    } catch { toast.error('Failed to load debt data') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [selectedFY])

  const openAddLoan = () => { setEditLoan(null); setLoanForm(BLANK_LOAN); setShowLoanModal(true) }
  const openEditLoan = (loan) => {
    setEditLoan(loan)
    setLoanForm({ loan_type: loan.loan_type, loan_name: loan.loan_name, bank_name: loan.bank_name || '', principal: loan.principal, emi_amount: loan.emi_amount, interest_rate: loan.interest_rate, start_date: loan.start_date, months_total: loan.months_total })
    setShowLoanModal(true)
  }
  const openAddCard = () => { setEditCard(null); setCardForm(BLANK_CARD); setShowCardModal(true) }
  const openEditCard = (card) => {
    setEditCard(card)
    setCardForm({ card_name: card.card_name, bank_name: card.bank_name || '', credit_limit: card.credit_limit, outstanding: card.outstanding, minimum_due: card.minimum_due, due_date: card.due_date || '', statement_date: card.statement_date || '' })
    setShowCardModal(true)
  }

  const saveLoan = async () => {
    if (!loanForm.loan_name || !loanForm.principal) return toast.error('Fill required fields')
    try {
      if (editLoan) { await api.put(`/loans/${editLoan.id}`, loanForm); toast.success('Updated') }
      else { await api.post('/loans', loanForm); toast.success('Loan added') }
      setShowLoanModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const saveCard = async () => {
    if (!cardForm.card_name || !cardForm.credit_limit) return toast.error('Fill required fields')
    try {
      if (editCard) { await api.put(`/loans/cards/${editCard.id}`, cardForm); toast.success('Updated') }
      else { await api.post('/loans/cards', cardForm); toast.success('Card added') }
      setShowCardModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const deleteLoan = async (id) => {
    if (!confirm('Delete loan?')) return
    try { await api.delete(`/loans/${id}`); toast.success('Deleted'); setShowLoanModal(false); load() }
    catch { toast.error('Failed') }
  }
  const deleteCard = async (id) => {
    if (!confirm('Delete card?')) return
    try { await api.delete(`/loans/cards/${id}`); toast.success('Deleted'); setShowCardModal(false); load() }
    catch { toast.error('Failed') }
  }
  const s = score
  const scoreValue = s?.score || 0
  const scoreColor = scoreValue < 40 ? '#006b5d' : scoreValue < 70 ? '#d4932a' : '#ba1a1a'
  const scoreLabel = scoreValue < 40 ? 'Safe' : scoreValue < 70 ? 'Caution' : 'Danger'

  const getProgress = (loan) => {
    const today = new Date()
    const start = new Date(loan.start_date)
    const elapsed = Math.floor((today - start) / (1000 * 60 * 60 * 24 * 30))
    return Math.min((elapsed / loan.months_total) * 100, 100)
  }

  const activeLoans = loans.filter(l => l.is_active)
  const sortedByRate = [...activeLoans].sort((a, b) => parseFloat(b.interest_rate) - parseFloat(a.interest_rate))
  const sortedByBalance = [...activeLoans].sort((a, b) => parseFloat(a.principal) - parseFloat(b.principal))

  const forecastData = Array.isArray(forecast) ? forecast : []
  const dtiColorFn = (val) => val < 40 ? '#006b5d' : val < 70 ? '#d4932a' : '#ba1a1a'

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor: 'var(--background)', minHeight: '100%' }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: 'var(--on-surface)' }}>Debt Manager</h1>
          <p className="text-sm mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>Track loans and credit cards</p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={openAddLoan} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#2ab5a0', color: 'white' }}>
            <Plus size={16} /> Add Loan
          </button>
          <button onClick={openAddCard} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold" style={{ backgroundColor: 'var(--surface)', color: 'var(--on-surface)', border: '1px solid var(--outline-variant)' }}>
            <CreditCard size={16} /> Add Card
          </button>
        </div>
      </div>

      {/* Danger Score */}
      <Card className="p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <AlertTriangle size={18} style={{ color: scoreColor }} />
            <h2 className="text-sm font-semibold uppercase tracking-wider" style={{ color: 'var(--on-surface-variant)' }}>Debt Danger Score</h2>
          </div>
          {debtFree && typeof debtFree === 'object' && (
            <span className="text-xs px-3 py-1 rounded-full font-medium" style={{ backgroundColor: 'var(--surface-container-low)', color: 'var(--on-surface-variant)' }}>
              Debt free: <span className="font-mono font-semibold" style={{ color: 'var(--primary-container)' }}>{debtFree.formatted}</span>
            </span>
          )}
        </div>
        <div className="flex items-center gap-8">
          <div className="text-center">
            <p className="text-5xl font-mono font-bold" style={{ color: scoreColor }}>{scoreValue}</p>
            <span className="inline-block mt-1 px-3 py-0.5 rounded-full text-xs font-semibold" style={{ backgroundColor: `${scoreColor}18`, color: scoreColor }}>{scoreLabel}</span>
          </div>
          <div className="flex-1">
            <div className="flex justify-between text-xs mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>
              <span>Safe (0–39)</span><span>Caution (40–69)</span><span>Danger (70+)</span>
            </div>
            <div className="h-3 rounded-full overflow-hidden flex relative">
              <div className="h-full" style={{ width: '40%', backgroundColor: '#006b5d', opacity: 0.5 }} />
              <div className="h-full" style={{ width: '30%', backgroundColor: '#d4932a', opacity: 0.5 }} />
              <div className="h-full rounded-r-full" style={{ width: '30%', backgroundColor: '#ba1a1a', opacity: 0.5 }} />
              <div className="absolute top-1/2 -translate-y-1/2 w-3 h-3 rounded-full bg-white border-2"
                style={{ left: `calc(${Math.min(scoreValue, 99)}% - 6px)`, borderColor: scoreColor, boxShadow: `0 0 6px ${scoreColor}60` }} />
            </div>
            <p className="text-sm mt-3" style={{ color: 'var(--on-surface-variant)' }}>{s?.verdict?.message || 'Add loans to calculate your score'}</p>
            <div className="flex gap-6 mt-3 text-xs">
              {[
                { label: 'Monthly Income', val: formatINR(s?.monthly_income), color: 'var(--primary)' },
                { label: 'Total EMI', val: formatINR(s?.total_emi), color: '#d4932a' },
                { label: 'DTI', val: `${s?.dti?.toFixed(1) || 0}%`, color: scoreColor },
              ].map(({ label, val, color }) => (
                <div key={label}>
                  <span style={{ color: 'var(--on-surface-variant)' }}>{label}: </span>
                  <span className="font-mono font-semibold" style={{ color }}>{loading ? '—' : val}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </Card>

      <div className="grid grid-cols-2 gap-5">
        {/* Active Loans */}
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>Active Loans</h3>
            <button onClick={openAddLoan} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium" style={{ backgroundColor: 'var(--primary-container)', color: 'white' }}>
              <Plus size={12} /> Add
            </button>
          </div>
          {loading ? <div className="space-y-3">{[...Array(3)].map((_,i)=><div key={i} className="h-16 shimmer rounded"/>)}</div>
          : activeLoans.length === 0 ? (
            <div className="py-10 text-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>No active loans</div>
          ) : (
            <div className="space-y-3">
              {activeLoans.map(loan => {
                const prog = getProgress(loan)
                return (
                  <div key={loan.id} className="p-3 rounded-lg cursor-pointer transition-colors"
                    style={{ border: '1px solid var(--outline-variant)' }}
                    onClick={() => setDetailLoan(loan)}
                    onMouseEnter={e => e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}>
                    <div className="flex items-center justify-between mb-2">
                      <div>
                        <p className="text-sm font-semibold" style={{ color: 'var(--on-surface)' }}>{loan.loan_name}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="px-2 py-0.5 rounded-full text-xs font-semibold capitalize" style={{ backgroundColor: 'rgba(74,142,212,0.12)', color: '#4a8ed4' }}>{loan.loan_type.replace('_',' ')}</span>
                          <span className="text-xs font-mono" style={{ color: '#4a8ed4' }}>{loan.interest_rate}% p.a.</span>
                          {loan.bank_name && <span className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>{loan.bank_name}</span>}
                        </div>
                      </div>
                      <div className="flex items-center gap-2" onClick={e => { e.stopPropagation() }}>
                        <div className="text-right mr-1">
                          <p className="text-sm font-mono font-semibold" style={{ color: '#d4932a' }}>EMI {formatINR(loan.emi_amount)}</p>
                          <p className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>{loan.months_total} months</p>
                        </div>
                        <button onClick={() => openEditLoan(loan)} className="p-1.5 rounded-lg" style={{ color: 'var(--on-surface-variant)' }}
                          onMouseEnter={e => e.currentTarget.style.color='var(--primary-container)'}
                          onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Pencil size={12} />
                        </button>
                        <button onClick={() => deleteLoan(loan.id)} className="p-1.5 rounded-lg" style={{ color: 'var(--on-surface-variant)' }}
                          onMouseEnter={e => e.currentTarget.style.color='var(--error)'}
                          onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                    <div className="h-1.5 rounded-full overflow-hidden" style={{ backgroundColor: 'var(--surface-container)' }}>
                      <div className="h-full rounded-full" style={{ width: `${prog}%`, backgroundColor: '#4a8ed4' }} />
                    </div>
                    <p className="text-xs mt-1" style={{ color: 'var(--on-surface-variant)' }}>
                      {prog.toFixed(0)}% paid · Balance: <span className="font-mono">{formatINR(parseFloat(loan.principal) * (1 - prog/100))}</span>
                    </p>
                  </div>
                )
              })}
            </div>
          )}
        </Card>

        {/* Credit Cards */}
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold" style={{ color: 'var(--on-surface)' }}>Credit Cards</h3>
            <button onClick={openAddCard} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium" style={{ backgroundColor: 'var(--primary-container)', color: 'white' }}>
              <Plus size={12} /> Add
            </button>
          </div>
          {loading ? <div className="space-y-3">{[...Array(2)].map((_,i)=><div key={i} className="h-20 shimmer rounded"/>)}</div>
          : cards.length === 0 ? (
            <div className="py-10 text-center text-sm" style={{ color: 'var(--on-surface-variant)' }}>No credit cards</div>
          ) : (
            <div className="space-y-4">
              {cards.map(card => {
                const util = card.credit_limit > 0 ? (parseFloat(card.outstanding)/parseFloat(card.credit_limit))*100 : 0
                const utilColor = util < 30 ? '#006b5d' : util < 70 ? '#d4932a' : '#ba1a1a'
                const circumference = 2 * Math.PI * 20
                return (
                  <div key={card.id} className="p-4 rounded-lg" style={{ border: '1px solid var(--outline-variant)', cursor: 'pointer' }}
                    onClick={() => setDetailCard(card)}>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        {/* SVG ring */}
                        <svg width="52" height="52" viewBox="0 0 52 52">
                          <circle cx="26" cy="26" r="20" fill="none" stroke="var(--surface-container)" strokeWidth="5" />
                          <circle cx="26" cy="26" r="20" fill="none" stroke={utilColor} strokeWidth="5"
                            strokeDasharray={circumference} strokeDashoffset={circumference * (1 - util/100)}
                            strokeLinecap="round" transform="rotate(-90 26 26)" />
                          <text x="26" y="30" textAnchor="middle" fontSize="10" fontFamily="JetBrains Mono" fontWeight="600" fill={utilColor}>{Math.round(util)}%</text>
                        </svg>
                        <div>
                          <p className="text-sm font-semibold" style={{ color: 'var(--on-surface)' }}>{card.card_name}</p>
                          <p className="text-xs" style={{ color: 'var(--on-surface-variant)' }}>{card.bank_name}</p>
                          <p className="text-xs font-mono mt-0.5" style={{ color: 'var(--error)' }}>Outstanding: {formatINR(card.outstanding)}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1" onClick={e => e.stopPropagation()}>
                        <button onClick={() => openEditCard(card)} className="p-1.5 rounded-lg" style={{ color: 'var(--on-surface-variant)' }}
                          onMouseEnter={e => e.currentTarget.style.color='var(--primary-container)'}
                          onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Pencil size={12} />
                        </button>
                        <button onClick={() => deleteCard(card.id)} className="p-1.5 rounded-lg" style={{ color: 'var(--on-surface-variant)' }}
                          onMouseEnter={e => e.currentTarget.style.color='var(--error)'}
                          onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 mt-3 text-xs">
                      <div><span style={{ color: 'var(--on-surface-variant)' }}>Limit: </span><span className="font-mono" style={{ color: 'var(--on-surface)' }}>{formatINR(card.credit_limit)}</span></div>
                      <div><span style={{ color: 'var(--on-surface-variant)' }}>Min Due: </span><span className="font-mono" style={{ color: '#d4932a' }}>{formatINR(card.minimum_due)}</span></div>
                      {card.due_date && <div><span style={{ color: 'var(--on-surface-variant)' }}>Due Date: </span><span style={{ color: 'var(--on-surface)' }}>Day {card.due_date}</span></div>}
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </Card>
      </div>

      {/* 6-Month DTI Forecast */}
      {forecastData.length > 0 && (
        <Card className="p-5">
          <h3 className="text-base font-semibold mb-4" style={{ color: 'var(--on-surface)' }}>6-Month DTI Forecast</h3>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={forecastData} barSize={32}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--outline-variant)" vertical={false} />
              <XAxis dataKey="month" tick={{ fontSize: 11, fill: 'var(--on-surface-variant)' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: 'var(--on-surface-variant)' }} axisLine={false} tickLine={false} unit="%" domain={[0,100]} />
              <Tooltip formatter={v => `${v?.toFixed(1)}%`} contentStyle={{ backgroundColor: 'var(--surface)', border: '1px solid var(--outline-variant)', borderRadius: 8, fontSize: 12 }} />
              <Bar dataKey="dti" radius={[4,4,0,0]}>
                {forecastData.map((entry, index) => (
                  <Cell key={index} fill={dtiColorFn(entry.dti)} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </Card>
      )}

      <DetailModal
        isOpen={!!detailLoan}
        onClose={() => setDetailLoan(null)}
        title={detailLoan?.loan_name || 'Loan Detail'}
        color="#4a8ed4"
        badge={detailLoan?.loan_type?.replace('_', ' ')}
        rows={detailLoan ? [
          { label: 'Loan Name', value: detailLoan.loan_name },
          { label: 'Type', value: detailLoan.loan_type?.replace('_', ' ') },
          { label: 'Lender / Bank', value: detailLoan.bank_name || '—' },
          { label: 'Principal', value: formatINR(detailLoan.principal), valueStyle: { fontFamily: 'monospace' } },
          { label: 'EMI Amount', value: formatINR(detailLoan.emi_amount), valueStyle: { fontFamily: 'monospace', color: '#d4932a' } },
          { label: 'Interest Rate', value: `${detailLoan.interest_rate}% p.a.` },
          { label: 'Tenure', value: `${detailLoan.months_total} months` },
          { label: 'Start Date', value: formatDate(detailLoan.start_date) },
          { label: 'Balance (est.)', value: formatINR(parseFloat(detailLoan.principal) * (1 - getProgress(detailLoan) / 100)), valueStyle: { fontFamily: 'monospace' } },
        ] : []}
      />

      <DetailModal
        isOpen={!!detailCard}
        onClose={() => setDetailCard(null)}
        title={detailCard?.card_name || 'Credit Card Detail'}
        color="#8b7fd4"
        badge={detailCard?.bank_name}
        rows={detailCard ? [
          { label: 'Card Name', value: detailCard.card_name },
          { label: 'Bank', value: detailCard.bank_name || '—' },
          { label: 'Credit Limit', value: formatINR(detailCard.credit_limit), valueStyle: { fontFamily: 'monospace' } },
          { label: 'Outstanding', value: formatINR(detailCard.outstanding), valueStyle: { fontFamily: 'monospace', color: 'var(--error)' } },
          { label: 'Minimum Due', value: formatINR(detailCard.minimum_due), valueStyle: { fontFamily: 'monospace', color: '#d4932a' } },
          { label: 'Utilization', value: `${detailCard.credit_limit > 0 ? ((parseFloat(detailCard.outstanding) / parseFloat(detailCard.credit_limit)) * 100).toFixed(1) : 0}%` },
          { label: 'Due Date', value: detailCard.due_date ? `Day ${detailCard.due_date} of month` : '—' },
        ] : []}
      />

      {/* Add Loan Modal */}
      <Modal isOpen={showLoanModal} onClose={() => setShowLoanModal(false)} title={editLoan ? 'Edit Loan' : 'Add Loan'}>
        <div className="space-y-4">
          {[
            { label: 'Loan Name', key: 'loan_name', type: 'text', placeholder: 'Home Loan' },
            { label: 'Bank/Lender', key: 'bank_name', type: 'text', placeholder: 'HDFC Bank' },
            { label: 'Principal (₹)', key: 'principal', type: 'number', placeholder: '500000' },
            { label: 'EMI Amount (₹)', key: 'emi_amount', type: 'number', placeholder: '15000' },
            { label: 'Interest Rate (%)', key: 'interest_rate', type: 'number', placeholder: '8.5' },
            { label: 'Tenure (months)', key: 'months_total', type: 'number', placeholder: '60' },
          ].map(({ label, key, type, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <input type={type} value={loanForm[key]} onChange={e => setLoanForm(p => ({ ...p, [key]: e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
            </div>
          ))}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Loan Type</p>
            <select value={loanForm.loan_type} onChange={e => setLoanForm(p => ({ ...p, loan_type: e.target.value }))}
              className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
              style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }}>
              {['personal','home','car','education','gold','other'].map(t => <option key={t} value={t}>{t.replace(/^\w/,c=>c.toUpperCase())}</option>)}
            </select>
          </div>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>Start Date</p>
            <DatePickerInput value={loanForm.start_date} onChange={v => setLoanForm(p => ({ ...p, start_date: v }))} />
          </div>
          <div className="flex gap-3 pt-2">
            {editLoan && <button onClick={() => deleteLoan(editLoan.id)} className="px-5 py-3 rounded-lg text-sm font-medium" style={{ color: 'var(--error)', border: '1px solid var(--error)', backgroundColor: 'var(--error-container)' }}>Delete</button>}
            <button onClick={() => setShowLoanModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor: 'var(--outline-variant)', color: 'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={saveLoan} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#2ab5a0', color: 'white' }}>{editLoan ? 'Save' : 'Add Loan'}</button>
          </div>
        </div>
      </Modal>

      {/* Add Card Modal */}
      <Modal isOpen={showCardModal} onClose={() => setShowCardModal(false)} title={editCard ? 'Edit Card' : 'Add Credit Card'}>
        <div className="space-y-4">
          {[
            { label: 'Card Name', key: 'card_name', placeholder: 'HDFC Regalia' },
            { label: 'Bank', key: 'bank_name', placeholder: 'HDFC Bank' },
            { label: 'Credit Limit (₹)', key: 'credit_limit', placeholder: '100000' },
            { label: 'Outstanding (₹)', key: 'outstanding', placeholder: '25000' },
            { label: 'Minimum Due (₹)', key: 'minimum_due', placeholder: '1250' },
            { label: 'Due Date (day of month)', key: 'due_date', placeholder: '15' },
          ].map(({ label, key, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color: 'var(--on-surface-variant)' }}>{label}</p>
              <input type={key.includes('date') ? 'number' : key.includes('credit')||key.includes('outstanding')||key.includes('minimum') ? 'number' : 'text'}
                value={cardForm[key]} onChange={e => setCardForm(p => ({ ...p, [key]: e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor: 'var(--surface-container-low)', borderColor: 'var(--outline-variant)', color: 'var(--on-surface)' }} />
            </div>
          ))}
          <div className="flex gap-3 pt-2">
            {editCard && <button onClick={() => deleteCard(editCard.id)} className="px-5 py-3 rounded-lg text-sm font-medium" style={{ color: 'var(--error)', border: '1px solid var(--error)', backgroundColor: 'var(--error-container)' }}>Delete</button>}
            <button onClick={() => setShowCardModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor: 'var(--outline-variant)', color: 'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={saveCard} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor: '#2ab5a0', color: 'white' }}>{editCard ? 'Save' : 'Add Card'}</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
