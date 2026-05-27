import { TrendingUp, TrendingDown } from 'lucide-react'
import { formatINR } from '../utils/format'

const COLOR_MAP = {
  teal:    { hex:'var(--positive)',          bg:'rgba(42,181,160,0.12)'  },
  red:     { hex:'var(--error)',             bg:'rgba(186,26,26,0.12)'   },
  amber:   { hex:'var(--warning)',           bg:'rgba(212,147,42,0.12)'  },
  purple:  { hex:'var(--purple)',            bg:'rgba(139,127,212,0.12)' },
  info:    { hex:'var(--info)',              bg:'rgba(74,142,212,0.12)'  },
  default: { hex:'var(--on-surface-variant)',bg:'rgba(108,122,118,0.1)'  },
}

export default function MetricCard({ title, value, subtitle, trend, trendDirection, color='teal', icon:Icon, isAmount=true, loading=false }) {
  const c = COLOR_MAP[color] || COLOR_MAP.default

  if (loading) {
    return (
      <div className="rounded-xl bg-white p-5" style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', borderTop:`2px solid ${c.hex}` }}>
        <div className="flex items-start justify-between">
          <div className="w-12 h-12 shimmer rounded-lg" />
          <div className="h-5 w-14 shimmer rounded-full" />
        </div>
        <div className="h-3 w-20 shimmer rounded mt-3 mb-1" />
        <div className="h-7 w-28 shimmer rounded mb-3" />
        <div className="h-px w-full shimmer rounded mb-3" />
        <div className="h-3 w-24 shimmer rounded" />
      </div>
    )
  }

  return (
    <div className="rounded-xl bg-white p-5 flex flex-col" style={{ boxShadow:'0px 4px 12px rgba(0,0,0,0.05)', borderTop:`2px solid ${c.hex}` }}>
      <div className="flex items-start justify-between">
        {Icon ? (
          <div className="w-12 h-12 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor:c.bg }}>
            <Icon size={20} strokeWidth={1.8} style={{ color:c.hex }} />
          </div>
        ) : <div className="w-12 h-12" />}

        {trend !== undefined && trend !== null && (
          <div className="flex items-center gap-0.5 text-xs font-semibold px-2 py-1 rounded-full"
            style={{ backgroundColor:trendDirection==='up'?'rgba(42,181,160,0.12)':'rgba(186,26,26,0.12)', color:trendDirection==='up'?'var(--positive)':'var(--error)' }}>
            {trendDirection === 'up' ? <TrendingUp size={11} /> : <TrendingDown size={11} />}
            {Math.abs(trend).toFixed(1)}%
          </div>
        )}
      </div>

      <span className="text-xs font-semibold uppercase tracking-wider mt-3 mb-1" style={{ color:'var(--on-surface-variant)' }}>{title}</span>

      <div className="font-mono font-semibold" style={{ fontSize:24, letterSpacing:'-0.02em', lineHeight:1.2, color:'var(--on-surface)' }}>
        {isAmount ? formatINR(value) : value}
      </div>

      <div className="mt-3 mb-3" style={{ height:1, backgroundColor:'var(--outline-variant)' }} />

      {subtitle && <span className="text-xs" style={{ color:'var(--on-surface-variant)' }}>{subtitle}</span>}
    </div>
  )
}
