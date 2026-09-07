// app/frontend/components/OperationsCenter.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import OperationsCenter from "./OperationsCenter"

const cable = vi.hoisted(() => {
  const callbacks: Array<Record<string, (...args: unknown[]) => void>> = []
  const perform = vi.fn()
  const unsubscribe = vi.fn()
  return {
    callbacks,
    connect: vi.fn(),
    disconnect: vi.fn(),
    subscriptions: {
      create: vi.fn((_identifier, subscriptionCallbacks) => {
        callbacks.push(subscriptionCallbacks)
        queueMicrotask(() => subscriptionCallbacks.connected())
        return { perform, unsubscribe }
      })
    },
    perform,
    unsubscribe
  }
})

vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

const queued = {
  cancelUrl: "/admin/operations/op-1/cancel",
  error: null,
  idempotency_key: "op-1:1",
  kind: "successful_demo",
  message: "Waiting for a worker",
  occurred_at: "2026-09-06T12:00:00Z",
  operation_id: "op-1",
  progress: 0,
  result: null,
  retryUrl: "/admin/operations/op-1/retry",
  sequence: 1,
  state: "queued"
}

const telemetry = {
  cable: { active_subscriptions: 1, deliveries_last_five_minutes: 3, live_deliveries: 2, replay_deliveries: 1 },
  database: { connections_busy: 1, connections_idle: 4, connections_total: 5 },
  health: { recent_request_errors: 0, status: "healthy" },
  observed_at: "2026-09-06T12:00:00Z",
  requests: { count: 10, error_count: 0, p95_ms: 12 },
  runtime: { cpu_seconds: 2, ruby_heap_mb: 3, sqlite_mb: 4 }
}

