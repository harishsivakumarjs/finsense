import { useEffect, useRef } from 'react'
import { X } from 'lucide-react'

export default function Modal({ isOpen, onClose, title, children, size='md' }) {
  const backdropRef = useRef(null)

  useEffect(() => {
    const handleKeyDown = (e) => { if (e.key === 'Escape') onClose() }
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown)
      document.body.style.overflow = 'hidden'
    }
    return () => {
      document.removeEventListener('keydown', handleKeyDown)
      document.body.style.overflow = ''
    }
  }, [isOpen, onClose])

  const handleBackdropClick = (e) => { if (e.target === backdropRef.current) onClose() }

  const sizeClasses = { sm:'max-w-md', md:'max-w-lg', lg:'max-w-2xl', xl:'max-w-4xl' }

  if (!isOpen) return null

  return (
    <div ref={backdropRef} onClick={handleBackdropClick}
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      style={{ backgroundColor:'rgba(0,0,0,0.5)' }}>
      <div className={`w-full ${sizeClasses[size]}`}
        style={{
          backgroundColor:'var(--surface)',
          border:'1px solid var(--outline-variant)',
          maxHeight:'90vh', overflowY:'auto', borderRadius:16,
          boxShadow:'0 20px 60px rgba(0,0,0,0.15), 0 4px 16px rgba(0,0,0,0.08)',
        }}>
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4" style={{ borderBottom:'1px solid var(--outline-variant)' }}>
          <h2 className="text-base font-semibold" style={{ color:'var(--on-surface)' }}>{title}</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg transition-colors"
            style={{ color:'var(--on-surface-variant)' }}
            onMouseEnter={e => e.currentTarget.style.backgroundColor='var(--surface-container-low)'}
            onMouseLeave={e => e.currentTarget.style.backgroundColor='transparent'}>
            <X size={18} />
          </button>
        </div>
        {/* Content */}
        <div className="p-6">{children}</div>
      </div>
    </div>
  )
}
