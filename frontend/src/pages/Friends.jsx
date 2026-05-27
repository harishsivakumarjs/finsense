import { useEffect, useState } from 'react'
import { Plus, Search, Check, Users, Download, Pencil, Trash2 } from 'lucide-react'
import toast from 'react-hot-toast'
import api from '../api/axios'
import Modal from '../components/Modal'
import DetailModal from '../components/DetailModal'
import DatePickerInput from '../components/DatePickerInput'
import { formatINR, formatDate, formatRelativeDate } from '../utils/format'

const BLANK_FORM = { friend_name:'', amount:'', reason:'', date:new Date().toISOString().split('T')[0], direction:'receivable' }
const AVATAR_COLORS = ['#2ab5a0','#4a8ed4','#8b7fd4','#d4932a','#ba1a1a','#4f5e80']

const Card = ({ children, className='', style={} }) => (
  <div className={`rounded-xl bg-white ${className}`} style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', ...style }}>
    {children}
  </div>
)

export default function Friends() {
  const [entries, setEntries] = useState([])
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [filter, setFilter] = useState('all')
  const [showModal, setShowModal] = useState(false)
  const [editEntry, setEditEntry] = useState(null)
  const [detail, setDetail] = useState(null)
  const [form, setForm] = useState(BLANK_FORM)

  const load = async () => {
    setLoading(true)
    try {
      const [entriesR, sumR] = await Promise.all([
        api.get('/friends'),
        api.get('/friends/summary'),
      ])
      setEntries(entriesR.data)
      setSummary(sumR.data)
    } catch { toast.error('Failed to load') }
    finally { setLoading(false) }
  }

  useEffect(() => { load() }, [])

  const openAdd = () => { setEditEntry(null); setForm(BLANK_FORM); setShowModal(true) }
  const openEdit = (entry) => {
    setEditEntry(entry)
    const amt = parseFloat(entry.amount)
    setForm({ friend_name:entry.friend_name, amount:Math.abs(amt).toString(), reason:entry.reason||'', date:entry.date, direction:amt>0?'receivable':'payable' })
    setShowModal(true)
  }
  const handleSave = async () => {
    if (!form.friend_name || !form.amount) return toast.error('Fill required fields')
    const amount = form.direction === 'receivable' ? parseFloat(form.amount) : -parseFloat(form.amount)
    try {
      if (editEntry) { await api.put(`/friends/${editEntry.id}`, { friend_name:form.friend_name, amount, reason:form.reason, date:form.date }); toast.success('Updated') }
      else { await api.post('/friends', { friend_name:form.friend_name, amount, reason:form.reason, date:form.date }); toast.success('Entry added') }
      setShowModal(false); load()
    } catch { toast.error('Failed to save') }
  }
  const handleDelete = async (id) => {
    if (!confirm('Delete entry?')) return
    try { await api.delete(`/friends/${id}`); toast.success('Deleted'); setShowModal(false); load() }
    catch { toast.error('Failed') }
  }
  const settleUp = async (id) => {
    try { await api.put(`/friends/${id}/settle`); toast.success('Settled!'); load() }
    catch { toast.error('Failed to settle') }
  }
  const exportCSV = () => {
    const rows = [['Name','Amount','Reason','Date','Status']]
    filtered.forEach(e => rows.push([e.friend_name, e.amount, e.reason||'', e.date, e.is_settled?'SETTLED':'PENDING']))
    const csv = rows.map(r=>r.join(',')).join('\n')
    const blob = new Blob([csv], { type:'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a'); a.href = url; a.download = 'friends_ledger.csv'; a.click()
  }

  const filtered = entries.filter(e => {
    const match = e.friend_name.toLowerCase().includes(search.toLowerCase()) || (e.reason||'').toLowerCase().includes(search.toLowerCase())
    if (filter === 'unsettled') return match && !e.is_settled
    return match
  })

  const s = summary
  const netVal = s?.net || 0

  return (
    <div className="p-6 space-y-5" style={{ backgroundColor:'var(--background)', minHeight:'100%' }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color:'var(--on-surface)' }}>Friends Ledger</h1>
          <p className="text-sm mt-0.5" style={{ color:'var(--on-surface-variant)' }}>Track money owed and lent</p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={exportCSV} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium border" style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>
            <Download size={15} /> Export
          </button>
          <button onClick={openAdd} className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold" style={{ backgroundColor:'#2ab5a0', color:'white' }}>
            <Plus size={16} /> Add Entry
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 gap-4">
        <Card className="p-5" style={{ borderLeft:'4px solid #006b5d' }}>
          <p className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color:'var(--on-surface-variant)' }}>You Are Owed</p>
          <p className="text-3xl font-bold font-mono" style={{ color:'var(--positive)' }}>{loading ? '—' : formatINR(s?.total_receivable || 0)}</p>
          <p className="text-sm mt-1" style={{ color:'var(--on-surface-variant)' }}>From {s?.receivable_friends_count || 0} friend(s)</p>
        </Card>
        <Card className="p-5" style={{ borderLeft:'4px solid #d4932a' }}>
          <p className="text-xs font-semibold uppercase tracking-wider mb-2" style={{ color:'var(--on-surface-variant)' }}>You Owe</p>
          <p className="text-3xl font-bold font-mono" style={{ color:'#d4932a' }}>{loading ? '—' : formatINR(s?.total_payable || 0)}</p>
          <p className="text-sm mt-1" style={{ color:'var(--on-surface-variant)' }}>To {s?.payable_friends_count || 0} friend(s)</p>
        </Card>
      </div>

      {/* Ledger Table */}
      <Card className="overflow-hidden">
        {/* Toolbar */}
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
          <div className="flex items-center gap-3">
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" style={{ color:'var(--on-surface-variant)' }} />
              <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Search friend..."
                className="pl-9 pr-4 py-2 rounded-lg text-sm focus:outline-none"
                style={{ width:200, backgroundColor:'var(--surface-container-low)', border:'1px solid var(--outline-variant)', color:'var(--on-surface)' }} />
            </div>
            <div className="flex rounded-lg overflow-hidden" style={{ border:'1px solid var(--outline-variant)' }}>
              {[['all','All'],['unsettled','Unsettled']].map(([f,l]) => (
                <button key={f} onClick={() => setFilter(f)}
                  className="px-4 py-2 text-xs font-semibold transition-colors"
                  style={{ backgroundColor:filter===f?'#2ab5a0':'transparent', color:filter===f?'white':'var(--on-surface-variant)' }}>
                  {l}
                </button>
              ))}
            </div>
          </div>
          <span className="text-sm" style={{ color:'var(--on-surface-variant)' }}>{filtered.length} entries</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor:'var(--surface-container-low)' }}>
                {['Friend','Amount','Reason','Date','Days Since','Status','Actions'].map(h => (
                  <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wider ${['Amount','Actions'].includes(h)?'text-right':'text-left'}`}
                    style={{ color:'var(--on-surface-variant)', borderBottom:'1px solid var(--outline-variant)' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_,i)=><tr key={i}><td colSpan={7} className="px-5 py-3"><div className="h-5 shimmer rounded"/></td></tr>)
              ) : filtered.length === 0 ? (
                <tr><td colSpan={7} className="px-5 py-12 text-center" style={{ color:'var(--on-surface-variant)' }}>
                  <Users size={28} className="mx-auto mb-3 opacity-40" />
                  <p className="text-sm">No entries found. <button onClick={openAdd} style={{ color:'var(--primary-container)' }} className="underline">Add one</button></p>
                </td></tr>
              ) : filtered.map((entry, idx) => {
                const amt = parseFloat(entry.amount)
                const isReceivable = amt > 0
                const avatarColor = AVATAR_COLORS[idx % AVATAR_COLORS.length]
                const daysSince = Math.floor((new Date() - new Date(entry.date)) / 86400000)
                return (
                  <tr key={entry.id} className="group" style={{ borderBottom:'1px solid var(--outline-variant)', cursor:'pointer' }}
                    onClick={() => setDetail(entry)}
                    onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
                    onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
                    <td className="px-5 py-3.5">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
                          style={{ backgroundColor:`${avatarColor}18`, color:avatarColor }}>
                          {entry.friend_name.slice(0,2).toUpperCase()}
                        </div>
                        <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>{entry.friend_name}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3.5 text-right text-sm font-mono font-semibold" style={{ color:entry.is_settled?'var(--on-surface-variant)':isReceivable?'#006b5d':'#d4932a' }}>
                      {isReceivable?'+':'-'}{formatINR(Math.abs(amt))}
                    </td>
                    <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{entry.reason || '—'}</td>
                    <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{formatDate(entry.date)}</td>
                    <td className="px-5 py-3.5 text-sm" style={{ color:'var(--on-surface-variant)' }}>{daysSince}d ago</td>
                    <td className="px-5 py-3.5">
                      {entry.is_settled ? (
                        <span className="px-2.5 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor:'rgba(0,107,93,0.12)', color:'var(--positive)' }}>Settled</span>
                      ) : (
                        <span className="px-2.5 py-1 rounded-full text-xs font-semibold" style={{ backgroundColor:'rgba(212,147,42,0.12)', color:'#d4932a' }}>Pending</span>
                      )}
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity" onClick={e => e.stopPropagation()}>
                        {!entry.is_settled && (
                          <button onClick={() => settleUp(entry.id)} className="p-1.5 rounded-lg" title="Settle"
                            style={{ color:'var(--on-surface-variant)' }}
                            onMouseEnter={e => e.currentTarget.style.color='#006b5d'}
                            onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                            <Check size={13} />
                          </button>
                        )}
                        <button onClick={() => openEdit(entry)} className="p-1.5 rounded-lg"
                          style={{ color:'var(--on-surface-variant)' }}
                          onMouseEnter={e => e.currentTarget.style.color='var(--primary-container)'}
                          onMouseLeave={e => e.currentTarget.style.color='var(--on-surface-variant)'}>
                          <Pencil size={13} />
                        </button>
                        <button onClick={() => handleDelete(entry.id)} className="p-1.5 rounded-lg"
                          style={{ color:'var(--on-surface-variant)' }}
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

        {/* Net Position Footer */}
        {entries.length > 0 && (
          <div className="px-5 py-4 flex items-center justify-between" style={{ borderTop:'2px solid var(--outline-variant)', backgroundColor:'var(--surface-container-low)' }}>
            <div className="flex items-center gap-4">
              <span className="text-sm font-semibold" style={{ color:'var(--on-surface)' }}>Net Position:</span>
              <span className="text-lg font-bold font-mono" style={{ color:netVal>=0?'#006b5d':'#ba1a1a' }}>
                {netVal>=0?'+':''}{formatINR(netVal)}
              </span>
            </div>
          </div>
        )}
      </Card>

      <DetailModal
        isOpen={!!detail}
        onClose={() => setDetail(null)}
        title={detail?.friend_name || 'Ledger Detail'}
        color={parseFloat(detail?.amount || 0) > 0 ? '#006b5d' : '#d4932a'}
        badge={detail?.is_settled ? 'Settled' : 'Pending'}
        rows={detail ? (() => {
          const amt = parseFloat(detail.amount)
          const isReceivable = amt > 0
          const daysSince = Math.floor((new Date() - new Date(detail.date)) / 86400000)
          return [
            { label: 'Friend', value: detail.friend_name },
            { label: 'Type', value: isReceivable ? 'They owe me' : 'I owe them' },
            { label: 'Amount', value: `${isReceivable ? '+' : '-'}${formatINR(Math.abs(amt))}`, valueStyle: { fontFamily: 'monospace', color: isReceivable ? '#006b5d' : '#d4932a' } },
            { label: 'Reason', value: detail.reason || '—' },
            { label: 'Date', value: formatDate(detail.date) },
            { label: 'Days Since', value: `${daysSince} days` },
            { label: 'Status', value: detail.is_settled ? 'Settled' : 'Pending' },
          ]
        })() : []}
      />

      {/* Modal */}
      <Modal isOpen={showModal} onClose={() => setShowModal(false)} title={editEntry ? 'Edit Entry' : 'Add Entry'}>
        <div className="space-y-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Direction</p>
            <div className="grid grid-cols-2 gap-2">
              {[['receivable','They owe me'],['payable','I owe them']].map(([d,l]) => (
                <button key={d} onClick={() => setForm(p => ({ ...p, direction:d }))}
                  className="py-3 rounded-lg text-sm font-semibold transition-colors"
                  style={{ backgroundColor:form.direction===d?(d==='receivable'?'rgba(0,107,93,0.12)':'rgba(212,147,42,0.12)'):'var(--surface-container-low)', color:form.direction===d?(d==='receivable'?'#006b5d':'#d4932a'):'var(--on-surface-variant)', border:`1px solid ${form.direction===d?(d==='receivable'?'#006b5d':'#d4932a'):'var(--outline-variant)'}` }}>
                  {l}
                </button>
              ))}
            </div>
          </div>
          {[
            { label:'Friend Name', key:'friend_name', type:'text', placeholder:'Rahul Kumar' },
            { label:'Amount (₹)', key:'amount', type:'number', placeholder:'1500' },
            { label:'Reason', key:'reason', type:'text', placeholder:'Dinner at restaurant' },
          ].map(({ label, key, type, placeholder }) => (
            <div key={key}>
              <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
              <input type={type} value={form[key]} onChange={e => setForm(p => ({ ...p, [key]:e.target.value }))}
                placeholder={placeholder} className="w-full px-4 py-3 rounded-lg text-sm focus:outline-none border"
                style={{ backgroundColor:'var(--surface-container-low)', borderColor:'var(--outline-variant)', color:'var(--on-surface)' }} />
            </div>
          ))}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider mb-1.5" style={{ color:'var(--on-surface-variant)' }}>Date</p>
            <DatePickerInput value={form.date} onChange={v => setForm(p => ({ ...p, date:v }))} />
          </div>
          <div className="flex gap-3 pt-2">
            {editEntry && <button onClick={() => handleDelete(editEntry.id)} className="px-5 py-3 rounded-lg text-sm font-medium" style={{ color:'var(--error)', border:'1px solid var(--error)', backgroundColor:'var(--error-container)' }}>Delete</button>}
            <button onClick={() => setShowModal(false)} className="flex-1 py-3 rounded-lg text-sm font-medium border" style={{ borderColor:'var(--outline-variant)', color:'var(--on-surface-variant)' }}>Cancel</button>
            <button onClick={handleSave} className="flex-1 py-3 rounded-lg text-sm font-semibold" style={{ backgroundColor:'#2ab5a0', color:'white' }}>{editEntry ? 'Save' : 'Add Entry'}</button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
