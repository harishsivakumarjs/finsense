import {
  AreaChart as ReAreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts'
import { formatINRCompact } from '../../utils/format'

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-card border border-white/8 rounded-lg p-3 shadow-xl">
        <p className="text-xs text-text-secondary mb-2">{label}</p>
        {payload.map((entry, i) => (
          <p key={i} className="text-sm font-mono" style={{ color: entry.color }}>
            {entry.name}: {formatINRCompact(entry.value)}
          </p>
        ))}
      </div>
    )
  }
  return null
}

export default function AreaChart({
  data = [],
  lines = [{ key: 'value', color: '#00C9A7', name: 'Value' }],
  height = 220,
}) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <ReAreaChart data={data} margin={{ top: 5, right: 5, left: 0, bottom: 5 }}>
        <defs>
          {lines.map((line) => (
            <linearGradient key={line.key} id={`grad-${line.key}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={line.color} stopOpacity={0.3} />
              <stop offset="95%" stopColor={line.color} stopOpacity={0} />
            </linearGradient>
          ))}
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
        <XAxis
          dataKey="month"
          tick={{ fill: '#8B949E', fontSize: 11 }}
          axisLine={false}
          tickLine={false}
        />
        <YAxis
          tick={{ fill: '#8B949E', fontSize: 11 }}
          axisLine={false}
          tickLine={false}
          tickFormatter={(v) => formatINRCompact(v)}
          width={60}
        />
        <Tooltip content={<CustomTooltip />} />
        {lines.length > 1 && (
          <Legend
            wrapperStyle={{ fontSize: 11, color: '#8B949E', paddingTop: 8 }}
          />
        )}
        {lines.map((line) => (
          <Area
            key={line.key}
            type="monotone"
            dataKey={line.key}
            stroke={line.color}
            fill={`url(#grad-${line.key})`}
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 4, fill: line.color }}
            name={line.name}
          />
        ))}
      </ReAreaChart>
    </ResponsiveContainer>
  )
}
