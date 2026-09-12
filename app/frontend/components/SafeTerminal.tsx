// app/frontend/components/SafeTerminal.tsx

import { FitAddon } from "@xterm/addon-fit"
import { Terminal } from "@xterm/xterm"
import "@xterm/xterm/css/xterm.css"
import { createConsumer } from "@rails/actioncable"
import { useEffect, useRef, useState } from "react"

export type TerminalOutput = {
  id: number
  occurredAt: string
  sequence: number
  stream: "stdout" | "stderr" | "system"
  text: string
}

export type TerminalExecution = {
  cancelUrl: string
  commandKey: string
  displayCommand: string
  operationId: string
  outputs: TerminalOutput[]
  sequence: number
  state: string
}

type Command = { key: string, label: string }
type Envelope = { type: "output", operationId: string, state: string, terminal: boolean, output: TerminalOutput }
type Props = { commands: Command[], createUrl: string, executions: TerminalExecution[] }
type CableSubscription = { perform(action: string, data?: object): void, unsubscribe(): void }

const terminalStates = ["cancelled", "completed", "failed"]

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

function printable(text: string) {
  return text.replace(/[\u0000-\u0008\u000b-\u001f\u007f-\u009f]/g, "")
}

function orderedUnique(outputs: TerminalOutput[]) {
  return [...new Map(outputs.map((output) => [output.sequence, output])).values()]
    .sort((left, right) => left.sequence - right.sequence)
}

