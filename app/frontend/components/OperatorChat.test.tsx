// app/frontend/components/OperatorChat.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import OperatorChat from "./OperatorChat"
import type { ChatMessage } from "./OperatorChat"

const cable = vi.hoisted(() => {
  let callbacks: Record<string, (...args: unknown[]) => void> = {}
  return {
    connect: vi.fn(),
    disconnect: vi.fn(),
    get callbacks() { return callbacks },
    subscriptions: {
      create: vi.fn((_identifier, receivedCallbacks) => {
        callbacks = receivedCallbacks
        queueMicrotask(() => receivedCallbacks.connected())
        return { unsubscribe: vi.fn() }
      })
    }
  }
})

vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

const message: ChatMessage = {
  id: 1,
  authorKey: "maya",
  authorName: "Maya Ortiz",
  body: "Ready for review.",
  sequence: 1,
  occurredAt: "2026-09-07T10:00:00Z"
}

const props = {
  createUrl: "/admin/operator-chat/support/messages",
  messages: [message],
  resetUrl: "/admin/operator-chat/support/reset",
  roomId: "support",
  roomName: "Operator handoff"
}

describe("OperatorChat", () => {
  beforeEach(() => {
    cable.connect.mockClear()
    cable.disconnect.mockClear()
    cable.subscriptions.create.mockClear()
    vi.stubGlobal("fetch", vi.fn())
  })

  it("renders the complete demo contract and subscribes from the latest sequence", async () => {
    render(<OperatorChat {...props} />)

    expect(screen.getByTestId("operator-chat").textContent).toContain("Ready for review.")
    expect(screen.getByText("Ruby")).not.toBeNull()
    expect(screen.getByText("JavaScript")).not.toBeNull()
    expect(screen.getByText("Architecture")).not.toBeNull()
    expect(cable.subscriptions.create).toHaveBeenCalledWith(
      { after_sequence: 1, channel: "OperatorChatChannel", room_id: "support" },
      expect.any(Object)
    )
    await waitFor(() => expect(screen.getByTestId("chat-cable-status").textContent).toBe("connected"))
  })

  it("applies ordered live messages and ignores duplicate or stale delivery", () => {
    render(<OperatorChat {...props} />)
    act(() => {
      cable.callbacks.received({ type: "message", message: { ...message, id: 3, body: "Third", sequence: 3 } })
      cable.callbacks.received({ type: "message", message: { ...message, id: 2, body: "Second", sequence: 2 } })
      cable.callbacks.received({ type: "message", message: { ...message, body: "Duplicate", sequence: 3 } })
    })

    expect(screen.getByText("Third")).not.toBeNull()
    expect(screen.queryByText("Second")).toBeNull()
    expect(screen.queryByText("Duplicate")).toBeNull()
  })

  it("sends with CSRF protection and applies the response without waiting for Cable", async () => {
    const meta = document.createElement("meta")
    meta.name = "csrf-token"
    meta.content = "csrf-test"
    document.head.append(meta)
    const fetchMock = vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ ...message, id: 2, authorKey: "operator", authorName: "You", body: "Proceed", sequence: 2 }), { status: 201 }))
    render(<OperatorChat {...props} />)

    fireEvent.change(screen.getByLabelText("Message as authenticated operator"), { target: { value: "Proceed" } })
    fireEvent.submit(screen.getByRole("button", { name: "Send message" }).closest("form")!)

    expect(await screen.findByText("Proceed")).not.toBeNull()
    expect(screen.getByLabelText("Message as authenticated operator")).toHaveProperty("value", "")
    expect(fetchMock).toHaveBeenCalledWith(props.createUrl, expect.objectContaining({
      body: JSON.stringify({ body: "Proceed" }),
      headers: expect.objectContaining({ "X-CSRF-Token": "csrf-test" }),
      method: "POST"
    }))
    meta.remove()
  })

  it("resets to a server-owned snapshot and handles an empty conversation", async () => {
    const resetMessages = [{ ...message, id: 4, body: "Reset message" }]
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(resetMessages), { status: 200 }))
    render(<OperatorChat {...props} messages={[]} />)
    expect(screen.getByText("No messages yet.")).not.toBeNull()

    fireEvent.click(screen.getByRole("button", { name: "Reset synthetic conversation" }))
    expect(await screen.findByText("Reset message")).not.toBeNull()

    act(() => cable.callbacks.received({ type: "reset", messages: [] }))
    expect(screen.getByText("No messages yet.")).not.toBeNull()
  })

  it("reports command, authorization, and connection failures", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ error: "Message denied" }), { status: 422 }))
    render(<OperatorChat {...props} />)
    fireEvent.change(screen.getByLabelText("Message as authenticated operator"), { target: { value: "Denied" } })
    fireEvent.click(screen.getByRole("button", { name: "Send message" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Message denied")

    act(() => cable.callbacks.disconnected())
    expect(screen.getByTestId("chat-cable-status")).toHaveTextContent("disconnected")
    act(() => cable.callbacks.rejected())
    expect(screen.getByRole("alert")).toHaveTextContent("Cable subscription was not authorized")
  })

  it("uses a generic error, blocks pending commands, and reconnects", async () => {
    vi.useFakeTimers()
    let resolveRequest!: (response: Response) => void
    vi.mocked(fetch).mockReturnValue(new Promise((resolve) => { resolveRequest = resolve }))
    render(<OperatorChat {...props} />)
    fireEvent.change(screen.getByLabelText("Message as authenticated operator"), { target: { value: "Pending" } })
    fireEvent.click(screen.getByRole("button", { name: "Send message" }))
    expect(screen.getByRole("button", { name: "Send message" })).toHaveProperty("disabled", true)

    resolveRequest(new Response(JSON.stringify({}), { status: 500 }))
    await act(async () => { await Promise.resolve() })
    expect(screen.getByRole("alert")).toHaveTextContent("Chat command failed")

    fireEvent.click(screen.getByTestId("reconnect-chat"))
    expect(cable.disconnect).toHaveBeenCalled()
    act(() => vi.advanceTimersByTime(500))
    expect(cable.connect).toHaveBeenCalled()
    vi.useRealTimers()
  })

  it("reports a reset failure", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ error: "Reset denied" }), { status: 403 }))
    render(<OperatorChat {...props} />)

    fireEvent.click(screen.getByRole("button", { name: "Reset synthetic conversation" }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Reset denied")
  })
})
