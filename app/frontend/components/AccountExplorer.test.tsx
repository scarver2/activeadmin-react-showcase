// app/frontend/components/AccountExplorer.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"

import AccountExplorer from "./AccountExplorer"

const populated = {
  filters: { plans: ["Enterprise", "Growth"], statuses: ["active", "trial"] },
  page: 1,
  perPage: 5,
  rows: [
    { activeUsers: 42, collectionHref: "/admin/accounts", href: "/admin/accounts/1", id: 1, inspectorHref: "/admin/accounts/1/inspector.json", name: "Bluebonnet", plan: "Enterprise", region: "Central", revenueCents: 125_000, status: "active" },
    { activeUsers: 12, collectionHref: "/admin/accounts", href: "/admin/accounts/2", id: 2, inspectorHref: "/admin/accounts/2/inspector.json", name: "Cedar", plan: "Growth", region: "East", revenueCents: 25_000, status: "trial" }
  ],
  sort: { direction: "asc", field: "name" },
  total: 7,
  totalPages: 2
}
const empty = { ...populated, rows: [], total: 0, totalPages: 1 }

const inspector = {
  actions: [
    { href: "/admin/accounts/1", label: "View full account" },
    { href: "/admin/accounts/1/edit", label: "Edit account" }
  ],
  account: { id: 1, name: "Bluebonnet", plan: "Enterprise", region: "Central", status: "active" },
  canonicalHref: "/admin/accounts/1",
  metrics: { activeUsers: 42, recordedOn: "2026-09-28", revenueCents: 125_000 },
  relationships: { contacts: 2, observations: 7 }
}

function response(body: unknown, ok = true, status = ok ? 200 : 422, redirected = false) {
  return Promise.resolve({ json: () => Promise.resolve(body), ok, redirected, status } as Response)
}

