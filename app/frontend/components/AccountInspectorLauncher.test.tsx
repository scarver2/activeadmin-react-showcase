// app/frontend/components/AccountInspectorLauncher.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"

import AccountInspectorLauncher from "./AccountInspectorLauncher"

const props = {
  canonicalHref: "/admin/accounts/1",
  collectionHref: "/admin/accounts",
  inspectorHref: "/admin/accounts/1/inspector.json",
  label: "Inspect",
  name: "Bluebonnet"
}

describe("AccountInspectorLauncher", () => {
  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
    window.history.replaceState(null, "", "/")
    document.documentElement.removeAttribute("aria-busy")
  })

  it("uses an explicit dense-index label while retaining the canonical destination", () => {
    vi.stubGlobal("fetch", vi.fn(() => new Promise(() => undefined)))
    render(<AccountInspectorLauncher {...props} />)

    expect(screen.getByRole("link", { name: "Inspect" })).toHaveAttribute("href", "/admin/accounts/1")
  })

  it("reports a bounded inspector timeout with a canonical recovery action", async () => {
    vi.useFakeTimers()
    vi.stubGlobal("fetch", vi.fn((_url, options: RequestInit) => new Promise((_resolve, reject) => {
      options.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
    })))
    render(<AccountInspectorLauncher {...props} />)

    fireEvent.click(screen.getByRole("link", { name: "Inspect" }))
    await act(async () => vi.advanceTimersByTime(8_000))

    expect(screen.getByRole("alert")).toHaveTextContent("Account context timed out")
    expect(screen.getByRole("link", { name: "Open the canonical account page" })).toHaveAttribute("href", "/admin/accounts/1")
  })

  it("restores launcher focus from both a remounted and live origin history entry", async () => {
    window.history.replaceState({ contextualInspectorReturnFocus: props.inspectorHref }, "", "/admin/accounts")
    render(<AccountInspectorLauncher {...props} />)
    const launcher = screen.getByRole("link", { name: "Inspect" })
    await waitFor(() => expect(launcher).toHaveFocus())

    const outside = document.createElement("button")
    document.body.append(outside)
    outside.focus()
    window.dispatchEvent(new PopStateEvent("popstate", {
      state: { contextualInspectorReturnFocus: props.inspectorHref }
    }))
    await waitFor(() => expect(launcher).toHaveFocus())
    outside.remove()
  })

  it("does not let pending origin focus restoration steal focus from a newly opened inspector", () => {
    const frames: FrameRequestCallback[] = []
    vi.spyOn(window, "requestAnimationFrame").mockImplementation(callback => {
      frames.push(callback)
      return frames.length
    })
    window.history.replaceState({ contextualInspectorReturnFocus: props.inspectorHref }, "", "/admin/accounts")
    vi.stubGlobal("fetch", vi.fn(() => new Promise(() => undefined)))
    render(<AccountInspectorLauncher {...props} />)

    fireEvent.click(screen.getByRole("link", { name: "Inspect" }))
    act(() => frames.forEach(callback => callback(0)))

    expect(screen.getByRole("button", { name: "Close account inspector" })).toHaveFocus()
  })

  it("opens a shared surface-local inspector deep link on mount", async () => {
    window.history.replaceState(null, "", "/admin/accounts#account-inspector-1")
    vi.stubGlobal("fetch", vi.fn(() => Promise.resolve({
      json: () => Promise.resolve({
        actions: [{ href: "/admin/accounts/1", label: "View full account" }],
        account: { id: 1, name: "Bluebonnet", plan: "Growth", region: "Central", status: "active" },
        canonicalHref: "/admin/accounts/1",
        metrics: { activeUsers: 3, recordedOn: null, revenueCents: 500 },
        relationships: { contacts: 1, observations: 0 }
      }),
      ok: true,
      redirected: false,
      status: 200
    } as Response)))

    render(<AccountInspectorLauncher {...props} />)

    expect(await screen.findByRole("dialog", { name: "Bluebonnet" })).toBeVisible()
    expect(fetch).toHaveBeenCalledWith(props.inspectorHref, expect.objectContaining({ credentials: "same-origin" }))
  })

  it("leaves Turbo restoration to the remounted launcher instead of opening a transient dialog", () => {
    vi.stubGlobal("fetch", vi.fn(() => new Promise(() => undefined)))
    const first = render(<AccountInspectorLauncher {...props} />)
    const state = { turbo: { restorationIdentifier: "demo" }, contextualInspector: props }
    window.history.replaceState(state, "", "/admin/accounts#account-inspector-1")

    act(() => window.dispatchEvent(new PopStateEvent("popstate", { state })))

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    expect(fetch).not.toHaveBeenCalled()
    first.unmount()
    render(<AccountInspectorLauncher {...props} />)
    expect(screen.getByRole("dialog")).toBeVisible()
    expect(screen.getByRole("button", { name: "Close account inspector" })).toHaveFocus()
    expect(fetch).toHaveBeenCalledOnce()
  })

  it("waits for an in-flight Turbo visit on mount and removes the listener on unmount", () => {
    vi.stubGlobal("fetch", vi.fn(() => new Promise(() => undefined)))
    window.history.replaceState(null, "", "/admin/accounts#account-inspector-1")
    document.documentElement.setAttribute("aria-busy", "true")
    const outgoing = render(<AccountInspectorLauncher {...props} />)
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    outgoing.unmount()
    act(() => document.dispatchEvent(new Event("turbo:load")))
    expect(fetch).not.toHaveBeenCalled()

    render(<AccountInspectorLauncher {...props} />)
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    document.documentElement.removeAttribute("aria-busy")
    act(() => document.dispatchEvent(new Event("turbo:load")))
    expect(screen.getByRole("dialog")).toBeVisible()
    expect(screen.getByRole("button", { name: "Close account inspector" })).toHaveFocus()
    expect(fetch).toHaveBeenCalledOnce()
  })
})
