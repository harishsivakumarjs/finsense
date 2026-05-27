import { AlertTriangle, AlertCircle, Info, CheckCircle } from 'lucide-react'

const levelConfig = {
  danger: {
    color: '#E05A5A',
    bg: 'rgba(224,90,90,0.08)',
    border: 'rgba(224,90,90,0.25)',
    left: '#E05A5A',
    icon: AlertTriangle,
  },
  caution: {
    color: '#D4932A',
    bg: 'rgba(212,147,42,0.08)',
    border: 'rgba(212,147,42,0.25)',
    left: '#D4932A',
    icon: AlertCircle,
  },
  info: {
    color: '#8B7FD4',
    bg: 'rgba(139,127,212,0.08)',
    border: 'rgba(139,127,212,0.2)',
    left: '#8B7FD4',
    icon: Info,
  },
  success: {
    color: '#1FA98A',
    bg: 'rgba(31,169,138,0.08)',
    border: 'rgba(31,169,138,0.2)',
    left: '#1FA98A',
    icon: CheckCircle,
  },
}

export default function AlertCard({ level = 'info', message, title }) {
  const config = levelConfig[level] || levelConfig.info
  const Icon = config.icon

  return (
    <div
      className="rounded-2xl p-4 flex items-start gap-3"
      style={{
        backgroundColor: config.bg,
        border: `1px solid ${config.border}`,
        borderLeft: `3px solid ${config.left}`,
      }}
    >
      <Icon size={17} strokeWidth={1.8} style={{ color: config.color, flexShrink: 0, marginTop: 2 }} />
      <div>
        {title && (
          <p className="text-sm font-semibold mb-0.5" style={{ color:config.color }}>
            {title}
          </p>
        )}
        <p className="text-sm" style={{ color:'var(--on-surface-variant)' }}>
          {message}
        </p>
      </div>
    </div>
  )
}
