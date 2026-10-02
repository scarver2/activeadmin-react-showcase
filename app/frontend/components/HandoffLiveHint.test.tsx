// app/frontend/components/HandoffLiveHint.test.tsx

import { act, render, screen } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import HandoffLiveHint from "./HandoffLiveHint"

const cable = vi.hoisted(() => ({ callbacks: {} as Record<string, (...args: any[]) => void>, unsubscribe: vi.fn(), disconnect: vi.fn() }))
vi.mock("@rails/actioncable", () => ({ createConsumer: () => ({
  disconnect: cable.disconnect,
  subscriptions: { create: (_id: unknown, callbacks: typeof cable.callbacks) => {
    cable.callbacks = callbacks
    return { unsubscribe: cable.unsubscribe }
  } }
}) }))

describe("HandoffLiveHint", () => {
  beforeEach(() => vi.clearAllMocks())

  it("keeps durable refresh available through connection degradation and reconnect", () => {
    const { unmount } = render(<HandoffLiveHint itemId="item" version={2} refreshUrl="/admin/work_handoff?item=item" />)
    expect(screen.getByRole("status")).toHaveTextContent("connecting")
    act(() => cable.callbacks.connected())
    expect(screen.getByRole("status")).toHaveTextContent("connected")
    act(() => cable.callbacks.disconnected())
    expect(screen.getByRole("status")).toHaveTextContent("unavailable")
    expect(screen.getByRole("link")).toHaveAttribute("href", "/admin/work_handoff?item=item")
    act(() => cable.callbacks.rejected())
    act(() => cable.callbacks.connected())
    unmount()
    expect(cable.unsubscribe).toHaveBeenCalledOnce()
    expect(cable.disconnect).toHaveBeenCalledOnce()
  })

  it("ignores duplicate or stale hints and never interprets hints as approval", () => {
    render(<HandoffLiveHint itemId="item" version={2} refreshUrl="/refresh" />)
    act(() => cable.callbacks.received({ version: 2 }))
    expect(screen.getByRole("status")).not.toHaveTextContent("Work changed")
    act(() => cable.callbacks.received({ version: 1 }))
    act(() => cable.callbacks.received({ version: 3 }))
    expect(screen.getByRole("status")).toHaveTextContent("Work changed. Refresh before acting.")
  })
})
