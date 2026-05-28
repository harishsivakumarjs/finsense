import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import useStore from './store/useStore'

// Pages
import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import Income from './pages/Income'
import Expenses from './pages/Expenses'
import Debt from './pages/Debt'
import Trading from './pages/Trading'
import Investments from './pages/Investments'
import Creator from './pages/Creator'
import Tax from './pages/Tax'
import NetWorth from './pages/NetWorth'
import Friends from './pages/Friends'
import Simulator from './pages/Simulator'
import Insurance from './pages/Insurance'
import Reports from './pages/Reports'
import Settings from './pages/Settings'

// Layout
import Sidebar from './components/Sidebar'
import TopBar from './components/TopBar'

function PrivateRoute({ children, title }) {
  const { token, sidebarCollapsed } = useStore()
  const [mobileNavOpen, setMobileNavOpen] = useState(false)
  const [isMobile, setIsMobile] = useState(() => window.innerWidth < 768)

  useEffect(() => {
    const handler = () => setIsMobile(window.innerWidth < 768)
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])

  if (!token) return <Navigate to="/login" replace />

  const sideW = isMobile ? 0 : (sidebarCollapsed ? 64 : 220)

  return (
    <div className="flex h-screen overflow-hidden" style={{ backgroundColor: 'var(--background)' }}>
      <Sidebar mobileOpen={mobileNavOpen} onMobileClose={() => setMobileNavOpen(false)} />
      <div
        className="flex flex-col flex-1 overflow-hidden min-w-0"
        style={{ marginLeft: sideW, transition: 'margin-left 0.2s ease' }}
      >
        <TopBar title={title} onMenuClick={() => setMobileNavOpen(true)} />
        <main className="flex-1 overflow-y-auto">
          {children}
        </main>
      </div>
    </div>
  )
}

export default function App() {
  const { theme } = useStore()

  useEffect(() => {
    // Light is default — apply 'dark' class only for dark mode
    document.documentElement.classList.toggle('dark', theme === 'dark')
  }, [theme])

  return (
    <BrowserRouter>
      <Toaster
        position="top-right"
        toastOptions={{
          style: {
            background: 'var(--surface)',
            color: 'var(--on-surface)',
            border: '1px solid var(--outline-variant)',
            fontSize: '14px',
            boxShadow: 'var(--shadow-card)',
          },
          success: { iconTheme: { primary: '#2ab5a0', secondary: 'white' } },
          error:   { iconTheme: { primary: '#ba1a1a', secondary: 'white' } },
        }}
      />

      <Routes>
        <Route path="/login"    element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/"         element={<Navigate to="/dashboard" replace />} />

        <Route path="/dashboard"  element={<PrivateRoute title="Dashboard"><Dashboard /></PrivateRoute>} />
        <Route path="/income"     element={<PrivateRoute title="Income"><Income /></PrivateRoute>} />
        <Route path="/expenses"   element={<PrivateRoute title="Expenses"><Expenses /></PrivateRoute>} />
        <Route path="/debt"       element={<PrivateRoute title="Debt Manager"><Debt /></PrivateRoute>} />
        <Route path="/trading"    element={<PrivateRoute title="Trading"><Trading /></PrivateRoute>} />
        <Route path="/investments" element={<PrivateRoute title="Investments"><Investments /></PrivateRoute>} />
        <Route path="/creator"    element={<PrivateRoute title="Creator Hub"><Creator /></PrivateRoute>} />
        <Route path="/tax"        element={<PrivateRoute title="Tax Planner"><Tax /></PrivateRoute>} />
        <Route path="/networth"   element={<PrivateRoute title="Net Worth"><NetWorth /></PrivateRoute>} />
        <Route path="/friends"    element={<PrivateRoute title="Friends Ledger"><Friends /></PrivateRoute>} />
        <Route path="/simulator"  element={<PrivateRoute title="Simulator"><Simulator /></PrivateRoute>} />
        <Route path="/insurance"  element={<PrivateRoute title="Insurance"><Insurance /></PrivateRoute>} />
        <Route path="/reports"    element={<PrivateRoute title="Reports"><Reports /></PrivateRoute>} />
        <Route path="/settings"   element={<PrivateRoute title="Settings"><Settings /></PrivateRoute>} />

        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </BrowserRouter>
  )
}
