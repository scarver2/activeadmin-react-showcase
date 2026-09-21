// app/frontend/components/CommandPalette.tsx

import { FormEvent, KeyboardEvent, useCallback, useEffect, useRef, useState } from "react"
import { createPortal } from "react-dom"

import ThemeIcon from "./ThemeIcon"

export type CommandPaletteProps = {
  compact?: boolean
  endpoint: string
  initialQuery?: string
}

type SearchResult = {
  description: string
  id: string
  kind: "Account" | "Article" | "Page"
  label: string
  url: string
}

type SearchPayload = {
  error?: string
  query?: string
  results?: SearchResult[]
}

export default function CommandPalette({ compact = false, endpoint, initialQuery = "" }: CommandPaletteProps) {
  const requestId = useRef(0)
  const input = useRef<HTMLInputElement>(null)
  const resultLinks = useRef<Array<HTMLAnchorElement | null>>([])
  const trigger = useRef<HTMLButtonElement>(null)
  const wasOpen = useRef(false)
  const [activeIndex, setActiveIndex] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState(initialQuery)
  const [results, setResults] = useState<SearchResult[]>([])
  const [searched, setSearched] = useState(false)

  const search = useCallback(async (value: string) => {
    const id = ++requestId.current
    const normalized = value.trim()
    if (!normalized) {
      setError(null)
      setResults([])
      setSearched(false)
      return
    }

    setError(null)
    setLoading(true)
    try {
      const response = await fetch(`${endpoint}?query=${encodeURIComponent(normalized)}`, {
        credentials: "same-origin",
        headers: { Accept: "application/json" }
      })
      const payload = await response.json() as SearchPayload
      if (id !== requestId.current) return
      if (!response.ok) throw new Error(payload.error || "Search could not be completed.")

      setActiveIndex(0)
      setResults(payload.results || [])
      setSearched(true)
    } catch (reason) {
      if (id !== requestId.current) return
      setError(reason instanceof Error ? reason.message : "Search could not be completed.")
      setResults([])
      setSearched(false)
    } finally {
      if (id === requestId.current) setLoading(false)
    }
  }, [endpoint])

  useEffect(() => {
    function openFromShortcut(event: globalThis.KeyboardEvent) {
      if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
        event.preventDefault()
        setOpen(true)
      }
    }

    document.addEventListener("keydown", openFromShortcut)
    return () => document.removeEventListener("keydown", openFromShortcut)
  }, [])

  useEffect(() => {
    if (open) {
      wasOpen.current = true
      input.current?.focus()
    } else if (wasOpen.current) {
      wasOpen.current = false
      trigger.current?.focus()
    }
  }, [open])

  function handleInputKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === "Escape") {
      event.preventDefault()
      setOpen(false)
    } else if (event.key === "ArrowDown" && results.length > 0) {
      event.preventDefault()
      setActiveIndex((current) => (current + 1) % results.length)
    } else if (event.key === "ArrowUp" && results.length > 0) {
      event.preventDefault()
      setActiveIndex((current) => (current - 1 + results.length) % results.length)
    } else if (event.key === "Enter" && results[activeIndex]) {
      event.preventDefault()
      resultLinks.current[activeIndex]?.click()
    }
  }

  function changeQuery(value: string) {
    requestId.current += 1
    setLoading(false)
    setActiveIndex(0)
    setError(null)
    setQuery(value)
    setResults([])
    setSearched(false)
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    void search(query)
  }

  return (
    <section aria-label="Global search" className={compact ? "workspace-global-search" : "command-palette-demo"} data-testid="command-palette">
      {!compact && <><h2 className="text-2xl font-bold">Authorized global search</h2>
      <p>Search Rails-owned showcase pages and records from a keyboard-friendly palette.</p></>}
      <button className="command-palette-trigger" onClick={() => setOpen(true)} ref={trigger} type="button">
        <ThemeIcon name="search" />{compact ? "Search Showcase" : "Open global search"} <kbd>⌘/Ctrl K</kbd>
      </button>

      {open && createPortal(
        <div className="command-palette-backdrop" data-testid="command-palette-backdrop" onMouseDown={(event) => {
          if (event.target === event.currentTarget) setOpen(false)
        }}>
          <section aria-labelledby="command-palette-dialog-title" aria-modal="true" className="command-palette-dialog" role="dialog" onKeyDown={event => {
            if (event.key === "Escape") { event.preventDefault(); setOpen(false) }
            if (event.key !== "Tab") return
            const controls = Array.from(event.currentTarget.querySelectorAll<HTMLElement>('button:not(:disabled), input, a[href]'))
            const first = controls[0]
            const last = controls[controls.length - 1]
            if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last?.focus() }
            else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first?.focus() }
          }}>
            <div className="command-palette-header">
              <h3 id="command-palette-dialog-title">Search Showcase</h3>
              <button aria-label="Close command palette" className="command-palette-close" onClick={() => setOpen(false)} type="button">×</button>
            </div>
            <form onSubmit={submit} role="search">
              <label className="sr-only" htmlFor="command-palette-query">Search pages, accounts and articles</label>
              <div className="command-palette-search-row">
                <input
                  aria-activedescendant={results[activeIndex] ? `command-result-${results[activeIndex].id}` : undefined}
                  aria-autocomplete="list"
                  aria-controls="command-palette-results"
                  aria-expanded={results.length > 0}
                  autoComplete="off"
                  id="command-palette-query"
                  maxLength={80}
                  onChange={(event) => changeQuery(event.target.value)}
                  onKeyDown={handleInputKeyDown}
                  placeholder="Search pages, accounts and articles"
                  ref={input}
                  role="combobox"
                  value={query}
                />
                <button disabled={loading} type="submit">{loading ? "Searching…" : "Search"}</button>
              </div>
            </form>

            {error && <div className="command-palette-message command-palette-error" role="alert"><p>{error}</p><button onClick={() => void search(query)} type="button">Try again</button></div>}
            {!error && !loading && !searched && <p className="command-palette-message">Enter a term to search authorized records.</p>}
            {!error && !loading && searched && results.length === 0 && <p className="command-palette-message" data-testid="command-palette-empty">No searchable records match “{query.trim()}”.</p>}
            {loading && <p aria-live="polite" className="command-palette-message" role="status">Searching authorized records…</p>}
            {!error && results.length > 0 && (
              <ul aria-label="Search results" className="command-palette-results" id="command-palette-results" role="listbox">
                {results.map((result, index) => (
                  <li aria-selected={activeIndex === index} id={`command-result-${result.id}`} key={result.id} role="option">
                    <a className={activeIndex === index ? "is-active" : ""} href={result.url} ref={(element) => { resultLinks.current[index] = element }}>
                      <span><strong>{result.label}</strong><small>{result.kind}</small></span>
                      <span>{result.description}</span>
                    </a>
                  </li>
                ))}
              </ul>
            )}
            <p className="command-palette-help">Use ↑/↓ to select, Enter to navigate, and Escape to close.</p>
          </section>
        </div>, document.body
      )}
    </section>
  )
}
