// app/frontend/components/SafeTerminal.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import SafeTerminal, { type TerminalExecution } from "./SafeTerminal"

const xterm = vi.hoisted(() => {
  let dataCallback: ((data: string) => void) | undefined
  const inputDispose = vi.fn()
  const fit = vi.fn()
  const instance = {
    dispose: vi.fn(),
    loadAddon: vi.fn(),
    onData: vi.fn((callback: (data: string) => void) => {
      dataCallback = callback
      return { dispose: inputDispose }
    }),
    open: vi.fn(),
    write: vi.fn(),
    writeln: vi.fn()
  }
  return { emit: (data: string) => dataCallback?.(data), fit, inputDispose, instance }
})

const cable = vi.hoisted(() => {
  const callbacks: Array<Record<string, (...args: unknown[]) => void>> = []
  const subscriptions: Array<{ perform: ReturnType<typeof vi.fn>, unsubscribe: ReturnType<typeof vi.fn> }> = []
  return {
    callbacks,
    connect: vi.fn(),
    disconnect: vi.fn(),
    subscriptions: {
      create: vi.fn((_identifier, subscriptionCallbacks) => {
        callbacks.push(subscriptionCallbacks)
        const subscription = { perform: vi.fn(), unsubscribe: vi.fn() }
        subscriptions.push(subscription)
        queueMicrotask(() => subscriptionCallbacks.connected())
        return subscription
      })
    },
    created: subscriptions
  }
})

vi.mock("@xterm/xterm", () => ({ Terminal: function Terminal() { return xterm.instance } }))
vi.mock("@xterm/addon-fit", () => ({ FitAddon: function FitAddon() { return { fit: xterm.fit } } }))
vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

const commands = [
  { key: "showcase:status", label: "Show application status" },
  { key: "showcase:backup:verify", label: "Verify backup plan" }
]

const queued: TerminalExecution = {
  cancelUrl: "/admin/terminal_executions/op-1/cancel",
  commandKey: "showcase:status",
  displayCommand: "showcase:status",
  operationId: "op-1",
  outputs: [{ id: 1, occurredAt: "2026-09-07T12:00:00Z", sequence: 1, stream: "system", text: "Queued\u0007" }],
  sequence: 1,
  state: "queued"
}

