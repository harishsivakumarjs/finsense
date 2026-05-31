import { useEffect, useState } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { CheckCircle2, XCircle, Loader2 } from 'lucide-react'
import api from '../api/axios'

export default function VerifyEmail() {
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const [status, setStatus] = useState('loading') // loading | success | error
  const [message, setMessage] = useState('')
  const token = params.get('token')

  useEffect(() => {
    if (!token) {
      setStatus('error')
      setMessage('This verification link is invalid or incomplete.')
      return
    }
    api.get(`/auth/verify-email?token=${encodeURIComponent(token)}`)
      .then(res => {
        setStatus('success')
        setMessage(res.data?.message || 'Email verified successfully!')
      })
      .catch(err => {
        setStatus('error')
        setMessage(err.response?.data?.detail || 'Verification failed. The link may be expired or already used.')
      })
  }, [token])

  const card = {
    background: '#ffffff',
    borderRadius: 20,
    padding: '40px 32px',
    border: '1px solid #eceef1',
    boxShadow: '0 4px 32px rgba(0,0,0,0.08)',
    textAlign: 'center',
    maxWidth: 440,
    width: '100%',
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  backgroundColor: '#f7f9fc', padding: 24 }}>
      <div style={card}>
        {/* Logo */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, marginBottom: 32 }}>
          <div style={{ width: 36, height: 36, borderRadius: 10, backgroundColor: '#2AB5A0',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontWeight: 800, fontSize: 16, color: '#fff' }}>F</div>
          <span style={{ fontSize: 18, fontWeight: 700, color: '#191c1e' }}>FinSense</span>
        </div>

        {status === 'loading' && (
          <>
            <Loader2 size={44} className="animate-spin" style={{ color: '#2AB5A0', margin: '0 auto 16px' }} />
            <h2 style={{ fontSize: 20, fontWeight: 700, color: '#191c1e', margin: '0 0 8px' }}>
              Verifying your email…
            </h2>
            <p style={{ color: '#8BA8C8', fontSize: 14, margin: 0 }}>Please wait a moment.</p>
          </>
        )}

        {status === 'success' && (
          <>
            <CheckCircle2 size={52} style={{ color: '#2AB5A0', margin: '0 auto 16px', display: 'block' }} />
            <h2 style={{ fontSize: 22, fontWeight: 700, color: '#191c1e', margin: '0 0 8px' }}>
              Email Verified!
            </h2>
            <p style={{ color: '#8BA8C8', fontSize: 14, margin: '0 0 28px', lineHeight: 1.6 }}>
              {message}
            </p>
            <button onClick={() => navigate('/login')}
              style={{ width: '100%', padding: '14px 0', borderRadius: 12, border: 'none', cursor: 'pointer',
                       backgroundColor: '#2AB5A0', color: '#ffffff', fontSize: 14, fontWeight: 600 }}>
              Sign In to FinSense →
            </button>
          </>
        )}

        {status === 'error' && (
          <>
            <XCircle size={52} style={{ color: '#ba1a1a', margin: '0 auto 16px', display: 'block' }} />
            <h2 style={{ fontSize: 22, fontWeight: 700, color: '#191c1e', margin: '0 0 8px' }}>
              Verification Failed
            </h2>
            <p style={{ color: '#8BA8C8', fontSize: 14, margin: '0 0 12px', lineHeight: 1.6 }}>
              {message}
            </p>
            <p style={{ color: '#8BA8C8', fontSize: 13, margin: '0 0 24px' }}>
              Go to Sign In and use "Resend verification email" to get a fresh link.
            </p>
            <button onClick={() => navigate('/login')}
              style={{ width: '100%', padding: '14px 0', borderRadius: 12, border: 'none', cursor: 'pointer',
                       backgroundColor: '#2AB5A0', color: '#ffffff', fontSize: 14, fontWeight: 600 }}>
              Go to Sign In
            </button>
          </>
        )}
      </div>
    </div>
  )
}
