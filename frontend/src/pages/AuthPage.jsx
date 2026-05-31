import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Eye, EyeOff, Check, Zap, TrendingUp, Shield, BarChart3, Mail, RefreshCw } from 'lucide-react'
import { signInWithPopup } from 'firebase/auth'
import toast from 'react-hot-toast'
import api from '../api/axios'
import { auth, googleProvider } from '../firebase'
import useStore from '../store/useStore'

const DEMO_EMAIL = 'demo@finsense.app'
const DEMO_PASSWORD = 'demo123456'

const FEATURES = [
  { icon: BarChart3, text: 'Track all your income streams in one place' },
  { icon: TrendingUp, text: 'Predict debt risk before it happens' },
  { icon: Shield, text: 'Complete ITR-3 tax planning built in' },
]

/* ── Left decorative panel ── */
function LeftPanel() {
  return (
    <div
      className="hidden lg:flex flex-col justify-between w-1/2 p-12 relative overflow-hidden"
      style={{ backgroundColor: '#0B1426' }}
    >
      {/* Decorative blur circles */}
      <div
        className="absolute pointer-events-none"
        style={{
          top: '-80px',
          right: '-80px',
          width: 320,
          height: 320,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(42,181,160,0.18) 0%, transparent 70%)',
          filter: 'blur(40px)',
        }}
      />
      <div
        className="absolute pointer-events-none"
        style={{
          bottom: '60px',
          left: '-60px',
          width: 280,
          height: 280,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(42,181,160,0.12) 0%, transparent 70%)',
          filter: 'blur(40px)',
        }}
      />
      <div
        className="absolute pointer-events-none"
        style={{
          top: '45%',
          left: '30%',
          width: 200,
          height: 200,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(91,157,246,0.08) 0%, transparent 70%)',
          filter: 'blur(30px)',
        }}
      />

      {/* Logo */}
      <div className="flex items-center gap-3 relative z-10">
        <div
          className="w-9 h-9 rounded-lg flex items-center justify-center font-bold text-base"
          style={{ backgroundColor: '#2AB5A0', color: '#ffffff' }}
        >
          F
        </div>
        <span
          className="text-xl font-bold"
          style={{ fontFamily: 'var(--font-heading)', color: '#ffffff' }}
        >
          FinSense
        </span>
      </div>

      {/* Center content */}
      <div className="relative z-10">
        <h2
          className="text-4xl font-bold mb-3 leading-tight"
          style={{ fontFamily: 'var(--font-heading)', color: '#ffffff' }}
        >
          Elevated financial
          <br />
          <span style={{ color: '#2AB5A0' }}>intelligence</span>
        </h2>
        <p className="text-base mb-10" style={{ color: '#8BA8C8' }}>
          The all-in-one finance OS built for modern Indians.
        </p>

        {/* Feature bullets */}
        <div className="space-y-4">
          {FEATURES.map(({ icon: Icon, text }) => (
            <div key={text} className="flex items-start gap-3">
              <div
                className="w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5"
                style={{ backgroundColor: 'rgba(42,181,160,0.15)', border: '1px solid rgba(42,181,160,0.3)' }}
              >
                <Check size={12} style={{ color: '#2AB5A0' }} />
              </div>
              <span className="text-sm leading-relaxed" style={{ color: '#CBD5E1' }}>{text}</span>
            </div>
          ))}
        </div>

        {/* Dashboard preview card */}
        <div
          className="mt-10 rounded-2xl p-5"
          style={{
            backgroundColor: 'rgba(255,255,255,0.04)',
            border: '1px solid rgba(255,255,255,0.08)',
            backdropFilter: 'blur(10px)',
          }}
        >
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-semibold" style={{ color: '#8BA8C8', letterSpacing: '0.08em' }}>
              NET WORTH
            </span>
            <span className="text-xs px-2 py-0.5 rounded-full font-semibold"
              style={{ backgroundColor: 'rgba(31,169,138,0.15)', color: '#1FA98A' }}>
              +12.4%
            </span>
          </div>
          <div
            className="text-3xl font-semibold mb-1"
            style={{ fontFamily: 'var(--font-mono)', color: '#ffffff', letterSpacing: '-0.02em' }}
          >
            ₹8,53,530
          </div>
          <p className="text-xs" style={{ color: '#8BA8C8' }}>Assets ₹12,40,000</p>

          {/* Mini bar chart preview */}
          <div className="mt-4 flex items-end gap-1.5" style={{ height: 40 }}>
            {[55, 70, 45, 80, 60, 90, 75, 85, 65, 95, 80, 100].map((h, i) => (
              <div
                key={i}
                className="flex-1 rounded-sm"
                style={{
                  height: `${h}%`,
                  backgroundColor: i === 11 ? '#2AB5A0' : 'rgba(42,181,160,0.25)',
                }}
              />
            ))}
          </div>
        </div>
      </div>

      {/* Bottom tagline */}
      <div className="relative z-10">
        <p className="text-xs" style={{ color: '#4D7094' }}>
          Trusted by 10,000+ users · Indian tax engine built-in
        </p>
      </div>
    </div>
  )
}

