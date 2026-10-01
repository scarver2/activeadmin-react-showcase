// app/frontend/components/BulkProgress.tsx

import { useEffect, useState } from "react"

type Snapshot = { state: string; progress: number; results: Record<string, string> }
type Props = { endpoint: string; initial: Snapshot }

export default function BulkProgress({ endpoint, initial }: Props) {
  const [snapshot, setSnapshot] = useState(initial)
  const [error, setError] = useState(false)
  useEffect(() => {
    if (!["queued", "running"].includes(snapshot.state)) return
    let active = true
    const timer = window.setTimeout(async () => {
      try {
        const response = await fetch(endpoint, { credentials: "same-origin", headers: { Accept: "application/json" } })
        if (!response.ok) throw new Error("Progress unavailable")
        const value = await response.json() as Snapshot
        if (active) { setSnapshot(value); setError(false) }
      } catch {
        if (active) setError(true)
      }
    }, 1000)
    return () => { active = false; window.clearTimeout(timer) }
  }, [endpoint, snapshot])
  return <section aria-label="Durable bulk progress">
    <p role="status">{snapshot.state}: {snapshot.progress}%</p>
    <progress aria-label="Processed records" max={100} value={snapshot.progress} />
    <ul>{Object.entries(snapshot.results).map(([id, result]) => <li key={id}>Account {id}: {result}</li>)}</ul>
    {error && <p role="alert">Progress could not be refreshed. <button type="button" onClick={() => setSnapshot({ ...snapshot })}>Retry progress</button> or use Refresh canonical results.</p>}
  </section>
}
