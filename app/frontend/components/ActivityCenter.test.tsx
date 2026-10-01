// app/frontend/components/ActivityCenter.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ActivityCenter from "./ActivityCenter"
import type { ActivityNotification } from "./ActivityCenter"
import { UNREAD_DELTA_EVENT } from "./NotificationBell"

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
  attentionKind: "fyi", availableAction: null, body: "Account needs review", deepLink: "/admin/accounts",
  dismissed: false, id: 1, kind: "account", occurredAt: "2026-09-07T09:00:00Z", priority: "normal",
  read: false, sequence: 1, snoozedUntil: null, subject: "Account review"
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
    fireEvent.change(screen.getByLabelText("Filter notifications"), { target: { value: "requires_action" } })
    expect(screen.getByText("No notifications match this filter.")).not.toBeNull()
    fireEvent.change(screen.getByLabelText("Filter notifications"), { target: { value: "unread" } })
    expect(screen.getByText("Account review")).not.toBeNull()
    unmount()
    expect(cable.unsubscribe).toHaveBeenCalled()
    expect(cable.disconnect).toHaveBeenCalled()
  })

  it("applies live delivery once and reports cable failures", () => {
    render(<ActivityCenter {...props} />)
    const second = { ...notice, id: 2, sequence: 2, subject: "Live" }
    act(() => {
      cable.callbacks().received({ type: "notification", notification: second })
      cable.callbacks().received({ type: "notification", notification: second })
      cable.callbacks().received({ type: "unread_count", latestSequence: 2, unreadCount: 2 })
      cable.callbacks().disconnected()
      cable.callbacks().rejected()
    })
    expect(screen.getAllByText("Live")).toHaveLength(1)
    expect(screen.getByTestId("activity-cable-status")).toHaveTextContent("disconnected")
    expect(screen.getByRole("alert")).toHaveTextContent("Activity stream was not authorized")
  })

  it("optimistically persists read state with CSRF", async () => {
    const deltas: number[] = []
    const observeDelta = (event: Event) => deltas.push((event as CustomEvent<{ delta: number }>).detail.delta)
    window.addEventListener(UNREAD_DELTA_EVENT, observeDelta)
    const canonical = { ...notice, read: true }
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response(JSON.stringify(canonical), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify(notice), { status: 200 }))
    render(<ActivityCenter {...props} notifications={[notice, { ...notice, id: 2, sequence: 2, subject: "Second" }]} />)
    fireEvent.click(screen.getAllByRole("button", { name: "Mark read" })[1])
    expect(await screen.findByRole("button", { name: "Mark unread" })).not.toBeNull()
    expect(fetch).toHaveBeenCalledWith(`${props.endpoint}/1`, expect.objectContaining({ body: JSON.stringify({ read: true }), method: "PATCH" }))
    fireEvent.click(screen.getByRole("button", { name: "Mark unread" }))
    await waitFor(() => expect(fetch).toHaveBeenLastCalledWith(
      `${props.endpoint}/1`, expect.objectContaining({ body: JSON.stringify({ read: false }), method: "PATCH" })
    ))
    expect(deltas).toEqual([-1, 1])
    window.removeEventListener(UNREAD_DELTA_EVENT, observeDelta)
  })

  it("rolls back rejected and failed read mutations", async () => {
    const deltas: number[] = []
    const observeDelta = (event: Event) => deltas.push((event as CustomEvent<{ delta: number }>).detail.delta)
    window.addEventListener(UNREAD_DELTA_EVENT, observeDelta)
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
    expect(deltas).toEqual([-1, 1, -1, 1, -1, 1])
    window.removeEventListener(UNREAD_DELTA_EVENT, observeDelta)
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

  it("filters and persists snooze, dismiss, and restore state", async () => {
    const snoozed = { ...notice, snoozedUntil: "2099-09-30T12:00:00Z" }
    const dismissed = { ...snoozed, dismissed: true, snoozedUntil: null }
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response(JSON.stringify(snoozed), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify(dismissed), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify(notice), { status: 200 }))
    render(<ActivityCenter {...props} notifications={[notice, { ...notice, id: 2, sequence: 2, subject: "Second" }]} />)

    fireEvent.click(screen.getAllByRole("button", { name: "Snooze for one hour" })[1])
    fireEvent.change(screen.getByLabelText("Filter notifications"), { target: { value: "snoozed" } })
    expect(await screen.findByText("Account review")).not.toBeNull()
    expect(fetch).toHaveBeenCalledWith(`${props.endpoint}/1/snooze`, expect.objectContaining({ method: "PATCH" }))

    fireEvent.click(screen.getByRole("button", { name: "Dismiss" }))
    fireEvent.change(screen.getByLabelText("Filter notifications"), { target: { value: "dismissed" } })
    expect(await screen.findByRole("button", { name: "Restore" })).not.toBeNull()
    fireEvent.click(screen.getByRole("button", { name: "Restore" }))
    await waitFor(() => expect(fetch).toHaveBeenLastCalledWith(
      `${props.endpoint}/1/restore`, expect.objectContaining({ method: "PATCH" })
    ))
  })

  it("rolls back rejected and failed attention-state mutations", async () => {
    const deltas: number[] = []
    const observeDelta = (event: Event) => deltas.push((event as CustomEvent<{ delta: number }>).detail.delta)
    window.addEventListener(UNREAD_DELTA_EVENT, observeDelta)
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: "Snooze denied" }), { status: 403 }))
      .mockRejectedValueOnce(new Error("Mutation offline"))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    render(<ActivityCenter {...props} notifications={[notice, { ...notice, id: 2, sequence: 2, subject: "Second" }]} />)

    fireEvent.click(screen.getAllByRole("button", { name: "Snooze for one hour" })[1])
    expect(await screen.findByRole("alert")).toHaveTextContent("Snooze denied")
    expect(screen.getAllByRole("button", { name: "Snooze for one hour" })).toHaveLength(2)

    fireEvent.click(screen.getAllByRole("button", { name: "Dismiss" })[1])
    expect(await screen.findByRole("alert")).toHaveTextContent("Mutation offline")
    expect(screen.getAllByRole("button", { name: "Dismiss" })).toHaveLength(2)

    fireEvent.click(screen.getAllByRole("button", { name: "Dismiss" })[1])
    expect(await screen.findByRole("alert")).toHaveTextContent("Notification state was rejected")
    expect(deltas).toEqual([-1, 1, -1, 1, -1, 1])
    window.removeEventListener(UNREAD_DELTA_EVENT, observeDelta)
  })

  it.each([true, false])("does not double-adjust the bell when Cable arrives before HTTP: %s", async (cableFirst) => {
    const actionable = { ...notice, availableAction: { label: "Complete review", url: `${props.endpoint}/1/action` } }
    const completed = { ...actionable, availableAction: null, read: true }
    let resolveResponse!: (response: Response) => void
    vi.mocked(fetch).mockReturnValue(new Promise(resolve => { resolveResponse = resolve }))
    const deltas = vi.fn()
    window.addEventListener(UNREAD_DELTA_EVENT, deltas)
    render(<ActivityCenter {...props} notifications={[actionable]} />)
    fireEvent.click(screen.getByRole("button", { name: "Complete review" }))
    const deliver = () => act(() => {
      cable.callbacks().received({ type: "notification", notification: completed })
      cable.callbacks().received({ type: "unread_count", latestSequence: 1, unreadCount: 0 })
    })
    if (cableFirst) deliver()
    await act(async () => { resolveResponse(new Response(JSON.stringify(completed), { status: 200 })) })
    if (!cableFirst) deliver()
    expect(screen.queryByRole("button", { name: "Complete review" })).toBeNull()
    expect(deltas).not.toHaveBeenCalled()
    window.removeEventListener(UNREAD_DELTA_EVENT, deltas)
  })

  it("performs an available Rails action and reports rejection accessibly", async () => {
    const actionable = {
      ...notice,
      attentionKind: "requires_action" as const,
      availableAction: { label: "Complete review", url: `${props.endpoint}/1/action` },
      priority: "high" as const
    }
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response(JSON.stringify({ ...actionable, availableAction: null, read: true }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: "No longer available" }), { status: 422 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    const { rerender } = render(<ActivityCenter {...props} notifications={[actionable]} />)

    fireEvent.click(screen.getByRole("button", { name: "Complete review" }))
    await waitFor(() => expect(screen.queryByRole("button", { name: "Complete review" })).toBeNull())
    expect(fetch).toHaveBeenCalledWith(`${props.endpoint}/1/action`, expect.objectContaining({ method: "POST" }))

    rerender(<ActivityCenter {...props} notifications={[actionable]} />)
    act(() => cable.callbacks().received({ type: "notification", notification: actionable }))
    fireEvent.click(screen.getByRole("button", { name: "Complete review" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("No longer available")
    fireEvent.click(screen.getByRole("button", { name: "Complete review" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Notification action was rejected")
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