/* ── Shared Google Sign-In hook ── */
function useGoogleAuth() {
  const navigate = useNavigate()
  const { setUser, setToken } = useStore()
  const [googleLoading, setGoogleLoading] = useState(false)

  const signInWithGoogle = async () => {
    setGoogleLoading(true)
    try {
      const result = await signInWithPopup(auth, googleProvider)
      const idToken = await result.user.getIdToken()
      const res = await api.post('/auth/google/firebase', { id_token: idToken })
      setToken(res.data.access_token)
      setUser(res.data.user)
      toast.success(`Welcome, ${res.data.user.name}!`)
      navigate('/dashboard')
    } catch (err) {
      // User closed the popup — don't show an error
      if (err?.code === 'auth/popup-closed-by-user' || err?.code === 'auth/cancelled-popup-request') return
      toast.error(err?.response?.data?.detail || 'Google sign-in failed. Please try again.')
    } finally {
      setGoogleLoading(false)
    }
  }

  return { signInWithGoogle, googleLoading }
}

/* ── Reusable Google button ── */
function GoogleButton({ onClick, disabled }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="w-full py-3 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-2.5"
      style={{
        backgroundColor: '#ffffff',
        border: '1px solid #dde1e6',
        color: '#191c1e',
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        opacity: disabled ? 0.7 : 1,
      }}
    >
      {disabled ? (
        <svg className="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="10" stroke="#dde1e6" strokeWidth="3" />
          <path d="M12 2a10 10 0 0 1 10 10" stroke="#4285F4" strokeWidth="3" strokeLinecap="round" />
        </svg>
      ) : (
        <svg width="18" height="18" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M47.532 24.552c0-1.636-.132-3.2-.384-4.704H24v9.12h13.184c-.576 3.024-2.256 5.592-4.8 7.32v6.072h7.776c4.56-4.2 7.2-10.4 7.2-17.808z" fill="#4285F4"/>
          <path d="M24 48c6.48 0 11.904-2.136 15.872-5.784l-7.776-6.072c-2.16 1.464-4.92 2.328-8.096 2.328-6.24 0-11.52-4.224-13.416-9.888H2.616v6.24C6.576 42.696 14.76 48 24 48z" fill="#34A853"/>
          <path d="M10.584 28.584A14.4 14.4 0 0 1 9.6 24c0-1.584.288-3.12.768-4.584v-6.24H2.616A23.952 23.952 0 0 0 0 24c0 3.888.936 7.56 2.616 10.824l7.968-6.24z" fill="#FBBC05"/>
          <path d="M24 9.528c3.504 0 6.648 1.2 9.12 3.576l6.84-6.84C35.904 2.376 30.48 0 24 0 14.76 0 6.576 5.304 2.616 13.176l7.968 6.24C12.48 13.752 17.76 9.528 24 9.528z" fill="#EA4335"/>
        </svg>
      )}
      {disabled ? 'Signing in with Google…' : 'Continue with Google'}
    </button>
  )
}

