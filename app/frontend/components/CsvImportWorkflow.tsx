// app/frontend/components/CsvImportWorkflow.tsx

import { createConsumer } from "@rails/actioncable"
import { FormEvent, useEffect, useRef, useState } from "react"

type Preview = { headers: string[], rows: Record<string, string>[], rowCount: number }
export type CsvImportState = {
  token: string, status: string, rowCount: number, processedRows: number, importedRows: number,
  failedRows: number, mappings: Record<string, string>, errors: string[], preview?: Preview
}
type Props = { createUrl: string, initialImport: CsvImportState | null }
type Envelope = { type: "progress", import: CsvImportState }
const fields = ["first_name", "last_name", "email", "account"]

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

export default function CsvImportWorkflow({ createUrl, initialImport }: Props) {
  const [csvImport, setCsvImport] = useState(initialImport)
  const [mappings, setMappings] = useState<Record<string, string>>(initialImport?.mappings || {})
  const [pending, setPending] = useState(false)
  const [connection, setConnection] = useState("idle")
  const [error, setError] = useState<string | null>(null)
  const consumer = useRef(createConsumer())

  useEffect(() => {
    if (!csvImport || csvImport.status === "draft") return
    const subscription = consumer.current.subscriptions.create(
      { channel: "CsvImportChannel", token: csvImport.token },
      {
        connected: () => setConnection("connected"),
        disconnected: () => setConnection("disconnected"),
        rejected: () => setError("Progress stream was not authorized"),
        received: (envelope: Envelope) => setCsvImport(envelope.import)
      }
    )
    return () => { subscription.unsubscribe(); consumer.current.disconnect() }
  }, [csvImport?.token, csvImport?.status === "draft"])

  async function upload(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setPending(true)
    setError(null)
    try {
      const response = await fetch(createUrl, {
        method: "POST", credentials: "same-origin", headers: { Accept: "application/json", "X-CSRF-Token": csrfToken() },
        body: new FormData(event.currentTarget)
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "CSV upload failed")
      setCsvImport(payload)
      setMappings(payload.mappings)
      window.history.replaceState({}, "", `${window.location.pathname}?token=${payload.token}`)
    } catch (requestError) {
      setError((requestError as Error).message)
    } finally {
      setPending(false)
    }
  }

  async function confirmImport() {
    if (!csvImport || !window.confirm(`Import ${csvImport.rowCount} synthetic rows?`)) return
    setPending(true)
    setError(null)
    try {
      const response = await fetch(`${createUrl}/${csvImport.token}/confirm`, {
        method: "POST", credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ mappings })
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Import confirmation failed")
      setCsvImport(payload)
    } catch (requestError) {
      setError((requestError as Error).message)
    } finally {
      setPending(false)
    }
  }

  return <section className="space-y-5" data-testid="csv-import-workflow">
    <form className="space-y-3 rounded border bg-white p-5 dark:bg-gray-800" encType="multipart/form-data" onSubmit={upload}>
      <label className="block font-semibold" htmlFor="csv-source">Synthetic CSV file</label>
      <input accept=".csv,text/csv" id="csv-source" name="source" required type="file" />
      <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pending} type="submit">Upload and preview</button>
    </form>
    {error && <p className="text-red-700" role="alert">{error}</p>}
    {csvImport?.preview && <section className="space-y-3 rounded border p-4">
      <h3 className="font-semibold">Preview {csvImport.preview.rowCount} rows</h3>
      <div className="grid gap-2 md:grid-cols-2">{csvImport.preview.headers.map((header) => <label key={header}>{header}
        <select aria-label={`Map ${header}`} onChange={(event) => setMappings((current) => ({ ...current, [header]: event.target.value }))} value={mappings[header] || ""}>
          <option value="">Ignore</option>{fields.map((field) => <option key={field} value={field}>{field}</option>)}
        </select>
      </label>)}</div>
      <table><thead><tr>{csvImport.preview.headers.map((header) => <th key={header}>{header}</th>)}</tr></thead>
        <tbody>{csvImport.preview.rows.map((row, index) => <tr key={index}>{csvImport.preview!.headers.map((header) => <td key={header}>{row[header]}</td>)}</tr>)}</tbody></table>
      <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pending} onClick={() => void confirmImport()} type="button">Confirm import</button>
    </section>}
    {csvImport && csvImport.status !== "draft" && <section aria-live="polite" className="rounded border p-4">
      <h3 className="font-semibold">Import {csvImport.status}</h3>
      <progress max={csvImport.rowCount || 1} value={csvImport.processedRows} />
      <p>{csvImport.processedRows}/{csvImport.rowCount} processed · {csvImport.importedRows} imported · {csvImport.failedRows} failed</p>
      <p>Cable: <span data-testid="csv-cable-status">{connection}</span></p>
      {csvImport.errors.length > 0 && <ul aria-label="Row errors">{csvImport.errors.map((message, index) => <li key={index}>{message}</li>)}</ul>}
    </section>}
  </section>
}
