// app/frontend/components/KanbanWorkflow.tsx

import { useState } from "react"
import type { DragEvent } from "react"

export type WorkflowItem = {
  id: number
  title: string
  context: string | null
  state: WorkflowState
  position: number
  moveUrl: string
}

type WorkflowState = "backlog" | "ready" | "in_progress" | "review" | "done"
type Props = { items: WorkflowItem[] }

const states: { key: WorkflowState, label: string }[] = [
  { key: "backlog", label: "Backlog" },
  { key: "ready", label: "Ready" },
  { key: "in_progress", label: "In progress" },
  { key: "review", label: "Review" },
  { key: "done", label: "Done" }
]

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

function canonicalMove(items: WorkflowItem[], itemId: number, state: WorkflowState, position: number) {
  const moving = items.find((item) => item.id === itemId)!
  const withoutMoving = items.filter((item) => item.id !== itemId)
  const target = withoutMoving.filter((item) => item.state === state)
  target.splice(Math.min(Math.max(position, 0), target.length), 0, { ...moving, state })

  return states.flatMap(({ key }) => {
    const column = key === state ? target : withoutMoving.filter((item) => item.state === key)
    return column.map((item, index) => ({ ...item, position: index }))
  })
}

export default function KanbanWorkflow({ items: initialItems }: Props) {
  const [items, setItems] = useState(initialItems)
  const [pendingId, setPendingId] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function move(item: WorkflowItem, state: WorkflowState, position: number) {
    const snapshot = items
    setItems(canonicalMove(snapshot, item.id, state, position))
    setPendingId(item.id)
    setError(null)

    try {
      const response = await fetch(item.moveUrl, {
        body: JSON.stringify({ state, position }),
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        method: "PATCH"
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Workflow move failed")
      setItems(payload.items)
    } catch (moveError) {
      setItems(snapshot)
      setError(`${(moveError as Error).message}. The board was restored.`)
    } finally {
      setPendingId(null)
    }
  }

  function drop(event: DragEvent, state: WorkflowState) {
    event.preventDefault()
    const item = items.find((candidate) => candidate.id === Number(event.dataTransfer.getData("text/plain")))
    if (item) void move(item, state, items.filter((candidate) => candidate.state === state && candidate.id !== item.id).length)
  }

  return (
    <section className="space-y-5" data-testid="kanban-workflow">
      {error && <p className="text-red-700" role="alert">{error}</p>}
      <div className="grid gap-4 xl:grid-cols-5" data-testid="kanban-board">
        {states.map(({ key, label }, stateIndex) => {
          const columnItems = items.filter((item) => item.state === key).sort((left, right) => left.position - right.position)
          return (
            <section
              aria-label={`${label} workflow column`}
              className="min-h-48 rounded-lg border bg-gray-50 p-3 dark:bg-gray-900"
              data-workflow-state={key}
              key={key}
              onDragOver={(event) => event.preventDefault()}
              onDrop={(event) => drop(event, key)}
            >
              <h2 className="font-semibold">{label} <span className="text-sm text-gray-500">({columnItems.length})</span></h2>
              <ol className="mt-3 space-y-3">
                {columnItems.map((item) => (
                  <li className="rounded border bg-white p-3 shadow-sm dark:bg-gray-800" draggable key={item.id} onDragStart={(event) => event.dataTransfer.setData("text/plain", String(item.id))}>
                    <h3 className="font-medium">{item.title}</h3>
                    {item.context && <p className="mt-1 text-sm text-gray-600">{item.context}</p>}
                    <div className="mt-3 flex flex-wrap gap-2">
                      {stateIndex > 0 && <button className="rounded border px-2 py-1 text-xs" disabled={pendingId === item.id} onClick={() => void move(item, states[stateIndex - 1].key, items.filter((candidate) => candidate.state === states[stateIndex - 1].key).length)} type="button">Move {item.title} to {states[stateIndex - 1].label}</button>}
                      {stateIndex < states.length - 1 && <button className="rounded border px-2 py-1 text-xs" disabled={pendingId === item.id} onClick={() => void move(item, states[stateIndex + 1].key, items.filter((candidate) => candidate.state === states[stateIndex + 1].key).length)} type="button">Move {item.title} to {states[stateIndex + 1].label}</button>}
                    </div>
                  </li>
                ))}
              </ol>
            </section>
          )
        })}
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Guidance title="Ruby"><code>Workflow::Move.call(item:, state:, position:)</code><p>Rails validates the vocabulary and ordering bounds, then commits canonical positions transactionally.</p></Guidance>
        <Guidance title="JavaScript"><code>drag → PATCH → canonical board</code><p>The island proposes optimistic movement and restores its snapshot when Rails rejects it.</p></Guidance>
        <Guidance title="Architecture"><p>Workflow items are records. Columns are fixed state-machine vocabulary, so no column table is needed.</p></Guidance>
      </div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><div className="mt-2 space-y-2 text-sm">{children}</div></section>
}