/* ── Sign In Form ── */
function SignInForm({ onSwitchTab }) {
  const navigate = useNavigate()
  const { setUser, setToken, setAvatar } = useStore()
  const { signInWithGoogle, googleLoading } = useGoogleAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [demoLoading, setDemoLoading] = useState(false)

  const doLogin = async (loginEmail, loginPassword) => {
    const res = await api.post('/auth/login', { email: loginEmail, password: loginPassword })
    setAvatar(null)
    setToken(res.data.access_token)
    setUser(res.data.user)
    return res.data.user
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!email || !password) {
      toast.error('Please fill in all fields')
      return
    }
    setLoading(true)
    try {
      const user = await doLogin(email, password)
      toast.success(`Welcome back, ${user.name}!`)
      navigate('/dashboard')
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  const handleDemoLogin = async () => {
    setDemoLoading(true)
    try {
      const user = await doLogin(DEMO_EMAIL, DEMO_PASSWORD)
      toast.success(`Demo mode — welcome, ${user.name}!`)
      navigate('/dashboard')
    } catch {
      toast.error('Demo login failed — please try again')
    } finally {
      setDemoLoading(false)
    }
  }

  const inputCls = "w-full px-4 py-3 rounded-xl text-sm border focus:outline-none transition-colors"
  const inputStyle = {
    backgroundColor: '#f7f9fc',
    borderColor: '#bbcac5',
    color: '#191c1e',
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: '#3d4946' }}>
          Email Address
        </label>
        <input
          type="email"
          value={email}
          onChange={e => setEmail(e.target.value)}
          placeholder="you@example.com"
          className={inputCls}
          style={inputStyle}
        />
      </div>

      <div>
        <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: '#3d4946' }}>
          Password
        </label>
        <div className="relative">
          <input
            type={showPass ? 'text' : 'password'}
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="Enter your password"
            className={`${inputCls} pr-11`}
            style={inputStyle}
          />
          <button
            type="button"
            onClick={() => setShowPass(!showPass)}
            className="absolute right-3 top-1/2 -translate-y-1/2 transition-colors"
            style={{ color: '#8BA8C8' }}
          >
            {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
          </button>
        </div>
      </div>

      <button
        type="submit"
        disabled={loading || demoLoading}
        className="w-full py-3 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2"
        style={{
          backgroundColor: loading ? 'rgba(42,181,160,0.6)' : '#2AB5A0',
          color: '#ffffff',
          opacity: loading || demoLoading ? 0.8 : 1,
        }}
      >
        {loading ? 'Signing in...' : 'Sign in →'}
      </button>

      <div className="relative flex items-center gap-3">
        <div className="flex-1 h-px" style={{ backgroundColor: '#eceef1' }} />
        <span className="text-xs" style={{ color: '#8BA8C8' }}>or</span>
        <div className="flex-1 h-px" style={{ backgroundColor: '#eceef1' }} />
      </div>

      <GoogleButton onClick={signInWithGoogle} disabled={loading || demoLoading || googleLoading} />

      <button
        type="button"
        onClick={handleDemoLogin}
        disabled={loading || demoLoading}
        className="w-full py-3 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-2"
        style={{
          backgroundColor: 'transparent',
          border: '1px solid rgba(42,181,160,0.3)',
          color: '#2AB5A0',
          opacity: demoLoading ? 0.7 : 1,
        }}
      >
        <Zap size={15} />
        {demoLoading ? 'Loading demo...' : 'Try demo account'}
      </button>

      <p className="text-center text-sm" style={{ color: '#8BA8C8' }}>
        Don't have an account?{' '}
        <button
          type="button"
          onClick={onSwitchTab}
          className="font-semibold transition-colors"
          style={{ color: '#2AB5A0' }}
        >
          Sign up
        </button>
      </p>
    </form>
  )
}

/* ── Email Verification Screen ── */
function EmailVerificationScreen({ email, onSwitchTab }) {
  const navigate = useNavigate()
  const { setUser, setToken } = useStore()
  const [resending, setResending] = useState(false)
  const [resent, setResent] = useState(false)

  const handleResend = async () => {
    setResending(true)
    try {
      await api.post('/auth/resend-verification', { email })
      setResent(true)
      toast.success('Verification email resent!')
    } catch {
      toast.error('Could not resend email. Try again shortly.')
    } finally {
      setResending(false)
    }
  }

  const handleContinue = async () => {
    try {
      const res = await api.post('/auth/login-unverified', { email })
      if (res.data?.access_token) {
        setToken(res.data.access_token)
        setUser(res.data.user)
        navigate('/dashboard')
      }
    } catch {
      navigate('/dashboard')
    }
  }

  return (
    <div className="text-center space-y-5">
      <div
        className="w-16 h-16 rounded-2xl flex items-center justify-center mx-auto"
        style={{ backgroundColor: 'rgba(42,181,160,0.1)', border: '1px solid rgba(42,181,160,0.2)' }}
      >
        <Mail size={28} style={{ color: '#2AB5A0' }} />
      </div>
      <div>
        <h2 className="text-xl font-bold mb-2" style={{ color: '#191c1e' }}>Check your email</h2>
        <p className="text-sm" style={{ color: '#8BA8C8' }}>
          We sent a verification link to
        </p>
        <p className="text-sm font-semibold mt-1" style={{ color: '#191c1e' }}>{email}</p>
        <p className="text-xs mt-3" style={{ color: '#8BA8C8' }}>
          Click the link in the email to activate your account.
        </p>
      </div>

      <button
        type="button"
        onClick={handleResend}
        disabled={resending || resent}
        className="w-full py-3 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition-all"
        style={{
          backgroundColor: resent ? 'rgba(42,181,160,0.1)' : 'transparent',
          border: '1px solid rgba(42,181,160,0.3)',
          color: resent ? '#2AB5A0' : '#2AB5A0',
          opacity: resending ? 0.7 : 1,
        }}
      >
        {resending ? <><RefreshCw size={14} className="animate-spin" /> Resending...</> : resent ? <><Check size={14} /> Email resent</> : 'Resend verification email'}
      </button>

      <button
        type="button"
        onClick={handleContinue}
        className="w-full py-3 rounded-xl text-sm font-semibold transition-all"
        style={{ backgroundColor: '#2AB5A0', color: '#ffffff' }}
      >
        Continue to dashboard →
      </button>

      <p className="text-center text-sm" style={{ color: '#8BA8C8' }}>
        Already have an account?{' '}
        <button
          type="button"
          onClick={onSwitchTab}
          className="font-semibold"
          style={{ color: '#2AB5A0' }}
        >
          Sign in
        </button>
      </p>
    </div>
  )
}

