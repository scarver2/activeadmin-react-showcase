// app/frontend/components/ContextualInspector.tsx

import { type ReactNode, type RefObject, useEffect, useRef } from "react"

type ContextualInspectorProps = {
  canonicalHref: string
  children: ReactNode
  error: string | null
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

export default function ContextualInspector({ canonicalHref, children, error, eyebrow, loading, onClose, returnFocus, title }: ContextualInspectorProps) {
  const closeButton = useRef<HTMLButtonElement>(null)
  const dialog = useRef<HTMLElement>(null)

  useEffect(() => {
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
    closeButton.current?.focus()

    return () => {
      document.body.style.overflow = previousOverflow
      returnFocus.current?.focus()
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
    <div className="fixed inset-0 z-50 bg-slate-950/45" data-testid="contextual-inspector-backdrop">
      <section
        aria-labelledby="contextual-inspector-title"
        aria-modal="true"
        className="showcase-themed-island fixed inset-y-0 right-0 flex w-full flex-col border-l border-[var(--aat-border)] bg-[var(--aat-surface)] text-[var(--aat-text)] shadow-2xl sm:max-w-md"
        data-testid="contextual-inspector"
        onKeyDown={handleKeyDown}
        ref={dialog}
        role="dialog"
      >
        <header className="flex items-start justify-between gap-4 border-b border-[var(--aat-border)] p-5">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-[var(--aat-muted)]">{eyebrow}</p>
            <h2 className="mt-1 text-2xl font-bold" id="contextual-inspector-title">{title}</h2>
          </div>
          <button aria-label="Close account inspector" className="min-h-11 min-w-11 rounded border border-[var(--aat-border)] text-xl" onClick={onClose} ref={closeButton} type="button">×</button>
        </header>

        <div className="flex-1 overflow-y-auto p-5">
          {loading && <p aria-live="polite" role="status">Loading account context…</p>}
          {error && <div className="rounded border border-[var(--aat-danger)] bg-[var(--aat-danger-bg)] p-4" role="alert"><p>{error}</p><a className="mt-3 inline-block font-semibold underline" href={canonicalHref}>Open the canonical account page</a></div>}
          {children && !loading && !error && children}
        </div>
      </section>
    </div>
  )
}
