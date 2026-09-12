// app/frontend/components/ActivityCenter.tsx

import { createConsumer } from "@rails/actioncable"
import { useEffect, useMemo, useRef, useState } from "react"

export type ActivityNotification = {
  id: number
  sequence: number
  kind: string
  subject: string
  body: string
  deepLink: string
  occurredAt: string
  read: boolean
}

type Props = { createUrl: string, endpoint: string, notifications: ActivityNotification[] }
type Envelope = { type: "notification", notification: ActivityNotification }

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

function unique(items: ActivityNotification[]) {
  return [...new Map(items.map((item) => [item.sequence, item])).values()]
    .sort((left, right) => right.sequence - left.sequence)
    .slice(0, 100)
}

export default function ActivityCenter({ createUrl, endpoint, notifications: initial }: Props) {
  const [items, setItems] = useState(() => unique(initial))
  const [filter, setFilter] = useState("all")
  const [connection, setConnection] = useState("connecting")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const latestSequence = useRef(Math.max(0, ...initial.map((item) => item.sequence)))
  const consumer = useRef(createConsumer())

  function apply(item: ActivityNotification) {
    latestSequence.current = Math.max(latestSequence.current, item.sequence)
    setItems((current) => unique([...current, item]))
  }

  useEffect(() => {
    const subscription = consumer.current.subscriptions.create(
      { channel: "ActivityCenterChannel", after_sequence: latestSequence.current },
      {
        connected: () => setConnection("connected"),
        disconnected: () => setConnection("disconnected"),
        rejected: () => setError("Activity stream was not authorized"),
        received: (envelope: Envelope) => apply(envelope.notification)
      }
    )
    return () => {
      subscription.unsubscribe()
      consumer.current.disconnect()
    }
  }, [])

  const visible = useMemo(
    () => items.filter((item) => filter === "all" || (filter === "unread" ? !item.read : item.kind === filter)),
    [filter, items]
  )
  const groups = useMemo(() => visible.reduce<Record<string, ActivityNotification[]>>((result, item) => {
    const date = item.occurredAt.slice(0, 10)
    result[date] ||= []
    result[date].push(item)
    return result
  }, {}), [visible])
  const unread = items.filter((item) => !item.read).length

  async function setRead(item: ActivityNotification) {
    const proposed = !item.read
    setItems((current) => current.map((candidate) => candidate.id === item.id ? { ...candidate, read: proposed } : candidate))
    setError(null)
    try {
      const response = await fetch(`${endpoint}/${item.id}`, {
        method: "PATCH",
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ read: proposed })
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Read state was rejected")
      setItems((current) => current.map((candidate) => candidate.id === item.id ? payload : candidate))
    } catch (requestError) {
      setItems((current) => current.map((candidate) => candidate.id === item.id ? item : candidate))
      setError((requestError as Error).message)
    }
  }

  async function createDemo() {
    setLoading(true)
    setError(null)
    try {
      const response = await fetch(createUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: "{}"
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Notification creation failed")
      apply(payload)
    } catch (requestError) {
      setError((requestError as Error).message)
    } finally {
      setLoading(false)
    }
  }

  function reconnect() {
    setConnection("disconnected")
    consumer.current.disconnect()
    window.setTimeout(() => consumer.current.connect(), 500)
  }

  return (
    <section className="space-y-5" data-testid="activity-center">
      <header className="rounded-lg border bg-white p-5 dark:bg-gray-800">
        <p aria-live="polite" className="text-sm font-semibold">{unread} unread · Cable: <span data-testid="activity-cable-status">{connection}</span></p>
        <div className="mt-3 flex flex-wrap gap-2">
          <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={loading} onClick={() => void createDemo()} type="button">Create demo notification</button>
          <button className="rounded border px-4 py-2" data-testid="reconnect-activity" onClick={reconnect} type="button">Demonstrate reconnect</button>
          <label>Filter <select aria-label="Filter notifications" onChange={(event) => setFilter(event.target.value)} value={filter}><option value="all">All</option><option value="unread">Unread</option><option value="account">Account</option><option value="operation">Operation</option><option value="schedule">Schedule</option></select></label>
        </div>
      </header>
      {error && <p className="text-red-700" role="alert">{error}</p>}
      {visible.length === 0 && <p>No notifications match this filter.</p>}
      {Object.entries(groups).map(([date, datedItems]) => (
        <section className="space-y-2" key={date}><h3 className="font-semibold">{date}</h3><ol className="space-y-2">
          {datedItems.map((item) => <li className="rounded border bg-white p-4 dark:bg-gray-800" data-notification-sequence={item.sequence} key={item.sequence}>
            <a className="font-semibold" href={item.deepLink}>{item.subject}</a><p>{item.body}</p><p className="text-sm">{item.kind}</p>
            <button className="rounded border px-3 py-1" onClick={() => void setRead(item)} type="button">Mark {item.read ? "unread" : "read"}</button>
          </li>)}
        </ol></section>
      ))}
    </section>
  )
}