/* ── Sign Up Form ── */
function SignUpForm({ onSwitchTab }) {
  const navigate = useNavigate()
  const { setUser, setToken, setAvatar } = useStore()
  const { signInWithGoogle, googleLoading } = useGoogleAuth()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [showPass, setShowPass] = useState(false)
  const [loading, setLoading] = useState(false)
  const [demoLoading, setDemoLoading] = useState(false)
  const [verifyEmail, setVerifyEmail] = useState(null)

  const doLogin = async (loginEmail, loginPassword) => {
    const res = await api.post('/auth/login', { email: loginEmail, password: loginPassword })
    setAvatar(null)
    setToken(res.data.access_token)
    setUser(res.data.user)
    return res.data.user
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name || !email || !password) {
      toast.error('Please fill in all fields')
      return
    }
    if (password !== confirm) {
      toast.error('Passwords do not match')
      return
    }
    if (password.length < 6) {
      toast.error('Password must be at least 6 characters')
      return
    }
    setLoading(true)
    try {
      const res = await api.post('/auth/register', { name, email, password, mode: 'earner' })
      if (res.data?.needs_verification || res.data?.email_sent) {
        setVerifyEmail(email)
      } else if (res.data?.access_token) {
        setAvatar(null)
        setToken(res.data.access_token)
        setUser(res.data.user)
        toast.success('Account created! Welcome to FinSense.')
        navigate('/dashboard')
      } else {
        setVerifyEmail(email)
      }
    } catch (err) {
      toast.error(err.response?.data?.detail || 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  const handleDemoLogin = async () => {
    setDemoLoading(true)
    try {
      const user = await doLogin(DEMO_EMAIL, DEMO_PASSWORD)
      toast.success(`Demo mode — welcome, ${user.name}!`)
      navigate('/dashboard')
    } catch {
      toast.error('Demo login failed — please try again')
    } finally {
      setDemoLoading(false)
    }
  }

  if (verifyEmail) {
    return <EmailVerificationScreen email={verifyEmail} onSwitchTab={onSwitchTab} />
  }

  const inputCls = "w-full px-4 py-3 rounded-xl text-sm border focus:outline-none transition-colors"
  const inputStyle = {
    backgroundColor: '#f7f9fc',
    borderColor: '#bbcac5',
    color: '#191c1e',
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3.5">
      <div>
        <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: '#3d4946' }}>
          Full Name
        </label>
        <input
          type="text"
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="Harish Kumar"
          className={inputCls}
          style={inputStyle}
        />
      </div>

      <div>
        <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: '#3d4946' }}>
          Email Address
        </label>
        <input
          type="email"
          value={email}
          onChange={e => setEmail(e.target.value)}
          placeholder="you@example.com"
          className={inputCls}
          style={inputStyle}
        />
      </div>

      <div>
        <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: '#3d4946' }}>
          Password
        </label>
        <div className="relative">
          <input
            type={showPass ? 'text' : 'password'}
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="Min 6 characters"
            className={`${inputCls} pr-11`}
            style={inputStyle}
          />
          <button
            type="button"
            onClick={() => setShowPass(!showPass)}
            className="absolute right-3 top-1/2 -translate-y-1/2 transition-colors"
            style={{ color: '#8BA8C8' }}
          >
            {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
          </button>
        </div>
      </div>

      <div>
        <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wider" style={{ color: '#3d4946' }}>
          Confirm Password
        </label>
        <input
          type="password"
          value={confirm}
          onChange={e => setConfirm(e.target.value)}
          placeholder="Repeat password"
          className={inputCls}
          style={inputStyle}
        />
      </div>

      <button
        type="submit"
        disabled={loading || demoLoading}
        className="w-full py-3 rounded-xl text-sm font-semibold transition-all"
        style={{
          backgroundColor: loading ? 'rgba(42,181,160,0.6)' : '#2AB5A0',
          color: '#ffffff',
          opacity: loading || demoLoading ? 0.8 : 1,
        }}
      >
        {loading ? 'Creating account...' : 'Create account →'}
      </button>

      <GoogleButton onClick={signInWithGoogle} disabled={loading || demoLoading || googleLoading} />

      <button
        type="button"
        onClick={handleDemoLogin}
        disabled={loading || demoLoading}
        className="w-full py-3 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-2"
        style={{
          backgroundColor: 'transparent',
          border: '1px solid rgba(42,181,160,0.3)',
          color: '#2AB5A0',
          opacity: demoLoading ? 0.7 : 1,
        }}
      >
        <Zap size={15} />
        {demoLoading ? 'Loading demo...' : 'Try demo account'}
      </button>

      <p className="text-center text-sm" style={{ color: '#8BA8C8' }}>
        Already have an account?{' '}
        <button
          type="button"
          onClick={onSwitchTab}
          className="font-semibold transition-colors"
          style={{ color: '#2AB5A0' }}
        >
          Sign in
        </button>
      </p>
    </form>
  )
}

