// app/frontend/components/InlineFieldEditor.tsx

import { KeyboardEvent, useEffect, useRef, useState } from "react"

type Props = { endpoint: string, field: "region" | "status", label: string, lockVersion: number, options: string[], value: string }
type AccountPayload = { id: number, lockVersion: number, region: string, status: string }

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

export default function InlineFieldEditor({ endpoint, field, label, lockVersion: initialLock, options, value: initialValue }: Props) {
  const [value, setValue] = useState(initialValue)
  const [draft, setDraft] = useState(initialValue)
  const [lockVersion, setLockVersion] = useState(initialLock)
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const buttonRef = useRef<HTMLButtonElement>(null)
  const selectRef = useRef<HTMLSelectElement>(null)

  useEffect(() => { if (editing) selectRef.current?.focus() }, [editing])

  function restoreFocus() {
    setEditing(false)
    window.requestAnimationFrame(() => buttonRef.current?.focus())
  }

  function cancel() {
    setDraft(value)
    setError(null)
    restoreFocus()
  }

  async function save() {
    const previous = value
    setValue(draft)
    setSaving(true)
    setError(null)
    try {
      const response = await fetch(endpoint, {
        method: "PATCH", credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ field, lock_version: lockVersion, value: draft })
      })
      const payload = await response.json()
      if (!response.ok) {
        const canonical = payload.account as AccountPayload | undefined
        if (canonical) { setValue(canonical[field]); setDraft(canonical[field]); setLockVersion(canonical.lockVersion) }
        else { setValue(previous); setDraft(previous) }
        throw new Error(payload.error || "Inline update failed")
      }
      const account = payload as AccountPayload
      setValue(account[field])
      setDraft(account[field])
      setLockVersion(account.lockVersion)
      restoreFocus()
    } catch (requestError) {
      if (!(requestError instanceof Error && requestError.message.includes("changed elsewhere"))) {
        setValue(previous)
        setDraft(previous)
      }
      setError((requestError as Error).message)
      restoreFocus()
    } finally {
      setSaving(false)
    }
  }

  function keyboard(event: KeyboardEvent<HTMLSelectElement>) {
    if (event.key === "Escape") { event.preventDefault(); cancel() }
    if (event.key === "Enter") { event.preventDefault(); void save() }
  }

  return <div className="inline-field-editor">
    {!editing && <button aria-label={`Edit ${label}`} className="rounded border px-3 py-1" onClick={() => setEditing(true)} ref={buttonRef} type="button">{value}</button>}
    {editing && <span className="inline-flex items-center gap-2">
      <select aria-label={label} disabled={saving} onBlur={() => { if (!saving) cancel() }} onChange={(event) => setDraft(event.target.value)} onKeyDown={keyboard} ref={selectRef} value={draft}>
        {options.map((option) => <option key={option}>{option}</option>)}
      </select>
      <button disabled={saving} onMouseDown={(event) => event.preventDefault()} onClick={() => void save()} type="button">Save</button>
      <button disabled={saving} onMouseDown={(event) => event.preventDefault()} onClick={cancel} type="button">Cancel</button>
    </span>}
    {saving && <span aria-live="polite"> Saving…</span>}
    {error && <span className="ml-2 text-red-700" role="alert">{error}</span>}
  </div>
}