describe("AccountExplorer", () => {
  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
    window.history.replaceState(null, "", "/")
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

  it("maps an optional theme composition onto semantic data regions", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response(populated)))
    render(<AccountExplorer composition={{ dataHeading: "theme-heading", dataSurface: "theme-surface", dataTable: "theme-table", pagination: "theme-pagination", primaryAction: "theme-primary-action", toolbar: "theme-toolbar", toolbarSurface: "theme-toolbar-surface" }} endpoint="/accounts" />)

    const results = await screen.findByTestId("account-explorer-results")
    expect(screen.getByRole("heading", { name: "Synthetic account explorer" })).toHaveClass("theme-heading")
    expect(screen.getByLabelText("Search name").closest("form")).toHaveClass("theme-toolbar")
    expect(screen.getByRole("heading", { name: "Synthetic account explorer" }).parentElement).toHaveClass("theme-toolbar-surface")
    expect(screen.getByRole("button", { name: "Apply filters" })).toHaveClass("theme-primary-action")
    expect(screen.getByText("Rows")).toHaveClass("sr-only")
    expect(screen.getByLabelText("Rows")).toHaveClass("min-h-11")
    expect(results).toHaveClass("theme-surface")
    expect(screen.getByRole("table")).toHaveClass("theme-table")
    expect(screen.getByRole("navigation", { name: "Account pages" })).toHaveClass("theme-pagination")
  })

  it("uses singular summary grammar", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response({ ...populated, rows: [populated.rows[0]], total: 1, totalPages: 1 })))
    render(<AccountExplorer endpoint="/accounts" />)

    expect(await screen.findByTestId("account-explorer-results")).toHaveTextContent("1 account")
  })

  it("enhances canonical account links with a history-aware inspector and restores focus", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => response(inspector))
    vi.stubGlobal("fetch", fetchMock)
    const historyBack = vi.spyOn(window.history, "back").mockImplementation(() => undefined)
    render(<AccountExplorer endpoint="/accounts" />)

    const accountLink = await screen.findByRole("link", { name: "Bluebonnet" })
    expect(accountLink).toHaveAttribute("href", "/admin/accounts/1")
    fireEvent.click(accountLink)

    expect(await screen.findByRole("dialog", { name: "Bluebonnet" })).toBeVisible()
    expect(window.location.pathname).toBe("/admin/accounts/1")
    expect(screen.getByText("2 contacts · 7 metric observations")).toBeVisible()
    expect(screen.getByRole("link", { name: "View full account" })).toHaveAttribute("href", "/admin/accounts/1")
    expect(screen.getByRole("button", { name: "Close account inspector" })).toHaveFocus()

    fireEvent.keyDown(screen.getByRole("dialog"), { key: "Escape" })
    expect(historyBack).toHaveBeenCalledOnce()
    window.history.replaceState(null, "", "/admin/data_explorer")
    window.dispatchEvent(new PopStateEvent("popstate", { state: null }))
    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument())
    expect(accountLink).toHaveFocus()
  })

  it("renders the Rails-owned empty-observation state", async () => {
    const emptyObservation = {
      ...inspector,
      actions: [inspector.actions[0]],
      metrics: { activeUsers: 0, recordedOn: null, revenueCents: 0 }
    }
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => response(emptyObservation))
    vi.stubGlobal("fetch", fetchMock)
    render(<AccountExplorer endpoint="/accounts" />)

    fireEvent.click(await screen.findByRole("link", { name: "Bluebonnet" }))
    expect(await screen.findByText("No observations yet")).toBeVisible()
    expect(screen.queryByRole("link", { name: "Edit account" })).not.toBeInTheDocument()
  })

  it("reopens inspector state on browser forward and reports authorization and stale-record changes", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => response({}, false, 403))
      .mockImplementationOnce(() => response({}, false, 404))
    vi.stubGlobal("fetch", fetchMock)
    render(<AccountExplorer endpoint="/accounts" />)
    const accountLink = await screen.findByRole("link", { name: "Bluebonnet" })

    fireEvent.click(accountLink)
    expect(await screen.findByRole("alert")).toHaveTextContent("authorization changed")
    expect(screen.getByRole("link", { name: "Reauthenticate on the canonical account page" })).toHaveAttribute("href", expect.stringContaining("/admin/accounts/1"))

    window.history.replaceState(null, "", "/admin/data_explorer")
    window.dispatchEvent(new PopStateEvent("popstate", { state: null }))
    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument())
    window.history.replaceState(null, "", "/admin/accounts/1")
    window.dispatchEvent(new PopStateEvent("popstate", { state: null }))

    expect(await screen.findByRole("alert")).toHaveTextContent("no longer available")
    expect(screen.getByRole("link", { name: "Return to the account list" })).toHaveAttribute("href", "/admin/accounts")
  })

  it.each([
    ["redirected authentication", () => response({}, true, 200, true), "authorization changed"],
    ["unauthorized authentication", () => response({}, false, 401), "authorization changed"],
    ["endpoint message", () => response({ error: "Bounded inspector failure" }, false, 422), "Bounded inspector failure"],
    ["endpoint fallback", () => response({}, false, 500), "Account context could not be loaded"],
    ["unknown failure", () => Promise.reject("unknown"), "Account context could not be loaded"]
  ])("renders %s inspector failures", async (_label, inspectorResponse, message) => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => inspectorResponse())
    vi.stubGlobal("fetch", fetchMock)
    render(<AccountExplorer endpoint="/accounts" />)

    fireEvent.click(await screen.findByRole("link", { name: "Bluebonnet" }))
    expect(await screen.findByRole("alert")).toHaveTextContent(message as string)
  })

  it("aborts replaced inspector requests and dismisses a history-restored inspector directly", async () => {
    let rejectFirst!: (reason: DOMException) => void
    const firstInspector = new Promise<Response>((_resolve, reject) => { rejectFirst = reject })
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce((_url, options: RequestInit) => {
        options.signal?.addEventListener("abort", () => rejectFirst(new DOMException("Aborted", "AbortError")))
        return firstInspector
      })
      .mockImplementationOnce(() => response(inspector))
    vi.stubGlobal("fetch", fetchMock)
    render(<AccountExplorer endpoint="/accounts" />)
    const results = await screen.findByTestId("account-explorer-results")
    fireEvent.click(results)
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole("link", { name: "Bluebonnet" }))
    const replacement = { canonicalHref: "/admin/accounts/2", inspectorHref: "/admin/accounts/2/inspector.json", name: "Cedar" }
    window.history.replaceState(null, "", "/admin/data_explorer")
    window.dispatchEvent(new PopStateEvent("popstate", { state: { contextualInspector: replacement } }))
    expect(await screen.findByText("2 contacts · 7 metric observations")).toBeVisible()

    fireEvent.click(screen.getByRole("button", { name: "Close account inspector" }))
    await waitFor(() => expect(screen.queryByRole("dialog")).not.toBeInTheDocument())
  })

  it.each([
    { altKey: true },
    { button: 1 },
    { ctrlKey: true },
    { metaKey: true },
    { shiftKey: true }
  ])("does not intercept modified canonical link activation %#", async (event) => {
    vi.stubGlobal("fetch", vi.fn(() => response(populated)))
    render(<AccountExplorer endpoint="/accounts" />)
    const accountLink = await screen.findByRole("link", { name: "Bluebonnet" })

    fireEvent.click(accountLink, event)
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
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
