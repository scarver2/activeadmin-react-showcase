// app/frontend/components/AccountInspectorLauncher.test.tsx

import { act, fireEvent, render, screen } from "@testing-library/react"

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
})
