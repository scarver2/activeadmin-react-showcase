// app/frontend/components/ActivityCenter.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ActivityCenter from "./ActivityCenter"
import type { ActivityNotification } from "./ActivityCenter"

const cable = vi.hoisted(() => {
  let callbacks: Record<string, (...args: unknown[]) => void> = {}
  const unsubscribe = vi.fn()
  return {
    callbacks: () => callbacks,
    connect: vi.fn(),
    disconnect: vi.fn(),
    subscriptions: { create: vi.fn((_identifier, handlers) => {
      callbacks = handlers
      queueMicrotask(() => handlers.connected())
      return { unsubscribe }
    }) },
    unsubscribe
  }
})

vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

const notice: ActivityNotification = {
  body: "Account needs review", deepLink: "/admin/accounts", id: 1, kind: "account",
  occurredAt: "2026-09-07T09:00:00Z", read: false, sequence: 1, subject: "Account review"
}
const props = { createUrl: "/admin/activity-center/notifications", endpoint: "/admin/activity-center/notifications", notifications: [notice] }

describe("ActivityCenter", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.stubGlobal("fetch", vi.fn())
  })

  it("renders, groups, filters, subscribes, and cleans up", async () => {
    const { unmount } = render(<ActivityCenter {...props} />)
    expect(screen.getByText("2026-09-07")).not.toBeNull()
    expect(screen.getByText("1 unread · Cable:")).not.toBeNull()
    expect(cable.subscriptions.create).toHaveBeenCalledWith(
      { after_sequence: 1, channel: "ActivityCenterChannel" }, expect.any(Object)
    )
    await waitFor(() => expect(screen.getByTestId("activity-cable-status")).toHaveTextContent("connected"))
    fireEvent.change(screen.getByLabelText("Filter notifications"), { target: { value: "operation" } })
    expect(screen.getByText("No notifications match this filter.")).not.toBeNull()
    fireEvent.change(screen.getByLabelText("Filter notifications"), { target: { value: "unread" } })
    expect(screen.getByText("Account review")).not.toBeNull()
    unmount()
    expect(cable.unsubscribe).toHaveBeenCalled()
    expect(cable.disconnect).toHaveBeenCalled()
  })

  it("applies live delivery once and reports cable failures", () => {
    render(<ActivityCenter {...props} notifications={[notice, { ...notice, id: 2, sequence: 2, subject: "Second" }]} />)
    const second = { ...notice, id: 2, sequence: 2, subject: "Live" }
    act(() => {
      cable.callbacks().received({ type: "notification", notification: second })
      cable.callbacks().received({ type: "notification", notification: second })
      cable.callbacks().disconnected()
      cable.callbacks().rejected()
    })
    expect(screen.getAllByText("Live")).toHaveLength(1)
    expect(screen.getByTestId("activity-cable-status")).toHaveTextContent("disconnected")
    expect(screen.getByRole("alert")).toHaveTextContent("Activity stream was not authorized")
  })

  it("optimistically persists read state with CSRF", async () => {
    const canonical = { ...notice, read: true }
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(canonical), { status: 200 }))
    render(<ActivityCenter {...props} notifications={[notice, { ...notice, id: 2, sequence: 2, subject: "Second" }]} />)
    fireEvent.click(screen.getAllByRole("button", { name: "Mark read" })[1])
    expect(await screen.findByRole("button", { name: "Mark unread" })).not.toBeNull()
    expect(fetch).toHaveBeenCalledWith(`${props.endpoint}/1`, expect.objectContaining({ body: JSON.stringify({ read: true }), method: "PATCH" }))
  })

  it("rolls back rejected and failed read mutations", async () => {
    vi.mocked(fetch).mockResolvedValueOnce(new Response(JSON.stringify({ error: "Denied" }), { status: 403 }))
      .mockRejectedValueOnce(new Error("Offline"))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    render(<ActivityCenter {...props} notifications={[notice, { ...notice, id: 2, sequence: 2, subject: "Second" }]} />)
    fireEvent.click(screen.getAllByRole("button", { name: "Mark read" })[0])
    expect(await screen.findByRole("alert")).toHaveTextContent("Denied")
    fireEvent.click(screen.getAllByRole("button", { name: "Mark read" })[0])
    expect(await screen.findByRole("alert")).toHaveTextContent("Offline")
    fireEvent.click(screen.getAllByRole("button", { name: "Mark read" })[0])
    expect(await screen.findByRole("alert")).toHaveTextContent("Read state was rejected")
  })

  it("creates a persisted demo notification and handles rejection", async () => {
    const second = { ...notice, id: 2, sequence: 2, subject: "Live" }
    vi.mocked(fetch).mockResolvedValueOnce(new Response(JSON.stringify(second), { status: 201 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    render(<ActivityCenter {...props} />)
    fireEvent.click(screen.getByRole("button", { name: "Create demo notification" }))
    expect(await screen.findByText("Live")).not.toBeNull()
    fireEvent.click(screen.getByRole("button", { name: "Create demo notification" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Notification creation failed")
  })

  it("reports network creation failures and reconnects", async () => {
    vi.useFakeTimers()
    vi.mocked(fetch).mockRejectedValue(new Error("Network unavailable"))
    render(<ActivityCenter {...props} notifications={[]} />)
    fireEvent.click(screen.getByRole("button", { name: "Create demo notification" }))
    await act(async () => { await Promise.resolve() })
    expect(screen.getByRole("alert")).toHaveTextContent("Network unavailable")
    fireEvent.click(screen.getByTestId("reconnect-activity"))
    act(() => vi.advanceTimersByTime(500))
    expect(cable.connect).toHaveBeenCalled()
    vi.useRealTimers()
  })
})
