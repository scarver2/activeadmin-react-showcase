// app/frontend/components/PrivacyMode.tsx

import { EyeSlashIcon } from "@heroicons/react/24/outline"
import { useState } from "react"

export const privacyEvent = "showcase:privacy-mode"

export default function PrivacyMode({ initialEnabled, endpoint }: { initialEnabled: boolean; endpoint: string }) {
  const [enabled, setEnabled] = useState(initialEnabled)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(false)

  function apply(value: boolean) {
    setEnabled(value)
    document.dispatchEvent(new CustomEvent(privacyEvent, { detail: value }))
  }

  async function toggle() {
    const previous = enabled
    apply(!previous)
    setSaving(true)
    setError(false)
    try {
      const response = await fetch(endpoint, {
        body: JSON.stringify({ enabled: !previous }),
        credentials: "same-origin",
        headers: { "Accept": "application/json", "Content-Type": "application/json", "X-CSRF-Token": document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" },
        method: "PATCH"
      })
      if (!response.ok) throw new Error("Privacy preference rejected")
    } catch {
      apply(true)
      setError(true)
    } finally {
      setSaving(false)
    }
  }

  return <div className="workspace-privacy">
    <button aria-describedby="privacy-scope" aria-pressed={enabled} disabled={saving} onClick={() => void toggle()} type="button">
      <EyeSlashIcon aria-hidden="true" /><span>Privacy Mode <strong>{enabled ? "On" : "Off"}</strong></span>
    </button>
    <span className="sr-only" id="privacy-scope">Masks designated home dashboard totals only. Not authorization; underlying page data remains available.</span>
    {error && <p role="alert">Privacy preference could not be saved. Masking stays on here; reloading may restore the previous session setting.</p>}
  </div>
}
