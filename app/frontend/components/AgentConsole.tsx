// app/frontend/components/AgentConsole.tsx

import { createConsumer } from "@rails/actioncable"
import { useEffect, useRef, useState } from "react"

type AgentEvent = {
  run_id: string
  sequence: number
  kind: "status" | "response" | "citation" | "result"
  content: string
  progress: number
  metadata: { label?: string, url?: string, sources?: number }
  occurred_at: string
}

type AgentRun = {
  id: string
  prompt: string
  state: string
  progress: number
  summary: string | null
  events: AgentEvent[]
  showUrl: string
  cancelUrl: string
}

type Props = { createUrl: string, runs: AgentRun[] }
type Subscription = { perform(action: string, data?: object): void, unsubscribe(): void }

const terminalStates = ["completed", "cancelled"]

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

export default function AgentConsole({ createUrl, runs: initialRuns }: Props) {
  const [runs, setRuns] = useState(initialRuns)
  const [prompt, setPrompt] = useState("Which synthetic accounts need attention?")
  const [connection, setConnection] = useState("connecting")
  const [error, setError] = useState<string | null>(null)
  const [pending, setPending] = useState(false)
  const consumerRef = useRef(createConsumer())
  const subscriptionsRef = useRef(new Map<string, Subscription>())

  useEffect(() => {
    const subscriptions = subscriptionsRef.current
    runs.forEach((run) => {
      if (terminalStates.includes(run.state) || subscriptions.has(run.id)) return

      const subscription = consumerRef.current.subscriptions.create(
        { channel: "AgentRunsChannel", run_id: run.id },
        {
          connected() {
            setConnection("connected")
            const afterSequence = run.events.at(-1)?.sequence || 0
            subscription.perform("resume", { after_sequence: afterSequence })
          },
          disconnected() { setConnection("disconnected") },
          rejected() { setError("Cable subscription was not authorized") },
          received(event: AgentEvent) {
            setRuns((existing) => existing.map((candidate) => {
              if (candidate.id !== event.run_id || candidate.events.some(({ sequence }) => sequence === event.sequence)) return candidate

              const state = event.kind === "result" ? "completed" : event.content === "Agent run cancelled" ? "cancelled" : "running"
              return {
                ...candidate,
                events: [...candidate.events, event].sort((left, right) => left.sequence - right.sequence),
                progress: event.progress,
                state,
                summary: event.kind === "result" ? event.content : candidate.summary
              }
            }))
          }
        }
      ) as Subscription
      subscriptions.set(run.id, subscription)
    })
  }, [runs])

  useEffect(() => () => {
    subscriptionsRef.current.forEach((subscription) => subscription.unsubscribe())
    consumerRef.current.disconnect()
  }, [])

  async function createRun(event: React.FormEvent) {
    event.preventDefault()
    setPending(true)
    setError(null)
    try {
      const response = await fetch(createUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ prompt })
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Agent run could not be created")
      setRuns((existing) => [payload, ...existing])
    } catch (requestError) {
      setError((requestError as Error).message)
    } finally {
      setPending(false)
    }
  }

  async function cancel(run: AgentRun) {
    const response = await fetch(run.cancelUrl, {
      method: "POST",
      credentials: "same-origin",
      headers: { Accept: "application/json", "X-CSRF-Token": csrfToken() }
    })
    if (!response.ok) setError("Agent run could not be cancelled")
  }

  function reconnect() {
    setConnection("disconnected")
    consumerRef.current.disconnect()
    window.setTimeout(() => consumerRef.current.connect(), 750)
  }

  return (
    <section className="space-y-6" data-testid="agent-console">
      <form className="rounded-lg border bg-white p-5 dark:bg-gray-800" onSubmit={createRun}>
        <label className="block font-semibold" htmlFor="agent-prompt">Prompt</label>
        <div className="mt-2 flex flex-wrap gap-2">
          <input className="min-w-72 flex-1 rounded border px-3 py-2" id="agent-prompt" maxLength={500} onChange={(event) => setPrompt(event.target.value)} required value={prompt} />
          <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pending} type="submit">Run demo agent</button>
          <button className="rounded border px-4 py-2" data-testid="agent-reconnect" onClick={reconnect} type="button">Reconnect Cable</button>
        </div>
        <p className="mt-2 text-sm">Cable: <span data-testid="agent-cable-status">{connection}</span>. No external provider or credential is used.</p>
        {error && <p className="mt-2 text-red-700" role="alert">{error}</p>}
      </form>

      {runs.length === 0 && <p>No agent runs yet.</p>}
      {runs.map((run) => {
        const responses = run.events.filter(({ kind }) => kind === "response").map(({ content }) => content).join("")
        const citations = run.events.filter(({ kind }) => kind === "citation")
        return (
          <article className="rounded-lg border bg-white p-5 dark:bg-gray-800" data-agent-run-id={run.id} data-last-sequence={run.events.at(-1)?.sequence || 0} data-state={run.state} key={run.id}>
            <div className="flex justify-between gap-4"><h2 className="font-semibold">{run.prompt}</h2><strong className="capitalize">{run.state}</strong></div>
            <ol aria-label="Agent activity" className="my-3 list-decimal pl-5 text-sm">
              {run.events.filter(({ kind }) => kind === "status").map((event) => <li key={event.sequence}>{event.content}</li>)}
            </ol>
            <progress aria-label={`Progress for ${run.prompt}`} className="w-full" max="100" value={run.progress} />
            {responses && <p aria-live="polite">{responses}</p>}
            {citations.length > 0 && <h3 className="mt-3 font-semibold">Citations</h3>}
            <ul>{citations.map((citation) => <li key={citation.sequence}><a className="text-indigo-600 underline" href={citation.metadata.url}>{citation.metadata.label || citation.content}</a></li>)}</ul>
            {run.summary && <p className="mt-3 text-green-700"><strong>Result:</strong> {run.summary}</p>}
            {!terminalStates.includes(run.state) && <button className="mt-3 rounded border px-3 py-1" onClick={() => void cancel(run)} type="button">Cancel</button>}
          </article>
        )
      })}
    </section>
  )
}
