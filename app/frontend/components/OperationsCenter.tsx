// app/frontend/components/OperationsCenter.tsx

import { createConsumer } from "@rails/actioncable"
import { useEffect, useRef, useState } from "react"

import {
  OperationState,
  operationAccessibility,
  requestOperationCancellation,
  subscribeToOperation
} from "active_admin/react"
import type { OperationValue } from "active_admin/react"

type OperationRecord = {
  operation_id: string
  idempotency_key: string
  sequence: number
  state: string
  progress: number
  message: string
  result: string | null
  error: string | null
  occurred_at: string
  cancelUrl: string
  retryUrl: string
  kind: string
}

type Telemetry = {
  requests: { count: number; error_count: number; p95_ms: number }
  database: { connections_busy: number; connections_idle: number; connections_total: number }
  cable: { active_subscriptions: number; deliveries_last_five_minutes: number; live_deliveries: number; replay_deliveries: number }
  runtime: { cpu_seconds: number; ruby_heap_mb: number; sqlite_mb: number }
  health: { status: string; recent_request_errors: number | null }
  observed_at: string
}

type Props = {
  createUrl: string
  operations: OperationRecord[]
  telemetry: Telemetry
}

type DisplayOperation = OperationValue & {
  cancelUrl: string
  retryUrl: string
  kind: string
}

type OperationError = NonNullable<OperationValue["error"]>

const terminalStates = ["completed", "failed", "cancelled"]

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
}

function fromRecord(record: OperationRecord): DisplayOperation {
  return {
    cancelUrl: record.cancelUrl,
    error: record.error ? { code: null, details: null, message: record.error, retryable: false } : null,
    idempotencyKey: record.idempotency_key,
    kind: record.kind,
    message: record.message,
    occurredAt: record.occurred_at,
    operationId: record.operation_id,
    progress: record.progress,
    result: record.result,
    retryUrl: record.retryUrl,
    sequence: record.sequence,
    state: record.state
  }
}

function errorMessage(error: OperationError | null) {
  return error?.message
}

