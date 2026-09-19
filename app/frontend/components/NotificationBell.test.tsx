// app/frontend/components/NotificationBell.test.tsx

import { act, render, screen } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import NotificationBell, { UNREAD_DELTA_EVENT } from "./NotificationBell"

const cable = vi.hoisted(() => {
  let callbacks: Record<string, (...args: unknown[]) => void> = {}
  const unsubscribe = vi.fn()
  return {
    callbacks: () => callbacks,
    disconnect: vi.fn(),
    subscriptions: { create: vi.fn((_identifier, handlers) => {
      callbacks = handlers
      return { unsubscribe }
    }) },
    unsubscribe
  }
})

vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

describe("NotificationBell", () => {
  beforeEach(() => vi.clearAllMocks())

  it("renders an accessible unread badge and links to the activity center", () => {
    render(<NotificationBell activityCenterUrl="/admin/activity_center" initialUnreadCount={3} latestSequence={4} />)
    const bell = screen.getByRole("link", { name: "Notifications, 3 unread" })
    expect(bell).toHaveAttribute("href", "/admin/activity_center")
    expect(bell).toHaveTextContent("3")
    expect(cable.subscriptions.create).toHaveBeenCalledWith(
      { after_sequence: 4, channel: "ActivityCenterChannel" }, expect.any(Object)
    )
  })

  it("deduplicates notification replay and accepts canonical unread projections", () => {
    render(<NotificationBell activityCenterUrl="/admin/activity_center" initialUnreadCount={1} latestSequence={4} />)
    act(() => {
      cable.callbacks().received({ type: "notification", notification: { read: false, sequence: 5 } })
      cable.callbacks().received({ type: "notification", notification: { read: false, sequence: 5 } })
    })
    expect(screen.getByRole("link", { name: "Notifications, 2 unread" })).not.toBeNull()

    act(() => cable.callbacks().received({ type: "unread_count", latestSequence: 5, unreadCount: 1 }))
    expect(screen.getByRole("link", { name: "Notifications, 1 unread" })).not.toBeNull()

    act(() => cable.callbacks().received({ type: "notification", notification: { read: true, sequence: 6 } }))
    expect(screen.getByRole("link", { name: "Notifications, 1 unread" })).not.toBeNull()
  })

  it("caps a large visible badge while retaining the exact accessible count", () => {
    render(<NotificationBell activityCenterUrl="/admin/activity_center" initialUnreadCount={100} latestSequence={100} />)
    expect(screen.getByRole("link", { name: "Notifications, 100 unread" })).toHaveTextContent("99+")
  })

  it("applies optimistic deltas, hides the zero badge, and cleans up", () => {
    const { unmount } = render(<NotificationBell activityCenterUrl="/admin/activity_center" initialUnreadCount={1} latestSequence={4} />)
    act(() => window.dispatchEvent(new CustomEvent(UNREAD_DELTA_EVENT, { detail: { delta: -1 } })))
    expect(document.querySelector(".notification-bell__badge")).toBeNull()

    unmount()
    expect(cable.unsubscribe).toHaveBeenCalled()
    expect(cable.disconnect).toHaveBeenCalled()
  })
})
