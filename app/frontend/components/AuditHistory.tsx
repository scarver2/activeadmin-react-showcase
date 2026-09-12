// app/frontend/components/AuditHistory.tsx

import { useMemo, useState } from "react"

type Change = { from: unknown, to: unknown }
type Version = { actor: string, at: string, changes: Record<string, Change>, event: string, id: number }
export type AuditHistoryProps = { history: Version[], name: string, previewUrl: string }

function display(value: unknown) { return typeof value === "string" ? value : JSON.stringify(value, null, 2) }

export default function AuditHistory({ history, name, previewUrl }: AuditHistoryProps) {
  const fields = useMemo(() => [...new Set(history.flatMap((version) => Object.keys(version.changes)))], [history])
  const [field, setField] = useState("all")
  const [preview, setPreview] = useState<Record<string, unknown> | null>(null)
  const [error, setError] = useState<string | null>(null)
  const visible = history.filter((version) => field === "all" || field in version.changes)

  async function loadPreview(versionId: number) {
    setError(null); setPreview(null)
    try {
      const response = await fetch(`${previewUrl}?version_id=${versionId}`, { credentials: "same-origin", headers: { Accept: "application/json" } })
      const payload = await response.json() as { error?: string, preview?: Record<string, unknown> }
      if (!response.ok || !payload.preview) throw new Error(payload.error || "Preview could not be loaded")
      setPreview(payload.preview)
    } catch (loadError) { setError((loadError as Error).message) }
  }

  return <section className="space-y-5" data-testid="audit-history">
    <h2 className="text-xl font-semibold">History for {name}</h2>
    <label>Changed field<select className="ml-2 rounded border p-2" value={field} onChange={(event) => setField(event.target.value)}><option value="all">All fields</option>{fields.map((item) => <option key={item}>{item}</option>)}</select></label>
    {error && <p role="alert" className="text-red-700">{error}</p>}
    {visible.length === 0 ? <p>No matching history.</p> : <ol className="space-y-3">{visible.map((version) => <li className="rounded border p-4" key={version.id}><h3 className="font-semibold">{version.event} by {version.actor}</h3><time dateTime={version.at}>{new Date(version.at).toLocaleString()}</time><table className="mt-2 w-full"><thead><tr><th>Field</th><th>Before</th><th>After</th></tr></thead><tbody>{Object.entries(version.changes).map(([key, change]) => <tr key={key}><th>{key}</th><td><pre>{display(change.from)}</pre></td><td><pre>{display(change.to)}</pre></td></tr>)}</tbody></table><button className="mt-2 rounded border px-3 py-2" onClick={() => void loadPreview(version.id)} type="button">Preview restoration from this version</button></li>)}</ol>}
    {preview && <section aria-live="polite" className="rounded border p-4"><h3 className="font-semibold">Restoration preview (no changes applied)</h3><pre>{JSON.stringify(preview, null, 2)}</pre></section>}
  </section>
}
