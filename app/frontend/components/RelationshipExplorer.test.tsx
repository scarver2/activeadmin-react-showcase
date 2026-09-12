// app/frontend/components/RelationshipExplorer.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"

import RelationshipExplorer from "./RelationshipExplorer"

const bluebonnet = {
  contactCount: 2,
  id: 1,
  name: "Bluebonnet Logistics",
  plan: "Enterprise",
  region: "Central",
  status: "active"
}
const cedar = {
  contactCount: 1,
  id: 2,
  name: "Cedar Ridge Health",
  plan: "Growth",
  region: "East",
  status: "trial"
}
const filters = {
  plans: [ "Enterprise", "Growth", "Starter" ],
  regions: [ "Central", "East", "West" ],
  relationshipRoles: [ "Executive sponsor", "Operations lead", "Technical lead" ]
}
const populated = {
  accounts: [ bluebonnet, cedar ],
  filters,
  selectedAccount: {
    ...bluebonnet,
    contacts: [
      {
        email: "marisol@bluebonnet.example",
        fullName: "Marisol Vega",
        href: "/admin/contacts/10",
        id: 10,
        jobTitle: "Chief Operating Officer",
        relationshipRole: "Executive sponsor"
      }
    ],
    href: "/admin/accounts/1"
  },
  total: 2,
  truncated: false
}
const selectedCedar = {
  ...populated,
  selectedAccount: {
    ...cedar,
    contacts: [],
    href: "/admin/accounts/2"
  }
}
const empty = { accounts: [], filters, selectedAccount: null, total: 0, truncated: false }

function response(body: unknown, ok = true) {
  return Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)
}

function renderExplorer() {
  return render(<RelationshipExplorer endpoint="/admin/relationship-explorer/accounts" />)
}

describe("RelationshipExplorer", () => {
  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it("loads account relationships with Rails-owned navigation", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response(populated)))
    renderExplorer()

    expect(screen.getByRole("status")).toHaveTextContent("Loading relationships")
    expect(await screen.findByTestId("relationship-explorer-results")).toHaveTextContent("2 accounts")
    expect(screen.getByRole("link", { name: "Bluebonnet Logistics" })).toHaveAttribute("href", "/admin/accounts/1")
    expect(screen.getByRole("link", { name: "Marisol Vega" })).toHaveAttribute("href", "/admin/contacts/10")
    expect(screen.getByTestId("selected-account")).toHaveTextContent("Chief Operating Officer")
  })

  it("uses singular grammar and explains a truncated result", async () => {
    const one = { ...populated, accounts: [ bluebonnet ], total: 1, truncated: true }
    vi.stubGlobal("fetch", vi.fn(() => response(one)))
    renderExplorer()

    expect(await screen.findByTestId("relationship-explorer-results")).toHaveTextContent("1 account")
    expect(screen.getByText(/Showing the first 20 accounts/)).toBeVisible()
  })

  it("applies bounded filters and navigates between selected accounts", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => response(selectedCedar))
    vi.stubGlobal("fetch", fetchMock)
    renderExplorer()
    await screen.findByTestId("relationship-explorer-results")

    fireEvent.change(screen.getByLabelText("Search accounts or contacts"), { target: { value: "Vega" } })
    fireEvent.change(screen.getByLabelText("Plan"), { target: { value: "Enterprise" } })
    fireEvent.change(screen.getByLabelText("Region"), { target: { value: "Central" } })
    fireEvent.change(screen.getByLabelText("Relationship role"), { target: { value: "Executive sponsor" } })
    fireEvent.click(screen.getByRole("button", { name: "Apply filters" }))

    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(
      expect.stringContaining("relationship_role=Executive+sponsor"),
      expect.anything()
    ))
    expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("query=Vega"), expect.anything())

    fireEvent.click(screen.getByRole("button", { name: /Cedar Ridge Health/ }))
    await waitFor(() => expect(fetchMock).toHaveBeenLastCalledWith(expect.stringContaining("selected_id=2"), expect.anything()))
    expect(await screen.findByRole("link", { name: "Cedar Ridge Health" })).toHaveAttribute("href", "/admin/accounts/2")
  })

  it("renders the empty state", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response(empty)))
    renderExplorer()

    expect(await screen.findByTestId("relationship-explorer-empty")).toHaveTextContent("No account or contact relationships")
  })

  it("renders endpoint and unknown errors and retries", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response({ error: "Region is invalid" }, false))
      .mockRejectedValueOnce("unknown")
      .mockImplementationOnce(() => response(populated))
    vi.stubGlobal("fetch", fetchMock)
    renderExplorer()

    expect(await screen.findByRole("alert")).toHaveTextContent("Region is invalid")
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Relationships could not be loaded"))
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    expect(await screen.findByTestId("relationship-explorer-results")).toBeVisible()
  })

  it("uses a safe unsuccessful-response fallback", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response({}, false)))
    renderExplorer()

    expect(await screen.findByRole("alert")).toHaveTextContent("Relationships could not be loaded")
  })

  it("times out a bounded search", async () => {
    vi.useFakeTimers()
    vi.stubGlobal("fetch", vi.fn((_url, options: RequestInit) => new Promise((_resolve, reject) => {
      options.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
    })))
    renderExplorer()

    await act(async () => vi.advanceTimersByTime(8_000))

    expect(screen.getByRole("alert")).toHaveTextContent("Relationship search timed out")
  })

  it("aborts an active request without publishing an unmount error", async () => {
    const abortSpy = vi.spyOn(AbortController.prototype, "abort")
    vi.stubGlobal("fetch", vi.fn((_url, options: RequestInit) => new Promise((_resolve, reject) => {
      options.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
    })))
    const { unmount } = renderExplorer()

    unmount()

    expect(abortSpy).toHaveBeenCalledOnce()
    await act(async () => Promise.resolve())
  })

  it("ignores a response that arrives after unmount", async () => {
    let resolveFetch: ((value: Response) => void) | undefined
    vi.stubGlobal("fetch", vi.fn(() => new Promise<Response>((resolve) => {
      resolveFetch = resolve
    })))
    const { unmount } = renderExplorer()

    unmount()
    await act(async () => {
      resolveFetch?.({ json: () => Promise.resolve(populated), ok: true } as Response)
      await Promise.resolve()
    })
  })
})
