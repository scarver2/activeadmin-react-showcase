// app/frontend/components/BulkProgress.test.tsx

import { act, fireEvent, render, screen } from "@testing-library/react"

import BulkProgress from "./BulkProgress"

const initial = { state: "queued", progress: 0, results: {} }
const complete = { state: "completed", progress: 100, results: { "1": "updated" } }
const tick = () => act(async () => { await vi.advanceTimersByTimeAsync(1000) })

describe("BulkProgress", () => {
  beforeEach(() => { vi.useFakeTimers() })
  afterEach(() => { vi.useRealTimers(); vi.unstubAllGlobals() })

  it("polls read-only progress and stops at completion", async () => {
    const fetcher = vi.fn().mockResolvedValue({ ok: true, json: async () => complete })
    vi.stubGlobal("fetch", fetcher)
    render(<BulkProgress endpoint="/status" initial={initial} />)
    await tick()
    expect(screen.getByRole("status")).toHaveTextContent("completed: 100%")
    expect(screen.getByText("Account 1: updated")).toBeVisible()
    await tick()
    expect(fetcher).toHaveBeenCalledTimes(1)
    expect(fetcher).toHaveBeenCalledWith("/status", { credentials: "same-origin", headers: { Accept: "application/json" } })
  })

  it("offers explicit recovery without losing durable progress", async () => {
    const fetcher = vi.fn().mockResolvedValueOnce({ ok: false }).mockRejectedValueOnce(new Error("offline")).mockResolvedValue({ ok: true, json: async () => complete })
    vi.stubGlobal("fetch", fetcher)
    render(<BulkProgress endpoint="/status" initial={initial} />)
    await tick()
    expect(screen.getByRole("alert")).toHaveTextContent("could not be refreshed")
    fireEvent.click(screen.getByRole("button", { name: "Retry progress" }))
    await tick()
    fireEvent.click(screen.getByRole("button", { name: "Retry progress" }))
    await tick()
    expect(screen.queryByRole("alert")).toBeNull()
  })

  it.each([true, false])("ignores an unmounted in-flight response (%s)", async (ok) => {
    let resolve!: (response: unknown) => void
    vi.stubGlobal("fetch", vi.fn(() => new Promise((done) => { resolve = done })))
    const view = render(<BulkProgress endpoint="/status" initial={initial} />)
    await tick()
    view.unmount()
    await act(async () => { resolve({ ok, json: async () => complete }) })
  })
})