export default function SafeTerminal({ commands, createUrl, executions: initialExecutions }: Props) {
  const [connection, setConnection] = useState("connecting")
  const [error, setError] = useState<string | null>(null)
  const [executions, setExecutions] = useState(initialExecutions)
  const [pending, setPending] = useState(false)
  const pendingRequest = useRef(false)
  const consumer = useRef(createConsumer())
  const cursors = useRef(new Map(initialExecutions.map((execution) => [execution.operationId, execution.sequence])))
  const renderedOutputs = useRef(new Set<string>())
  const runCommand = useRef(create)
  const subscriptions = useRef(new Map<string, CableSubscription>())
  const terminalContainer = useRef<HTMLDivElement>(null)
  const terminal = useRef<Terminal | null>(null)

  async function create(commandKey: string) {
    if (pendingRequest.current) return

    pendingRequest.current = true
    setPending(true)
    setError(null)
    try {
      const response = await fetch(createUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "Idempotency-Key": crypto.randomUUID(),
          "X-CSRF-Token": csrfToken()
        },
        body: JSON.stringify({ command_key: commandKey })
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Safe command could not be queued")

      cursors.current.set(payload.operationId, payload.sequence)
      setExecutions((current) => [payload, ...current])
    } catch (commandError) {
      setError((commandError as Error).message)
    } finally {
      pendingRequest.current = false
      setPending(false)
    }
  }

  runCommand.current = create

  useEffect(() => {
    const instance = new Terminal({ convertEol: true, cursorBlink: true, rows: 18, theme: { background: "#111827" } })
    const fit = new FitAddon()
    let input = ""
    instance.loadAddon(fit)
    instance.open(terminalContainer.current!)
    fit.fit()
    instance.writeln("ActiveAdmin React safe terminal")
    instance.writeln("Type an allowlisted command exactly, or use a command button below.")
    instance.write("\r\nshowcase> ")
    const inputDisposable = instance.onData((data) => {
      if (data === "\r") {
        const commandKey = input.trim()
        instance.write("\r\n")
        input = ""
        if (commands.some((command) => command.key === commandKey)) void runCommand.current(commandKey)
        else instance.writeln("Rejected locally: command is not allowlisted.")
        instance.write("showcase> ")
      } else if (data === "\u007f" && input.length > 0) {
        input = input.slice(0, -1)
        instance.write("\b \b")
      } else if (/^[ -~]+$/.test(data) && input.length + data.length <= 80) {
        input += data
        instance.write(data)
      }
    })
    const resize = () => fit.fit()
    window.addEventListener("resize", resize)
    terminal.current = instance
    return () => {
      inputDisposable.dispose()
      window.removeEventListener("resize", resize)
      instance.dispose()
      terminal.current = null
    }
  }, [commands])

  useEffect(() => {
    [...executions].reverse().forEach((execution) => {
      execution.outputs.forEach((output) => {
        const key = `${execution.operationId}:${output.sequence}`
        if (renderedOutputs.current.has(key)) return

        renderedOutputs.current.add(key)
        const prefix = output.stream === "stderr" ? "[error] " : output.stream === "system" ? "[system] " : ""
        terminal.current!.writeln(`${prefix}${printable(output.text)}`)
      })
    })
  }, [executions])

  useEffect(() => {
    executions.forEach((execution) => {
      if (terminalStates.includes(execution.state) || subscriptions.current.has(execution.operationId)) return

      const subscription = consumer.current.subscriptions.create(
        { channel: "SafeTerminalChannel", operation_id: execution.operationId },
        {
          connected: () => {
            subscription.perform("resume", { after_sequence: cursors.current.get(execution.operationId) || 0 })
            setConnection("connected")
          },
          disconnected: () => setConnection("disconnected"),
          rejected: () => setError("Cable subscription was not authorized"),
          received: (envelope: Envelope) => {
            if (envelope.operationId !== execution.operationId) return
            if (envelope.output.sequence <= (cursors.current.get(execution.operationId) || 0)) return

            cursors.current.set(execution.operationId, envelope.output.sequence)
            setExecutions((current) => current.map((candidate) => candidate.operationId === execution.operationId ? {
              ...candidate,
              outputs: orderedUnique([...candidate.outputs, envelope.output]),
              sequence: envelope.output.sequence,
              state: envelope.state
            } : candidate))
            if (envelope.terminal) {
              subscription.unsubscribe()
              subscriptions.current.delete(execution.operationId)
            }
          }
        }
      ) as unknown as CableSubscription
      subscriptions.current.set(execution.operationId, subscription)
    })
  }, [executions])

  useEffect(() => () => {
    subscriptions.current.forEach((subscription) => subscription.unsubscribe())
    consumer.current.disconnect()
  }, [])

  async function cancel(execution: TerminalExecution) {
    pendingRequest.current = true
    setPending(true)
    setError(null)
    try {
      const response = await fetch(execution.cancelUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: "{}"
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Cancellation failed")

      setExecutions((current) => current.map((candidate) => candidate.operationId === payload.operationId ? payload : candidate))
    } catch (commandError) {
      setError((commandError as Error).message)
    } finally {
      pendingRequest.current = false
      setPending(false)
    }
  }

  function reconnect() {
    setConnection("disconnected")
    consumer.current.disconnect()
    window.setTimeout(() => consumer.current.connect(), 800)
  }

  return (
    <section className="space-y-5" data-testid="safe-terminal">
      <header className="rounded-lg border bg-white p-5 dark:bg-gray-800">
        <p className="text-sm font-semibold uppercase tracking-wide text-indigo-600">Deterministic demo</p>
        <h2 className="text-2xl font-bold">Safe terminal console</h2>
        <p>No shell is exposed. Only exact command keys owned by this Rails application can run.</p>
        <p className="text-sm text-gray-500">Cable: <span data-testid="terminal-cable-status">{connection}</span></p>
      </header>

      <div aria-label="Safe terminal output" className="min-h-80 rounded bg-gray-900 p-3" data-testid="xterm-host" ref={terminalContainer} />

      <div aria-label="Allowlisted commands" className="flex flex-wrap gap-2">
        {commands.map((command) => (
          <button className="rounded bg-indigo-600 px-4 py-2 text-white" disabled={pending} key={command.key} onClick={() => void create(command.key)} type="button">
            {command.label}
          </button>
        ))}
        <button className="rounded border px-4 py-2" data-testid="reconnect-terminal" onClick={reconnect} type="button">Demonstrate reconnect</button>
      </div>
      {error && <p className="text-red-700" role="alert">{error}</p>}

      <ol aria-label="Durable executions" className="space-y-3">
        {executions.length === 0 && <li>No commands have run yet.</li>}
        {executions.map((execution) => (
          <li className="rounded border bg-white p-4 dark:bg-gray-800" data-execution-id={execution.operationId} data-sequence={execution.sequence} data-state={execution.state} key={execution.operationId}>
            <strong>{execution.displayCommand}</strong> — <span className="capitalize">{execution.state}</span>
            {!terminalStates.includes(execution.state) && <button className="ml-3 rounded border px-3 py-1" disabled={pending} onClick={() => void cancel(execution)} type="button">Cancel</button>}
          </li>
        ))}
      </ol>

      <div className="grid gap-4 lg:grid-cols-3">
        <Guidance title="Ruby"><code>SafeTerminal::Commands.fetch(command_key)</code><p>Rails validates an exact registry key, persists execution/output, and queues deterministic application work.</p></Guidance>
        <Guidance title="JavaScript"><code>new Terminal() + SafeTerminalChannel</code><p>React owns xterm.js input, ordered output, cancellation, and cursor-based replay.</p></Guidance>
        <Guidance title="Architecture"><p>SQLite transcript → Solid Queue demo → Solid Cable transport → xterm.js presentation.</p><a className="text-indigo-600 underline" href="https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/safe-terminal.md">Read the safe-terminal guide</a></Guidance>
      </div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><div className="mt-2 space-y-2 text-sm">{children}</div></section>
}
