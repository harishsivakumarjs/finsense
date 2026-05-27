import { X } from 'lucide-react'

function Row({ label, value, valueStyle = {} }) {
  if (value === null || value === undefined || value === '') return null
  return (
    <div className="flex items-start justify-between py-2.5" style={{ borderBottom: '1px solid var(--outline-variant)' }}>
      <span className="text-xs font-semibold uppercase tracking-wider flex-shrink-0 w-36" style={{ color: 'var(--on-surface-variant)' }}>{label}</span>
      <span className="text-sm text-right font-medium" style={{ color: 'var(--on-surface)', ...valueStyle }}>{value}</span>
    </div>
  )
}

export default function DetailModal({ isOpen, onClose, title, color = '#2ab5a0', icon, rows = [], badge }) {
  if (!isOpen) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}
      onClick={e => { if (e.target === e.currentTarget) onClose() }}>
      <div className="w-full max-w-md rounded-2xl overflow-hidden"
        style={{ backgroundColor: 'var(--surface)', boxShadow: '0 16px 48px rgba(0,0,0,0.25)' }}>
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: '1px solid var(--outline-variant)', backgroundColor: `${color}0d` }}>
          <div className="flex items-center gap-3">
            {icon && (
              <div className="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                style={{ backgroundColor: `${color}20` }}>
                {icon}
              </div>
            )}
            <div>
              <h3 className="text-base font-bold" style={{ color: 'var(--on-surface)' }}>{title}</h3>
              {badge && (
                <span className="text-xs font-semibold px-2 py-0.5 rounded-full capitalize"
                  style={{ backgroundColor: `${color}20`, color }}>
                  {badge}
                </span>
              )}
            </div>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg transition-colors"
            style={{ color: 'var(--on-surface-variant)' }}
            onMouseEnter={e => e.currentTarget.style.backgroundColor = 'var(--surface-container-low)'}
            onMouseLeave={e => e.currentTarget.style.backgroundColor = 'transparent'}>
            <X size={16} />
          </button>
        </div>
        {/* Rows */}
        <div className="px-5 py-1 max-h-[60vh] overflow-y-auto">
          {rows.map((r, i) => <Row key={i} {...r} />)}
        </div>
      </div>
    </div>
  )
}
