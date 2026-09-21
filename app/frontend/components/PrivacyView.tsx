// app/frontend/components/PrivacyView.tsx

import { useEffect, useState } from "react"

import ThemeIcon from "./ThemeIcon"

type PrivacyViewProps = {
  endpoint: string
  initialEnabled: boolean
}

function publish(enabled: boolean) {
  document.documentElement.dataset.privacyView = enabled ? "on" : "off"
}

export default function PrivacyView({ initialEnabled, endpoint }: PrivacyViewProps) {
  const [enabled, setEnabled] = useState(initialEnabled)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(false)

  useEffect(() => publish(initialEnabled), [initialEnabled])

  function apply(value: boolean) {
    setEnabled(value)
    publish(value)
  }

  async function toggle() {
    const next = !enabled
    apply(next)
    setSaving(true)
    setError(false)

    try {
      const response = await fetch(endpoint, {
        body: JSON.stringify({ enabled: next }),
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
        },
        method: "PATCH"
      })
      if (!response.ok) throw new Error("Privacy View preference rejected")
    } catch {
      apply(true)
      setError(true)
    } finally {
      setSaving(false)
    }
  }

  return <div className="privacy-view-control">
    <button
      aria-checked={enabled}
      aria-describedby="privacy-view-scope"
      aria-label={`Privacy View ${enabled ? "On" : "Off"}`}
      disabled={saving}
      onClick={() => void toggle()}
      role="switch"
      type="button"
    >
      <ThemeIcon name="privacy_view" />
      <span>Privacy View</span>
      <span aria-hidden="true" className="privacy-view-switch"><span /></span>
      <strong>{enabled ? "On" : "Off"}</strong>
    </button>
    <span className="sr-only" id="privacy-view-scope">
      Conceals marked commercially sensitive values for presentation. It does not change authorization or remove delivered data.
    </span>
    {error && <p role="alert">Privacy View could not be saved. Concealment stays on here; reloading may restore the previous session setting.</p>}
  </div>
}
