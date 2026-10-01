// app/frontend/components/ContextualInspector.tsx

import { type ReactNode, type RefObject, useEffect, useRef } from "react"

type ContextualInspectorProps = {
  children: ReactNode
  error: string | null
  errorActionHref: string
  errorActionLabel: string
  eyebrow: string
  loading: boolean
  onClose: () => void
  returnFocus: RefObject<HTMLElement | null>
  title: string
}

const focusableSelector = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  '[tabindex]:not([tabindex="-1"])'
].join(",")

export default function ContextualInspector({ children, error, errorActionHref, errorActionLabel, eyebrow, loading, onClose, returnFocus, title }: ContextualInspectorProps) {
  const closeButton = useRef<HTMLButtonElement>(null)
  const dialog = useRef<HTMLElement>(null)

  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
    closeButton.current?.focus()

    return () => {
      document.body.style.overflow = previousOverflow
      window.requestAnimationFrame(() => {
        if (returnFocus.current?.isConnected) returnFocus.current.focus()
      })
    }
  }, [returnFocus])

  function handleKeyDown(event: React.KeyboardEvent<HTMLElement>) {
    if (event.key === "Escape") {
      event.preventDefault()
      onClose()
      return
    }
    if (event.key !== "Tab") return

    const focusable = Array.from(dialog.current!.querySelectorAll<HTMLElement>(focusableSelector))
    /* v8 ignore next -- the always-rendered close button guarantees one focusable control. */
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  return (
    <div className="contextual-inspector-backdrop" data-testid="contextual-inspector-backdrop">
      <section
        aria-labelledby="contextual-inspector-title"
        aria-modal="true"
        className="contextual-inspector showcase-themed-island"
        data-testid="contextual-inspector"
        onKeyDown={handleKeyDown}
        ref={dialog}
        role="dialog"
      >
        <header className="contextual-inspector-header">
          <div>
            <p className="contextual-inspector-eyebrow">{eyebrow}</p>
            <h2 id="contextual-inspector-title">{title}</h2>
          </div>
          <button aria-label="Close account inspector" className="contextual-inspector-close" onClick={onClose} ref={closeButton} type="button">×</button>
        </header>

        <div className="contextual-inspector-body">
          {loading && <p aria-live="polite" role="status">Loading account context…</p>}
          {error && <div className="contextual-inspector-error" role="alert"><p>{error}</p><a href={errorActionHref}>{errorActionLabel}</a></div>}
          {children && !loading && !error && children}
        </div>
      </section>
    </div>
  )
}
