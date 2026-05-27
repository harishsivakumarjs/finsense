import { BarChart as ReBarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, Cell } from 'recharts'
import { formatINRCompact } from '../../utils/format'

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload && payload.length) {
    return (
      <div className="rounded-xl shadow-xl" style={{ backgroundColor:'var(--surface)', border:'1px solid var(--outline-variant)', padding:'10px 14px' }}>
        <p className="text-xs mb-2" style={{ color:'var(--on-surface-variant)' }}>{label}</p>
        {payload.map((entry, i) => (
          <p key={i} className="text-sm font-semibold font-mono" style={{ color:entry.color||entry.fill }}>
            {entry.name}: {formatINRCompact(entry.value)}
          </p>
        ))}
      </div>
    )
  }
  return null
}

export default function BarChart({ data=[], bars=[{ key:'value', color:'#2ab5a0', name:'Value' }], height=220, colorByValue=false }) {
  const firstKey = data[0] ? ('month' in data[0] ? 'month' : Object.keys(data[0])[0]) : 'name'

  return (
    <ResponsiveContainer width="100%" height={height}>
      <ReBarChart data={data} margin={{ top:4, right:4, left:0, bottom:4 }} barCategoryGap="32%">
        <CartesianGrid strokeDasharray="3 3" stroke="var(--outline-variant)" vertical={false} />
        <XAxis dataKey={firstKey} tick={{ fill:'var(--on-surface-variant)', fontSize:11 }} axisLine={false} tickLine={false} />
        <YAxis tick={{ fill:'var(--on-surface-variant)', fontSize:11 }} axisLine={false} tickLine={false} tickFormatter={v => formatINRCompact(v)} width={56} />
        <Tooltip content={<CustomTooltip />} cursor={{ fill:'rgba(0,0,0,0.04)' }} />
        {bars.length > 1 && <Legend wrapperStyle={{ fontSize:11, color:'var(--on-surface-variant)', paddingTop:8 }} />}
        {bars.map((bar) => (
          <Bar key={bar.key} dataKey={bar.key} fill={bar.color||'#2ab5a0'} radius={[4,4,0,0]} name={bar.name}>
            {bar.colorFn && data.map((entry, i) => <Cell key={`cell-${i}`} fill={bar.colorFn(entry[bar.key])} />)}
            {colorByValue && !bar.colorFn && data.map((entry, i) => <Cell key={`cell-${i}`} fill={entry[bar.key]>=0?'#2ab5a0':'#ba1a1a'} />)}
          </Bar>
        ))}
      </ReBarChart>
    </ResponsiveContainer>
  )
}