describe("SafeTerminal", () => {
  beforeEach(() => {
    cable.callbacks.length = 0
    cable.created.length = 0
    cable.connect.mockClear()
    cable.disconnect.mockClear()
    cable.subscriptions.create.mockClear()
    xterm.fit.mockClear()
    xterm.inputDispose.mockClear()
    Object.values(xterm.instance).forEach((mock) => mock.mockClear())
    vi.stubGlobal("fetch", vi.fn())
    vi.stubGlobal("crypto", { randomUUID: () => "browser-request" })
    document.head.innerHTML = '<meta name="csrf-token" content="token">'
  })

  it("mounts real xterm, durable state, and complete implementation guidance", async () => {
    const { unmount } = render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[queued]} />)

    expect(screen.getByTestId("safe-terminal").textContent).toContain("No shell is exposed")
    expect(screen.getByText("Ruby")).not.toBeNull()
    expect(screen.getByText("JavaScript")).not.toBeNull()
    expect(screen.getByText("Architecture")).not.toBeNull()
    expect(screen.getByRole("link", { name: "Read the safe-terminal guide" })).not.toBeNull()
    expect(xterm.instance.open).toHaveBeenCalled()
    expect(xterm.fit).toHaveBeenCalled()
    expect(xterm.instance.writeln).toHaveBeenCalledWith("[system] Queued")
    await waitFor(() => expect(cable.created[0].perform).toHaveBeenCalledWith("resume", { after_sequence: 1 }))

    fireEvent(window, new Event("resize"))
    expect(xterm.fit).toHaveBeenCalledTimes(2)
    unmount()
    expect(xterm.inputDispose).toHaveBeenCalled()
    expect(xterm.instance.dispose).toHaveBeenCalled()
    expect(cable.created[0].unsubscribe).toHaveBeenCalled()
    expect(cable.disconnect).toHaveBeenCalled()
  })

  it("accepts only exact advertised terminal input and supports editing", async () => {
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValue(new Response(JSON.stringify({ ...queued, operationId: "op-2" }), { status: 201 }))
    render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[]} />)

    act(() => {
      xterm.emit("showcase:status")
      xterm.emit("\r")
    })
    await waitFor(() => expect(fetchMock).toHaveBeenCalledOnce())
    expect(fetchMock).toHaveBeenCalledWith("/admin/terminal_executions", expect.objectContaining({
      body: JSON.stringify({ command_key: "showcase:status" }),
      headers: expect.objectContaining({ "Idempotency-Key": "browser-request", "X-CSRF-Token": "token" })
    }))

    act(() => {
      xterm.emit("bad")
      xterm.emit("\u007f")
      xterm.emit("\r")
      xterm.emit("\u007f")
      xterm.emit("\n")
      xterm.emit("x".repeat(81))
    })
    expect(xterm.instance.writeln).toHaveBeenCalledWith("Rejected locally: command is not allowlisted.")
    expect(xterm.instance.write).toHaveBeenCalledWith("\b \b")
    expect(fetchMock).toHaveBeenCalledOnce()
  })

  it("starts a command once and reports server and network errors", async () => {
    const fetchMock = vi.mocked(fetch)
    let resolveRequest: ((response: Response) => void) | undefined
    fetchMock.mockReturnValueOnce(new Promise((resolve) => { resolveRequest = resolve }))
    const { rerender } = render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[]} />)

    const start = screen.getByRole("button", { name: "Show application status" })
    fireEvent.click(start)
    fireEvent.click(start)
    act(() => {
      xterm.emit("showcase:status")
      xterm.emit("\r")
    })
    expect(fetchMock).toHaveBeenCalledOnce()
    await act(async () => resolveRequest?.(new Response(JSON.stringify(queued), { status: 201 })))

    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ error: "Denied" }), { status: 422 }))
    fireEvent.click(start)
    expect(await screen.findByRole("alert")).toHaveTextContent("Denied")

    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    fireEvent.click(start)
    expect(await screen.findByRole("alert")).toHaveTextContent("Safe command could not be queued")

    fetchMock.mockRejectedValueOnce(new Error("Offline"))
    document.head.innerHTML = ""
    fireEvent.click(start)
    expect(await screen.findByRole("alert")).toHaveTextContent("Offline")

    rerender(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[]} />)
  })

  it("applies ordered live output, ignores stale/wrong output, and unsubscribes at completion", async () => {
    render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[queued, { ...queued, operationId: "op-2", outputs: [], sequence: 0 }]} />)
    await waitFor(() => expect(cable.callbacks).toHaveLength(2))

    act(() => {
      cable.callbacks[1].received({ ...envelope(1, "stdout", "Zero cursor"), operationId: "op-2" })
      cable.callbacks[0].received({ ...envelope(2, "stderr", "Warning\u001b[31m"), operationId: "other" })
      cable.callbacks[0].received(envelope(1, "stdout", "Stale"))
      cable.callbacks[0].received(envelope(2, "stdout", "Working"))
      cable.callbacks[0].received(envelope(3, "stderr", "Warning\u001b[31m"))
      cable.callbacks[0].received({ ...envelope(4, "system", "Done"), state: "completed", terminal: true })
    })

    expect(xterm.instance.writeln).toHaveBeenCalledWith("Working")
    expect(xterm.instance.writeln).toHaveBeenCalledWith("[error] Warning[31m")
    expect(xterm.instance.writeln).toHaveBeenCalledWith("[system] Done")
    expect(cable.created[0].unsubscribe).toHaveBeenCalled()
    expect(screen.getByText("completed")).not.toBeNull()
  })

  it("cancels once and reports both cancellation error forms", async () => {
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ ...queued, state: "cancelled" }), { status: 200 }))
    const second = { ...queued, operationId: "op-2", cancelUrl: "/admin/terminal_executions/op-2/cancel" }
    const view = render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[queued, second]} />)

    const cancel = screen.getAllByRole("button", { name: "Cancel" })[0]
    fireEvent.click(cancel)
    fireEvent.click(cancel)
    await waitFor(() => expect(fetchMock).toHaveBeenCalledOnce())
    expect(fetchMock).toHaveBeenCalledWith(queued.cancelUrl, expect.objectContaining({ method: "POST" }))
    expect(await screen.findByText("cancelled")).not.toBeNull()

    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ error: "Already stopped" }), { status: 409 }))
    view.unmount()
    render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[queued]} />)
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Already stopped")

    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Cancellation failed")
  })

  it("reports Cable lifecycle and reconnects the consumer", async () => {
    vi.useFakeTimers()
    render(<SafeTerminal commands={commands} createUrl="/admin/terminal_executions" executions={[queued, { ...queued, operationId: "done", state: "failed" }]} />)
    await act(async () => Promise.resolve())

    act(() => cable.callbacks[0].disconnected())
    expect(screen.getByTestId("terminal-cable-status")).toHaveTextContent("disconnected")
    act(() => cable.callbacks[0].rejected())
    expect(screen.getByRole("alert")).toHaveTextContent("Cable subscription was not authorized")

    fireEvent.click(screen.getByTestId("reconnect-terminal"))
    expect(cable.disconnect).toHaveBeenCalled()
    act(() => vi.advanceTimersByTime(800))
    expect(cable.connect).toHaveBeenCalled()
    vi.useRealTimers()
  })
})

function envelope(sequence: number, stream: "stdout" | "stderr" | "system", text: string) {
  return {
    operationId: "op-1",
    output: { id: sequence, occurredAt: "2026-09-07T12:00:01Z", sequence, stream, text },
    state: "running",
    terminal: false,
    type: "output"
  }
}
