import {
  LineChart as ReLineChart,
  Line,
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

export default function LineChart({
  data = [],
  lines = [{ key: 'value', color: '#00C9A7', name: 'Value' }],
  height = 220,
  xKey = 'month',
}) {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <ReLineChart data={data} margin={{ top: 5, right: 5, left: 0, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.04)" />
        <XAxis
          dataKey={xKey}
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
          <Legend wrapperStyle={{ fontSize: 11, color: '#8B949E', paddingTop: 8 }} />
        )}
        {lines.map((line) => (
          <Line
            key={line.key}
            type="monotone"
            dataKey={line.key}
            stroke={line.color}
            strokeWidth={2}
            dot={{ r: 3, fill: line.color, strokeWidth: 0 }}
            activeDot={{ r: 5, fill: line.color }}
            name={line.name}
          />
        ))}
      </ReLineChart>
    </ResponsiveContainer>
  )
}