export default function OperationsCenter({ createUrl, operations: initialOperations, telemetry }: Props) {
  const [operations, setOperations] = useState(() => initialOperations.map(fromRecord))
  const [connection, setConnection] = useState("connecting")
  const [error, setError] = useState<string | null>(null)
  const [appliedSequences, setAppliedSequences] = useState(() => new Map(
    initialOperations.map((operation) => [operation.operation_id, [operation.sequence]])
  ))
  const [pendingActions, setPendingActions] = useState(() => new Set<string>())
  const consumerRef = useRef(createConsumer())
  const pendingActionsRef = useRef(new Set<string>())
  const subscriptionsRef = useRef(new Map<string, { unsubscribe(): void }>())

  useEffect(() => {
    const subscriptions = subscriptionsRef.current
    operations.forEach((operation) => {
      const operationId = operation.operationId
      if (!operationId || subscriptions.has(operationId) || terminalStates.includes(operation.state)) return

      const operationState = new OperationState(operation)
      const subscription = subscribeToOperation({
        consumer: consumerRef.current,
        channel: "OperationsChannel",
        params: { operation_id: operationId, after_sequence: operationState.lastSequence },
        operationState,
        resume: false,
        onConnected: () => setConnection("connected"),
        onDisconnected: () => setConnection("disconnected"),
        onEvent: (_event: unknown, current: OperationValue) => {
          setAppliedSequences((existing) => {
            const next = new Map(existing)
            const sequences = next.get(operationId)!
            next.set(operationId, [...new Set([...sequences, current.sequence!])])
            return next
          })
          setOperations((existing) => existing.map((candidate) => (
            candidate.operationId === operationId ? { ...candidate, ...current } : candidate
          )))
          if (terminalStates.includes(current.state)) {
            subscriptions.get(operationId)?.unsubscribe()
            subscriptions.delete(operationId)
          }
        },
        onProtocolError: (protocolError: Error) => setError(protocolError.message),
        onRejected: () => setError("Cable subscription was not authorized")
      })
      subscriptions.set(operationId, subscription)
    })
  }, [operations])

  useEffect(() => () => {
    subscriptionsRef.current.forEach((subscription) => subscription.unsubscribe())
    consumerRef.current.disconnect()
  }, [])

  async function create(kind: string) {
    setError(null)
    const response = await fetch(createUrl, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "Idempotency-Key": crypto.randomUUID(),
        "X-CSRF-Token": csrfToken() || ""
      },
      body: JSON.stringify({ kind })
    })
    const payload = await response.json()
    if (!response.ok) throw new Error(payload.error || "Operation could not be started")
    setOperations((existing) => [fromRecord(payload), ...existing])
    setAppliedSequences((existing) => new Map(existing).set(payload.operation_id, [payload.sequence]))
  }

  async function cancel(operation: DisplayOperation) {
    await requestOperationCancellation({
      csrfToken: csrfToken(),
      operationId: operation.operationId,
      url: operation.cancelUrl
    })
  }

  async function retry(operation: DisplayOperation) {
    const response = await fetch(operation.retryUrl, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        "Idempotency-Key": crypto.randomUUID(),
        "X-CSRF-Token": csrfToken() || ""
      },
      body: "{}"
    })
    const payload = await response.json()
    if (!response.ok) throw new Error(payload.error || "Operation could not be retried")
    setOperations((existing) => [fromRecord(payload), ...existing])
    setAppliedSequences((existing) => new Map(existing).set(payload.operation_id, [payload.sequence]))
  }

  function reconnect() {
    setConnection("disconnected")
    consumerRef.current.disconnect()
    window.setTimeout(() => consumerRef.current.connect(), 3_000)
  }

  function safely(key: string, action: () => Promise<void>) {
    if (pendingActionsRef.current.has(key)) return

    pendingActionsRef.current.add(key)
    setPendingActions(new Set(pendingActionsRef.current))
    void action()
      .catch((actionError: Error) => setError(actionError.message))
      .finally(() => {
        pendingActionsRef.current.delete(key)
        setPendingActions(new Set(pendingActionsRef.current))
      })
  }

  return (
    <section className="space-y-6" data-testid="operations-center">
      <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-sm font-semibold uppercase tracking-wide text-indigo-600">Demo</p>
            <h2 className="text-2xl font-bold">Persistent operations</h2>
            <p className="text-sm text-gray-500">Cable: <span data-testid="cable-status">{connection}</span></p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pendingActions.has("create")} onClick={() => safely("create", () => create("successful_demo"))} type="button">
              Run successful job
            </button>
            <button className="rounded border px-4 py-2" disabled={pendingActions.has("create")} onClick={() => safely("create", () => create("failing_demo"))} type="button">
              Run failing job
            </button>
            <button className="rounded border px-4 py-2" data-testid="reconnect-cable" onClick={reconnect} type="button">
              Demonstrate reconnect
            </button>
          </div>
        </div>
        {error && <p className="mt-4 text-red-700" role="alert">{error}</p>}
      </div>

      <div className="grid gap-3 md:grid-cols-4" aria-label="Application telemetry">
        <Metric label="Requests / p95 / errors" value={`${telemetry.requests.count} / ${telemetry.requests.p95_ms} ms / ${telemetry.requests.error_count}`} />
        <Metric label="Database busy / total" value={`${telemetry.database.connections_busy} / ${telemetry.database.connections_total}`} />
        <Metric label="Cable deliveries / active / replayed" value={`${telemetry.cable.deliveries_last_five_minutes} / ${telemetry.cable.active_subscriptions} / ${telemetry.cable.replay_deliveries}`} />
        <Metric label="CPU sec / heap / disk" value={`${telemetry.runtime.cpu_seconds} / ${telemetry.runtime.ruby_heap_mb} MB / ${telemetry.runtime.sqlite_mb} MB`} />
      </div>
      <p className="text-sm">Health: <strong>{telemetry.health.status}</strong>; observed {telemetry.observed_at}</p>

      <div className="space-y-3">
        {operations.length === 0 && <p>No operations yet. Start a bounded demo above.</p>}
        {operations.map((operation) => {
          const accessibility = operationAccessibility(operation)
          return (
            <article
              {...accessibility}
              className="rounded-lg border border-gray-200 bg-white p-4 dark:border-gray-700 dark:bg-gray-800"
              data-operation-id={operation.operationId}
              data-applied-sequences={appliedSequences.get(operation.operationId!)!.join(",")}
              data-state={operation.state}
              key={operation.operationId}
            >
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h3 className="font-semibold">{operation.kind.replaceAll("_", " ")}</h3>
                  <p>{operation.message}</p>
                  {operation.result && <p className="text-green-700">{operation.result}</p>}
                  {errorMessage(operation.error) && <p className="text-red-700">{errorMessage(operation.error)}</p>}
                  <p className="text-xs text-gray-500">{operation.operationId} · event {operation.sequence}</p>
                </div>
                <strong className="capitalize">{operation.state}</strong>
              </div>
              <progress aria-label={`Progress for ${operation.operationId}`} className="mt-3 w-full" max="100" value={operation.progress || 0} />
              <p>{operation.progress || 0}%</p>
              <div className="mt-3 flex gap-2">
                {!terminalStates.includes(operation.state) && (
                  <button className="rounded border px-3 py-1" disabled={pendingActions.has(`cancel:${operation.operationId}`)} onClick={() => safely(`cancel:${operation.operationId}`, () => cancel(operation))} type="button">Cancel</button>
                )}
                {terminalStates.includes(operation.state) && (
                  <button className="rounded border px-3 py-1" disabled={pendingActions.has(`retry:${operation.operationId}`)} onClick={() => safely(`retry:${operation.operationId}`, () => retry(operation))} type="button">Retry</button>
                )}
              </div>
            </article>
          )
        })}
      </div>

      <Guidance />
    </section>
  )
}

function Metric({ label, value }: { label: string; value: string }) {
  return <div className="rounded border bg-white p-3 dark:bg-gray-800"><p className="text-xs text-gray-500">{label}</p><p className="font-semibold">{value}</p></div>
}

function Guidance() {
  return (
    <div className="grid gap-4 lg:grid-cols-3">
      <GuidancePanel title="Ruby">
        <code>Operations::Create.call(admin_user: current_admin_user, kind: "successful_demo", request_idempotency_key: key)</code>
        <p>The authenticated command creates persistent state before Solid Queue receives bounded work.</p>
      </GuidancePanel>
      <GuidancePanel title="JavaScript">
        <code>subscribeToOperation({`{ consumer, channel: "OperationsChannel", operationState }`})</code>
        <p>The gem rejects duplicates, stale sequences, wrong operation IDs, and post-terminal events.</p>
      </GuidancePanel>
      <GuidancePanel title="Architecture">
        <p>SQLite → Solid Queue worker → operation/event records → Solid Cable transport → React island.</p>
        <p><a className="text-indigo-600 underline" href="https://github.com/scarver2/activeadmin-react">View activeadmin-react</a></p>
      </GuidancePanel>
    </div>
  )
}

function GuidancePanel({ children, title }: { children: React.ReactNode; title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><div className="mt-2 space-y-2 text-sm">{children}</div></section>
}
