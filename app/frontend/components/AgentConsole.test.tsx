// app/frontend/components/AgentConsole.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import AgentConsole from "./AgentConsole"

const subscriptions: Array<Record<string, unknown>> = []
const perform = vi.fn()
const disconnect = vi.fn()
const connect = vi.fn()

vi.mock("@rails/actioncable", () => ({
  createConsumer: () => ({
    connect,
    disconnect,
    subscriptions: { create: (_params: object, callbacks: object) => {
      subscriptions.push(callbacks as Record<string, unknown>)
      return { perform, unsubscribe: vi.fn() }
    } }
  })
}))

const queued = {
  id: "run-1", prompt: "Inspect accounts", state: "queued", progress: 0, summary: null,
  events: [{ run_id: "run-1", sequence: 1, kind: "status" as const, content: "Queued deterministic analysis", progress: 0, metadata: {}, occurred_at: "now" }],
  showUrl: "/admin/agent_runs/run-1", cancelUrl: "/admin/agent_runs/run-1/cancel"
}

describe("AgentConsole", () => {
  beforeEach(() => { subscriptions.length = 0; vi.clearAllMocks(); vi.stubGlobal("fetch", vi.fn()) })

  it("subscribes with a replay cursor and renders progressive output, citation, and result", async () => {
    const second = { ...queued, id: "run-other", events: [] }
    const { unmount } = render(<AgentConsole createUrl="/admin/agent_runs" runs={[queued, second]} />)
    act(() => (subscriptions[0].connected as () => void)())
    expect(perform).toHaveBeenCalledWith("resume", { after_sequence: 1 })
    act(() => (subscriptions[1].connected as () => void)())
    expect(perform).toHaveBeenCalledWith("resume", { after_sequence: 0 })
    act(() => (subscriptions[0].disconnected as () => void)())
    expect(screen.getByTestId("agent-cable-status")).toHaveTextContent("disconnected")
    act(() => (subscriptions[0].rejected as () => void)())
    expect(screen.getByRole("alert")).toHaveTextContent("not authorized")
    act(() => (subscriptions[0].received as (event: object) => void)({ ...queued.events[0] }))
    act(() => (subscriptions[0].received as (event: object) => void)({ ...queued.events[0], run_id: "unknown", sequence: 9 }))
    act(() => (subscriptions[0].received as (event: object) => void)({ run_id: "run-1", sequence: 2, kind: "response", content: "Finding. ", progress: 50, metadata: {}, occurred_at: "now" }))
    act(() => (subscriptions[0].received as (event: object) => void)({ run_id: "run-1", sequence: 3, kind: "citation", content: "Accounts", progress: 70, metadata: { label: "Account data", url: "/admin/data_explorer" }, occurred_at: "now" }))
    act(() => (subscriptions[0].received as (event: object) => void)({ run_id: "run-1", sequence: 4, kind: "result", content: "Review trials", progress: 100, metadata: {}, occurred_at: "now" }))
    expect(screen.getByText("Finding.")).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Account data" })).toHaveAttribute("href", "/admin/data_explorer")
    expect(screen.getByText(/Review trials/)).toBeInTheDocument()
    unmount()
    expect(disconnect).toHaveBeenCalled()
  })

  it("creates, cancels, reconnects, rejects duplicate events, and reports errors", async () => {
    const fetchMock = vi.mocked(fetch)
    fetchMock.mockResolvedValueOnce(new Response(JSON.stringify({ ...queued, id: "run-2", prompt: "New prompt" }), { status: 201 }))
      .mockResolvedValueOnce(new Response("{}", { status: 500 }))
    render(<AgentConsole createUrl="/admin/agent_runs" runs={[queued]} />)
    fireEvent.change(screen.getByLabelText("Prompt"), { target: { value: "New prompt" } })
    fireEvent.click(screen.getByRole("button", { name: "Run demo agent" }))
    await screen.findByText("New prompt")
    fireEvent.click(screen.getAllByRole("button", { name: "Cancel" })[0])
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(screen.getByRole("alert")).toHaveTextContent("could not be cancelled")
    act(() => (subscriptions[0].received as (event: object) => void)({ run_id: "run-1", sequence: 2, kind: "status", content: "Agent run cancelled", progress: 0, metadata: {}, occurred_at: "now" }))
    expect(screen.getAllByText("cancelled")[0]).toBeInTheDocument()
    fetchMock.mockResolvedValueOnce(new Response("{}", { status: 200 }))
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
    const timeoutSpy = vi.spyOn(window, "setTimeout")
    fireEvent.click(screen.getByRole("button", { name: "Reconnect Cable" }))
    expect(disconnect).toHaveBeenCalled()
    ;(timeoutSpy.mock.calls[0][0] as () => void)()
    expect(connect).toHaveBeenCalled()
  })

  it("shows empty and request error states", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ error: "Nope" }), { status: 422 }))
    render(<AgentConsole createUrl="/admin/agent_runs" runs={[]} />)
    expect(screen.getByText("No agent runs yet.")).toBeInTheDocument()
    fireEvent.click(screen.getByRole("button", { name: "Run demo agent" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Nope")
  })

  it("uses safe response and citation fallbacks for terminal snapshots", async () => {
    const terminal = {
      ...queued,
      state: "completed",
      summary: "Done",
      events: [
        { ...queued.events[0], kind: "response" as const, content: "Answer" },
        { ...queued.events[0], sequence: 2, kind: "citation" as const, content: "Accounts", metadata: { url: "/admin/data_explorer" } }
      ]
    }
    render(<AgentConsole createUrl="/admin/agent_runs" runs={[terminal]} />)
    expect(screen.getByRole("link", { name: "Accounts" })).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Cancel" })).not.toBeInTheDocument()
    expect(subscriptions).toHaveLength(0)

    vi.mocked(fetch).mockResolvedValue(new Response("{}", { status: 422 }))
    fireEvent.click(screen.getByRole("button", { name: "Run demo agent" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Agent run could not be created")
  })
})
