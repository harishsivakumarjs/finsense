/**
 * Format amount in Indian number system (e.g., ₹1,24,500)
 */
export function formatINR(amount) {
  if (amount === null || amount === undefined) return '₹0'
  const num = parseFloat(amount)
  if (isNaN(num)) return '₹0'

  const isNegative = num < 0
  const abs = Math.abs(num)

  const [intPart, decPart] = abs.toFixed(2).split('.')
  let result = ''

  if (intPart.length <= 3) {
    result = intPart
  } else {
    result = intPart.slice(-3)
    let remaining = intPart.slice(0, -3)
    while (remaining.length > 2) {
      result = remaining.slice(-2) + ',' + result
      remaining = remaining.slice(0, -2)
    }
    if (remaining) result = remaining + ',' + result
  }

  const formatted = `₹${result}.${decPart}`
  return isNegative ? `-${formatted}` : formatted
}

/**
 * Format amount compactly (e.g., ₹1.2L, ₹45K)
 */
export function formatINRCompact(amount) {
  if (amount === null || amount === undefined) return '₹0'
  const num = parseFloat(amount)
  if (isNaN(num)) return '₹0'

  const isNeg = num < 0
  const abs = Math.abs(num)
  let formatted

  if (abs >= 10000000) {
    formatted = `₹${(abs / 10000000).toFixed(2)}Cr`
  } else if (abs >= 100000) {
    formatted = `₹${(abs / 100000).toFixed(1)}L`
  } else if (abs >= 1000) {
    formatted = `₹${(abs / 1000).toFixed(1)}K`
  } else {
    formatted = `₹${abs.toFixed(0)}`
  }

  return isNeg ? `-${formatted}` : formatted
}

/**
 * Format date as "24 May 2026"
 */
export function formatDate(dateStr) {
  if (!dateStr) return ''
  try {
    const s = String(dateStr).split('T')[0]
    const [y, m, d] = s.split('-').map(Number)
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
    return `${d} ${months[m - 1]} ${y}`
  } catch {
    return dateStr
  }
}

/**
 * Format date as relative "3 days ago"
 */
export function formatRelativeDate(dateStr) {
  if (!dateStr) return ''
  try {
    const d = new Date(dateStr)
    const now = new Date()
    const diffMs = now - d
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

    if (diffDays === 0) return 'Today'
    if (diffDays === 1) return 'Yesterday'
    if (diffDays < 7) return `${diffDays} days ago`
    if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`
    if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`
    return `${Math.floor(diffDays / 365)} years ago`
  } catch {
    return dateStr
  }
}

/**
 * Get financial year string (April to March)
 * e.g., April 2025 - March 2026 = "2025-26"
 */
export function getFinancialYear(date) {
  const d = date ? new Date(date) : new Date()
  const month = d.getMonth() + 1 // 1-indexed
  const year = d.getFullYear()
  const fyStart = month >= 4 ? year : year - 1
  return `${fyStart}-${String(fyStart + 1).slice(-2)}`
}

/**
 * Parse a FY string like "2025-26" into a date range (kept for backward compat)
 */
export function getFYDateRange(fy) {
  const startYear = parseInt(fy.split('-')[0], 10)
  return {
    fromYear: startYear, fromMonth: 4,
    toYear: startYear + 1, toMonth: 3,
    from: `${startYear}-04-01`,
    to:   `${startYear + 1}-03-31`,
  }
}

/**
 * Parse a calendar year string like "2025" or "all" into a date range (Jan–Dec)
 */
export function getYearDateRange(year) {
  if (!year || year === 'all') {
    return { fromYear: 2000, fromMonth: 1, toYear: 2099, toMonth: 12, from: '2000-01-01', to: '2099-12-31' }
  }
  const y = parseInt(year, 10)
  return { fromYear: y, fromMonth: 1, toYear: y, toMonth: 12, from: `${y}-01-01`, to: `${y}-12-31` }
}

/**
 * Format percentage
 */
export function formatPct(value, decimals = 1) {
  if (value === null || value === undefined) return '0%'
  return `${parseFloat(value).toFixed(decimals)}%`
}

/**
 * Get color class based on value (positive = teal, negative = red)
 */
export function getValueColor(value) {
  if (parseFloat(value) > 0) return 'text-teal'
  if (parseFloat(value) < 0) return 'text-danger'
  return 'text-text-secondary'
}

/**
 * Category badge color map
 */
export const CATEGORY_COLORS = {
  food: '#FF6B6B',
  transport: '#4ECDC4',
  bills: '#45B7D1',
  health: '#96E6A1',
  entertainment: '#A8E6CF',
  shopping: '#FFD93D',
  subscriptions: '#6C5CE7',
  education: '#74B9FF',
  other: '#8B949E',
}

export const ASSET_COLORS = {
  mutual_fund: '#00C9A7',
  gold: '#FFA502',
  silver: '#8B949E',
  land: '#7F77DD',
  fd: '#45B7D1',
  ppf: '#96E6A1',
  stocks: '#FF6B6B',
  insurance: '#74B9FF',
  other: '#8B94A0',
}
