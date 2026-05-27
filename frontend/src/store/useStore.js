import { create } from 'zustand'
import api from '../api/axios'

const useStore = create((set, get) => ({
  // Theme
  theme: localStorage.getItem('finsense_theme') || 'light',
  setTheme: (theme) => {
    localStorage.setItem('finsense_theme', theme)
    document.documentElement.classList.toggle('dark', theme === 'dark')
    set({ theme })
  },

  // Sidebar collapse
  sidebarCollapsed: localStorage.getItem('finsense_sidebar') === 'true',
  setSidebarCollapsed: (collapsed) => {
    localStorage.setItem('finsense_sidebar', String(collapsed))
    set({ sidebarCollapsed: collapsed })
  },

  // Selected calendar year (Jan-Dec) or 'all'
  selectedFY: (() => {
    const saved = localStorage.getItem('finsense_fy')
    if (saved && (saved === 'all' || /^\d{4}$/.test(saved))) return saved
    return String(new Date().getFullYear())
  })(),
  setSelectedFY: (fy) => {
    localStorage.setItem('finsense_fy', fy)
    set({ selectedFY: fy })
  },

  // Avatar
  avatar: localStorage.getItem('finsense_avatar') || null,
  setAvatar: (url) => {
    if (url) localStorage.setItem('finsense_avatar', url)
    else localStorage.removeItem('finsense_avatar')
    set({ avatar: url })
  },

  // Auth state
  user: JSON.parse(localStorage.getItem('finsense_user') || 'null'),
  token: localStorage.getItem('finsense_token') || null,

  setUser: (user) => {
    localStorage.setItem('finsense_user', JSON.stringify(user))
    set({ user })
  },

  setToken: (token) => {
    localStorage.setItem('finsense_token', token)
    set({ token })
  },

  logout: () => {
    localStorage.removeItem('finsense_token')
    localStorage.removeItem('finsense_user')
    localStorage.removeItem('finsense_avatar')
    set({ user: null, token: null, avatar: null })
  },

  // Dashboard data
  dashboard: null,
  dashboardLoading: false,

  fetchDashboard: async () => {
    set({ dashboardLoading: true })
    try {
      const res = await api.get('/dashboard')
      set({ dashboard: res.data, dashboardLoading: false })
    } catch (err) {
      set({ dashboardLoading: false })
      throw err
    }
  },

  // Expenses
  expenses: [],
  expensesLoading: false,

  fetchExpenses: async (params = {}) => {
    set({ expensesLoading: true })
    try {
      const res = await api.get('/expenses', { params })
      set({ expenses: res.data, expensesLoading: false })
    } catch (err) {
      set({ expensesLoading: false })
      throw err
    }
  },

  // Loans
  loans: [],
  creditCards: [],
  loansLoading: false,

  fetchLoans: async () => {
    set({ loansLoading: true })
    try {
      const [loansRes, cardsRes] = await Promise.all([
        api.get('/loans'),
        api.get('/loans/cards'),
      ])
      set({ loans: loansRes.data, creditCards: cardsRes.data, loansLoading: false })
    } catch (err) {
      set({ loansLoading: false })
      throw err
    }
  },

  // Trades
  trades: [],
  tradesLoading: false,

  fetchTrades: async (params = {}) => {
    set({ tradesLoading: true })
    try {
      const res = await api.get('/trades', { params })
      set({ trades: res.data, tradesLoading: false })
    } catch (err) {
      set({ tradesLoading: false })
      throw err
    }
  },

  // Investments
  investments: [],
  investmentsLoading: false,

  fetchInvestments: async () => {
    set({ investmentsLoading: true })
    try {
      const res = await api.get('/investments')
      set({ investments: res.data, investmentsLoading: false })
    } catch (err) {
      set({ investmentsLoading: false })
      throw err
    }
  },

  // Friends
  friends: [],
  friendsLoading: false,

  fetchFriends: async (params = {}) => {
    set({ friendsLoading: true })
    try {
      const res = await api.get('/friends', { params })
      set({ friends: res.data, friendsLoading: false })
    } catch (err) {
      set({ friendsLoading: false })
      throw err
    }
  },

  // Income
  incomeEntries: [],
  incomeLoading: false,

  fetchIncome: async (params = {}) => {
    set({ incomeLoading: true })
    try {
      const res = await api.get('/income', { params })
      set({ incomeEntries: res.data, incomeLoading: false })
    } catch (err) {
      set({ incomeLoading: false })
      throw err
    }
  },
}))

export default useStore