/* ── AuthPage ── */
export default function AuthPage({ defaultTab = 'signin' }) {
  const [activeTab, setActiveTab] = useState(defaultTab)
  const navigate = useNavigate()
  const { setUser, setToken } = useStore()

  return (
    <div className="min-h-screen flex" style={{ backgroundColor: '#f7f9fc' }}>
      {/* Left dark panel */}
      <LeftPanel />

      {/* Right light panel */}
      <div className="flex-1 flex items-center justify-center p-8" style={{ backgroundColor: '#f7f9fc' }}>
        <div className="w-full max-w-md">
          {/* Card */}
          <div
            className="bg-white rounded-2xl p-8 border"
            style={{
              boxShadow: '0 4px 32px rgba(0,0,0,0.08)',
              borderColor: '#eceef1',
            }}
          >
            {/* Tab switcher */}
            <div
              className="flex p-1 rounded-xl mb-7"
              style={{ backgroundColor: '#eceef1' }}
            >
              {[
                { id: 'signin', label: 'Sign in' },
                { id: 'signup', label: 'Sign up' },
              ].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className="flex-1 py-2 rounded-lg text-sm font-semibold transition-all"
                  style={{
                    backgroundColor: activeTab === tab.id ? '#ffffff' : 'transparent',
                    color: activeTab === tab.id ? '#191c1e' : '#8BA8C8',
                    boxShadow: activeTab === tab.id ? '0 1px 4px rgba(0,0,0,0.08)' : 'none',
                  }}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Form heading */}
            <div className="mb-6">
              <h1
                className="text-2xl font-bold mb-1"
                style={{ fontFamily: 'var(--font-heading)', color: '#191c1e' }}
              >
                {activeTab === 'signin' ? 'Welcome back' : 'Create your account'}
              </h1>
              <p className="text-sm" style={{ color: '#8BA8C8' }}>
                {activeTab === 'signin'
                  ? 'Sign in to your FinSense account'
                  : 'Join FinSense for free and take control of your finances'}
              </p>
            </div>

            {/* Forms */}
            {activeTab === 'signin' ? (
              <SignInForm onSwitchTab={() => setActiveTab('signup')} />
            ) : (
              <SignUpForm onSwitchTab={() => setActiveTab('signin')} />
            )}
          </div>

          {/* Footer text */}
          <p className="text-center text-xs mt-6" style={{ color: '#8BA8C8' }}>
            By continuing, you agree to our Terms of Service and Privacy Policy
          </p>
        </div>
      </div>
    </div>
  )
}
