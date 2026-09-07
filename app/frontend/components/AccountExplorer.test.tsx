// app/frontend/components/AccountExplorer.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"

import AccountExplorer from "./AccountExplorer"

const populated = {
  filters: { plans: ["Enterprise", "Growth"], statuses: ["active", "trial"] },
  page: 1,
  perPage: 5,
  rows: [
    { activeUsers: 42, href: "/admin/accounts/1", id: 1, name: "Bluebonnet", plan: "Enterprise", region: "Central", revenueCents: 125_000, status: "active" },
    { activeUsers: 12, href: "/admin/accounts/2", id: 2, name: "Cedar", plan: "Growth", region: "East", revenueCents: 25_000, status: "trial" }
  ],
  sort: { direction: "asc", field: "name" },
  total: 7,
  totalPages: 2
}
const empty = { ...populated, rows: [], total: 0, totalPages: 1 }

function response(body: unknown, ok = true) {
  return Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)
}

describe("AccountExplorer", () => {
  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it("loads and renders semantic account rows and totals", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response(populated)))
    render(<AccountExplorer endpoint="/admin/data-explorer/accounts" />)

    expect(screen.getByRole("status")).toHaveTextContent("Loading accounts")
    expect(await screen.findByTestId("account-explorer-results")).toHaveTextContent("7 accounts")
    expect(screen.getByRole("link", { name: "Bluebonnet" })).toHaveAttribute("href", "/admin/accounts/1")
    expect(screen.getByRole("cell", { name: "$1,250" })).toBeVisible()
    expect(screen.getByRole("cell", { name: "active" })).toBeVisible()
  })

  it("uses singular summary grammar", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response({ ...populated, rows: [populated.rows[0]], total: 1, totalPages: 1 })))
    render(<AccountExplorer endpoint="/accounts" />)

    expect(await screen.findByTestId("account-explorer-results")).toHaveTextContent("1 account")
  })

  it("submits filters, changes page size, paginates, and toggles server sorting", async () => {
    const fetchMock = vi.fn(() => response(populated))
    vi.stubGlobal("fetch", fetchMock)
    render(<AccountExplorer endpoint="/accounts" />)
    await screen.findByTestId("account-explorer-results")

    fireEvent.change(screen.getByLabelText("Search name"), { target: { value: "blue" } })
    fireEvent.change(screen.getByLabelText("Plan"), { target: { value: "Enterprise" } })
    fireEvent.change(screen.getByLabelText("Status"), { target: { value: "active" } })
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }))
    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("query=blue"), expect.anything()))

    fireEvent.change(screen.getByLabelText("Rows"), { target: { value: "10" } })
    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("per_page=10"), expect.anything()))
    fireEvent.click(screen.getByRole("button", { name: "Next" }))
    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("page=2"), expect.anything()))
    fireEvent.click(screen.getByRole("button", { name: "Previous" }))
    fireEvent.click(screen.getByRole("button", { name: "Sort by name" }))
    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("direction=desc"), expect.anything()))
    fireEvent.click(screen.getByRole("button", { name: "Sort by plan" }))
    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("sort=plan"), expect.anything()))
  })

  it("renders an empty result", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response(empty)))
    render(<AccountExplorer endpoint="/accounts" />)

    expect(await screen.findByTestId("account-explorer-empty")).toHaveTextContent("No accounts match")
  })

  it("renders endpoint and unknown errors and retries", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response({ error: "Sort is invalid" }, false))
      .mockRejectedValueOnce("unknown")
      .mockImplementationOnce(() => response(populated))
    vi.stubGlobal("fetch", fetchMock)
    render(<AccountExplorer endpoint="/accounts" />)

    expect(await screen.findByRole("alert")).toHaveTextContent("Sort is invalid")
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Accounts could not be loaded"))
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    expect(await screen.findByTestId("account-explorer-results")).toBeVisible()
  })

  it("uses the safe response fallback message", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response({}, false)))
    render(<AccountExplorer endpoint="/accounts" />)

    expect(await screen.findByRole("alert")).toHaveTextContent("Accounts could not be loaded")
  })

  it("times out and aborts an active request on unmount", async () => {
    vi.useFakeTimers()
    const abortSpy = vi.spyOn(AbortController.prototype, "abort")
    vi.stubGlobal("fetch", vi.fn((_url, options: RequestInit) => new Promise((_resolve, reject) => {
      options.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
    })))
    const { unmount } = render(<AccountExplorer endpoint="/accounts" />)

    await act(async () => vi.advanceTimersByTime(8_000))
    expect(screen.getByRole("alert")).toHaveTextContent("Account search timed out")
    unmount()
    expect(abortSpy).toHaveBeenCalled()
  })
})
