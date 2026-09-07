// app/frontend/components/OperatorChat.tsx

import { createConsumer } from "@rails/actioncable"
import { FormEvent, useEffect, useRef, useState } from "react"

export type ChatMessage = {
  id: number
  authorKey: string
  authorName: string
  body: string
  sequence: number
  occurredAt: string
}

type Props = {
  roomId: string
  roomName: string
  createUrl: string
  resetUrl: string
  messages: ChatMessage[]
}

type CableEnvelope = { type: "message", message: ChatMessage } | { type: "reset", messages: ChatMessage[] }

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

function orderedUnique(messages: ChatMessage[]) {
  return [...new Map(messages.map((message) => [message.sequence, message])).values()]
    .sort((left, right) => left.sequence - right.sequence)
}

export default function OperatorChat({ roomId, roomName, createUrl, resetUrl, messages: initialMessages }: Props) {
  const [messages, setMessages] = useState(() => orderedUnique(initialMessages))
  const [body, setBody] = useState("")
  const [connection, setConnection] = useState("connecting")
  const [pending, setPending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const latestSequence = useRef(initialMessages.at(-1)?.sequence || 0)
  const consumer = useRef(createConsumer())

  function apply(envelope: CableEnvelope) {
    if (envelope.type === "reset") {
      const resetMessages = orderedUnique(envelope.messages)
      latestSequence.current = resetMessages.at(-1)?.sequence || 0
      setMessages(resetMessages)
      return
    }

    if (envelope.message.sequence <= latestSequence.current) return
    latestSequence.current = envelope.message.sequence
    setMessages((current) => orderedUnique([...current, envelope.message]))
  }

  useEffect(() => {
    const subscription = consumer.current.subscriptions.create(
      { channel: "OperatorChatChannel", room_id: roomId, after_sequence: latestSequence.current },
      {
        connected: () => setConnection("connected"),
        disconnected: () => setConnection("disconnected"),
        rejected: () => setError("Cable subscription was not authorized"),
        received: (envelope: CableEnvelope) => apply(envelope)
      }
    )
    return () => {
      subscription.unsubscribe()
      consumer.current.disconnect()
    }
  }, [roomId])

  async function command(url: string, options: RequestInit = {}) {
    setPending(true)
    setError(null)
    try {
      const response = await fetch(url, {
        ...options,
        method: "POST",
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Chat command failed")
      return payload
    } finally {
      setPending(false)
    }
  }

  async function send(event: FormEvent) {
    event.preventDefault()
    try {
      const message = await command(createUrl, { body: JSON.stringify({ body }) }) as ChatMessage
      apply({ type: "message", message })
      setBody("")
    } catch (commandError) {
      setError((commandError as Error).message)
    }
  }

  async function reset() {
    try {
      const resetMessages = await command(resetUrl, { body: "{}" }) as ChatMessage[]
      apply({ type: "reset", messages: resetMessages })
    } catch (commandError) {
      setError((commandError as Error).message)
    }
  }

  function reconnect() {
    setConnection("disconnected")
    consumer.current.disconnect()
    window.setTimeout(() => consumer.current.connect(), 500)
  }

  return (
    <section className="space-y-5" data-testid="operator-chat">
      <header className="rounded-lg border bg-white p-5 dark:bg-gray-800">
        <p className="text-sm font-semibold uppercase tracking-wide text-indigo-600">Synthetic demo</p>
        <h2 className="text-2xl font-bold">{roomName}</h2>
        <p className="text-sm text-gray-500">Cable: <span data-testid="chat-cable-status">{connection}</span></p>
      </header>

      <ol aria-label="Conversation" className="space-y-3" data-last-sequence={latestSequence.current}>
        {messages.length === 0 && <li>No messages yet.</li>}
        {messages.map((message) => (
          <li className="rounded border bg-white p-4 dark:bg-gray-800" data-message-sequence={message.sequence} key={message.sequence}>
            <strong>{message.authorName}</strong>
            <p>{message.body}</p>
          </li>
        ))}
      </ol>

      <form className="space-y-2 rounded border p-4" onSubmit={send}>
        <label className="block font-semibold" htmlFor="operator-chat-body">Message as authenticated operator</label>
        <textarea id="operator-chat-body" maxLength={500} onChange={(event) => setBody(event.target.value)} required rows={3} value={body} />
        <div className="flex gap-2">
          <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pending || body.trim().length === 0} type="submit">Send message</button>
          <button className="rounded border px-4 py-2" disabled={pending} onClick={() => void reset()} type="button">Reset synthetic conversation</button>
          <button className="rounded border px-4 py-2" data-testid="reconnect-chat" onClick={reconnect} type="button">Demonstrate reconnect</button>
        </div>
      </form>
      {error && <p className="text-red-700" role="alert">{error}</p>}

      <div className="grid gap-4 lg:grid-cols-3">
        <Guidance title="Ruby"><code>OperatorChat::PostMessage.call(room:, body:)</code><p>Rails selects the author, validates content, and commits before broadcast.</p></Guidance>
        <Guidance title="JavaScript"><code>OperatorChatChannel + after_sequence</code><p>The island deduplicates ordered replay after reconnect.</p></Guidance>
        <Guidance title="Architecture"><p>SQLite record → Solid Cable envelope → React island. Cable never performs expensive work.</p></Guidance>
      </div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><div className="mt-2 space-y-2 text-sm">{children}</div></section>
}