describe("OperationsCenter", () => {
  beforeEach(() => {
    cable.callbacks.length = 0
    cable.connect.mockClear()
    cable.disconnect.mockClear()
    cable.perform.mockClear()
    cable.subscriptions.create.mockClear()
    cable.unsubscribe.mockClear()
    vi.stubGlobal("fetch", vi.fn())
  })

  it("renders operations, telemetry, and implementation guidance", async () => {
    render(<OperationsCenter createUrl="/admin/operations" operations={[queued]} telemetry={telemetry} />)

    expect(screen.getByTestId("operations-center").textContent).toContain("Waiting for a worker")
    expect(screen.getByLabelText("Application telemetry").textContent).toContain("10 / 12 ms / 0")
    expect(screen.getByText("Ruby")).not.toBeNull()
    expect(screen.getByText("JavaScript")).not.toBeNull()
    expect(screen.getByText("Architecture")).not.toBeNull()
    await waitFor(() => expect(screen.getByTestId("cable-status").textContent).toBe("connected"))
  })

  it("applies live terminal progress and offers retry", async () => {
    render(<OperationsCenter createUrl="/admin/operations" operations={[queued, { ...queued, operation_id: "op-other", idempotency_key: "op-other:1" }]} telemetry={telemetry} />)
    await waitFor(() => expect(cable.callbacks).toHaveLength(2))

    act(() => {
      cable.callbacks[0].received({
        error: null,
        idempotency_key: "op-1:2",
        message: "Operation completed",
        occurred_at: "2026-09-06T12:00:01Z",
        operation_id: "op-1",
        progress: 100,
        result: "Ready",
        result_metadata: null,
        sequence: 2,
        state: "completed"
      })
    })

    expect(await screen.findByText("Operation completed")).not.toBeNull()
    expect(screen.getAllByText("Waiting for a worker")).toHaveLength(1)
    expect(screen.getByRole("button", { name: "Retry" })).not.toBeNull()
    expect(cable.unsubscribe).toHaveBeenCalledOnce()
  })

  it("keeps the gem's idempotency and monotonic-sequence protections active", async () => {
    render(<OperationsCenter createUrl="/admin/operations" operations={[queued]} telemetry={telemetry} />)
    await waitFor(() => expect(cable.callbacks).toHaveLength(1))
    const event = {
      error: null,
      idempotency_key: "op-1:2",
      message: "Fresh progress",
      occurred_at: "2026-09-06T12:00:01Z",
      operation_id: "op-1",
      progress: 20,
      result: null,
      result_metadata: null,
      sequence: 2,
      state: "running"
    }

    act(() => {
      cable.callbacks[0].received(event)
      cable.callbacks[0].received({ ...event, message: "Duplicate payload" })
      cable.callbacks[0].received({ ...event, idempotency_key: "op-1:stale", message: "Stale payload", sequence: 1 })
    })

    expect(await screen.findByText("Fresh progress")).not.toBeNull()
    expect(screen.queryByText("Duplicate payload")).toBeNull()
    expect(screen.queryByText("Stale payload")).toBeNull()
    expect(cable.subscriptions.create).toHaveBeenCalledWith(
      { channel: "OperationsChannel", operation_id: "op-1" },
      expect.any(Object)
    )

    act(() => cable.callbacks[0].connected())
    expect(cable.perform).toHaveBeenLastCalledWith("resume", { after_sequence: 2 })
  })

  it("starts work and sends authenticated cancellation through the gem helper", async () => {
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ ...queued, operation_id: "op-2", idempotency_key: "op-2:1" }), { status: 201 }))
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ ...queued, state: "running" }), { status: 200 }))
    render(<OperationsCenter createUrl="/admin/operations" operations={[]} telemetry={telemetry} />)

    fireEvent.click(screen.getByRole("button", { name: "Run successful job" }))
    expect(await screen.findByText("Waiting for a worker")).not.toBeNull()
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(fetchMock.mock.calls[0][0]).toBe("/admin/operations")
    expect(fetchMock.mock.calls[1][0]).toBe("/admin/operations/op-1/cancel")
  })

  it("disconnects and reconnects the real consumer on demand", () => {
    vi.useFakeTimers()
    render(<OperationsCenter createUrl="/admin/operations" operations={[]} telemetry={telemetry} />)

    fireEvent.click(screen.getByTestId("reconnect-cable"))
    expect(cable.disconnect).toHaveBeenCalled()
    vi.advanceTimersByTime(3_000)
    expect(cable.connect).toHaveBeenCalled()
    vi.useRealTimers()
  })

  it("reports disconnects, rejected subscriptions, and protocol errors", async () => {
    render(<OperationsCenter createUrl="/admin/operations" operations={[queued]} telemetry={telemetry} />)
    await waitFor(() => expect(cable.callbacks).toHaveLength(1))

    act(() => cable.callbacks[0].disconnected())
    expect(screen.getByTestId("cable-status").textContent).toBe("disconnected")
    act(() => cable.callbacks[0].rejected())
    expect(await screen.findByText("Cable subscription was not authorized")).not.toBeNull()
    act(() => cable.callbacks[0].received({ malformed: true }))
    expect(await screen.findByText(/Invalid operation event/)).not.toBeNull()
  })

  it("retries terminal work and renders results and failures", async () => {
    const terminal = { ...queued, error: "Expected failure", progress: 70, state: "failed" }
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ ...queued, operation_id: "op-retry", idempotency_key: "op-retry:1" }), { status: 201 }))
    render(<OperationsCenter createUrl="/admin/operations" operations={[terminal]} telemetry={telemetry} />)

    expect(screen.getByText("Expected failure")).not.toBeNull()
    fireEvent.click(screen.getByRole("button", { name: "Retry" }))

    expect(await screen.findByText("Waiting for a worker")).not.toBeNull()
    expect(fetchMock.mock.calls[0][0]).toBe("/admin/operations/op-1/retry")
  })

  it("shows server errors from create and retry commands", async () => {
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ error: "Create denied" }), { status: 403 }))
    render(<OperationsCenter createUrl="/admin/operations" operations={[]} telemetry={telemetry} />)
    fireEvent.click(screen.getByRole("button", { name: "Run failing job" }))
    expect(await screen.findByText("Create denied")).not.toBeNull()

    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 422 }))
    const { unmount } = render(<OperationsCenter createUrl="/admin/operations" operations={[{ ...queued, state: "cancelled" }]} telemetry={telemetry} />)
    fireEvent.click(screen.getByRole("button", { name: "Retry" }))
    expect(await screen.findByText("Operation could not be retried")).not.toBeNull()
    unmount()
  })

  it("sends the Rails CSRF token when one is present", async () => {
    const meta = document.createElement("meta")
    meta.name = "csrf-token"
    meta.content = "test-token"
    document.head.append(meta)
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    render(<OperationsCenter createUrl="/admin/operations" operations={[]} telemetry={telemetry} />)

    fireEvent.click(screen.getByRole("button", { name: "Run successful job" }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalled())

    expect(fetchMock.mock.calls[0][1]).toMatchObject({ headers: expect.objectContaining({ "X-CSRF-Token": "test-token" }) })
    meta.remove()
  })

  it("prevents duplicate submissions while an operation command is pending", async () => {
    let resolveRequest!: (response: Response) => void
    const pending = new Promise<Response>((resolve) => { resolveRequest = resolve })
    const fetchMock = vi.mocked(fetch).mockReturnValue(pending)
    render(<OperationsCenter createUrl="/admin/operations" operations={[]} telemetry={telemetry} />)
    const button = screen.getByRole("button", { name: "Run successful job" })
    const alternateButton = screen.getByRole("button", { name: "Run failing job" })

    act(() => {
      button.click()
      alternateButton.click()
    })

    expect(fetchMock).toHaveBeenCalledOnce()
    expect(button).toHaveProperty("disabled", true)
    resolveRequest(new Response(JSON.stringify(queued), { status: 201 }))
    await waitFor(() => expect(button).toHaveProperty("disabled", false))
  })
})
