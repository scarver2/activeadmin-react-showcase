// app/frontend/components/CommandPalette.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"

import CommandPalette from "./CommandPalette"

const results = [
  { description: "Enterprise · Central · Active", id: "account-1", kind: "Account", label: "Bluebonnet Logistics", url: "/admin/accounts/1" },
  { description: "Rails-owned content", id: "article-2", kind: "Article", label: "Bluebonnet field guide", url: "/admin/showcase_articles/2" }
]

function response(body: unknown, ok = true) {
  return Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)
}

function openPalette() {
  fireEvent.click(screen.getByRole("button", { name: /Open command palette/ }))
  return screen.getByRole("combobox", { name: "Search accounts and articles" })
}

describe("CommandPalette", () => {
  afterEach(() => vi.restoreAllMocks())

  it("opens from both platform shortcuts, manages focus, and dismisses accessibly", () => {
    const { unmount } = render(<CommandPalette endpoint="/search" />)
    fireEvent.keyDown(document, { ctrlKey: true, key: "x" })
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()

    fireEvent.keyDown(document, { ctrlKey: true, key: "K" })
    expect(screen.getByRole("dialog")).toBeVisible()
    expect(screen.getByRole("combobox")).toHaveFocus()
    fireEvent.keyDown(screen.getByRole("combobox"), { key: "Escape" })
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    expect(screen.getByRole("button", { name: /Open command palette/ })).toHaveFocus()

    fireEvent.keyDown(document, { key: "k", metaKey: true })
    fireEvent.mouseDown(screen.getByRole("dialog"))
    expect(screen.getByRole("dialog")).toBeVisible()
    fireEvent.mouseDown(screen.getByTestId("command-palette-backdrop"))
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()

    openPalette()
    fireEvent.click(screen.getByRole("button", { name: "Close command palette" }))
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    unmount()
    fireEvent.keyDown(document, { ctrlKey: true, key: "k" })
  })

  it("renders authorized results and supports wrapped arrow and Enter navigation", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response({ query: "blue", results })))
    const click = vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(() => undefined)
    render(<CommandPalette endpoint="/search" initialQuery="blue" />)
    const query = openPalette()

    fireEvent.submit(screen.getByRole("search"))
    expect(screen.getByRole("status")).toHaveTextContent("Searching authorized records")
    const listbox = await screen.findByRole("listbox", { name: "Search results" })
    expect(listbox).toHaveTextContent("Bluebonnet Logistics")
    expect(screen.getByRole("link", { name: /Bluebonnet Logistics/ })).toHaveAttribute("href", "/admin/accounts/1")

    fireEvent.keyDown(query, { key: "ArrowDown" })
    expect(query).toHaveAttribute("aria-activedescendant", "command-result-article-2")
    fireEvent.keyDown(query, { key: "ArrowUp" })
    expect(query).toHaveAttribute("aria-activedescendant", "command-result-account-1")
    fireEvent.keyDown(query, { key: "ArrowUp" })
    expect(query).toHaveAttribute("aria-activedescendant", "command-result-article-2")
    fireEvent.keyDown(query, { key: "Enter" })
    expect(click).toHaveBeenCalledOnce()
  })

  it("keeps blank searches idle and presents empty successful searches", async () => {
    const fetchMock = vi.fn(() => response({}))
    vi.stubGlobal("fetch", fetchMock)
    render(<CommandPalette endpoint="/search" />)
    const query = openPalette()

    fireEvent.submit(screen.getByRole("search"))
    expect(fetchMock).not.toHaveBeenCalled()
    expect(screen.getByText("Enter a term to search authorized records.")).toBeVisible()

    fireEvent.change(query, { target: { value: "missing" } })
    fireEvent.submit(screen.getByRole("search"))
    expect(await screen.findByTestId("command-palette-empty")).toHaveTextContent("missing")
    fireEvent.keyDown(query, { key: "ArrowDown" })
    fireEvent.keyDown(query, { key: "ArrowUp" })
    fireEvent.keyDown(query, { key: "Enter" })
  })

  it("presents endpoint and network errors and retries", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response({ error: "Query is invalid" }, false))
      .mockImplementationOnce(() => response({}, false))
      .mockRejectedValueOnce("offline")
      .mockImplementationOnce(() => response({ results }))
    vi.stubGlobal("fetch", fetchMock)
    render(<CommandPalette endpoint="/search" />)
    const query = openPalette()
    fireEvent.change(query, { target: { value: "blue" } })

    fireEvent.submit(screen.getByRole("search"))
    expect(await screen.findByRole("alert")).toHaveTextContent("Query is invalid")
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Search could not be completed"))
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
    expect(screen.getByRole("alert")).toHaveTextContent("Search could not be completed")
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))
    expect(await screen.findByRole("listbox")).toBeVisible()
  })
})
