// app/frontend/components/HierarchyExplorer.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import HierarchyExplorer from "./HierarchyExplorer"

const root = {
  breadcrumbs: [], childCount: 1, childrenUrl: "/admin/hierarchy_nodes?parent_id=1",
  id: "1", lockVersion: 0, moveUrl: "/admin/hierarchy_nodes/1", title: "Showcase Company"
}
const child = {
  breadcrumbs: [{ id: "1", title: "Showcase Company" }], childCount: 1,
  childrenUrl: "/admin/hierarchy_nodes?parent_id=2", id: "2", lockVersion: 0,
  moveUrl: "/admin/hierarchy_nodes/2", title: "Engineering"
}
const grandchild = {
  breadcrumbs: [{ id: "1", title: root.title }, { id: "2", title: child.title }], childCount: 0,
  childrenUrl: "/admin/hierarchy_nodes?parent_id=4", id: "4", lockVersion: 0,
  moveUrl: "/admin/hierarchy_nodes/4", title: "Platform"
}
const sibling = {
  breadcrumbs: [], childCount: 0, childrenUrl: "/admin/hierarchy_nodes?parent_id=3",
  id: "3", lockVersion: 0, moveUrl: "/admin/hierarchy_nodes/3", title: "Studio"
}

function response(body: object, ok = true) {
  return Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)
}

afterEach(() => {
  document.head.innerHTML = ""
  vi.restoreAllMocks()
})

describe("HierarchyExplorer", () => {
  it("loads children lazily, renders empty branches, collapses, and shows breadcrumbs", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ nodes: [child] }))
    const user = userEvent.setup()
    render(<HierarchyExplorer roots={[root]} />)

    await user.click(screen.getByRole("button", { name: "Expand Showcase Company" }))
    expect(await screen.findByRole("button", { name: "Engineering" })).toBeVisible()
    expect(fetch).toHaveBeenCalledWith(root.childrenUrl, expect.any(Object))
    await user.click(screen.getByRole("button", { name: "Engineering" }))
    expect(screen.getByRole("navigation", { name: "Selected node breadcrumbs" })).toHaveTextContent("Showcase Company / Engineering")
    await user.click(screen.getByRole("button", { name: "Collapse Showcase Company" }))
    expect(screen.queryByRole("button", { name: "Engineering" })).not.toBeInTheDocument()
  })

  it("reports a child-loading error and restores the collapsed branch", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ error: "Unavailable" }, false))
    render(<HierarchyExplorer roots={[root]} />)

    await userEvent.click(screen.getByRole("button", { name: "Expand Showcase Company" }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Unavailable")
    expect(screen.getByRole("button", { name: "Expand Showcase Company" })).toBeVisible()
  })

  it("moves a selected node with a keyboard control and accepts the canonical response", async () => {
    const moved = { ...sibling, breadcrumbs: [{ id: "1", title: root.title }], lockVersion: 1 }
    vi.spyOn(globalThis, "fetch")
      .mockReturnValueOnce(response({ nodes: [child] }))
      .mockReturnValueOnce(response({ nodes: [grandchild] }))
      .mockReturnValueOnce(response({ node: moved }))
    const user = userEvent.setup()
    document.head.innerHTML = '<meta name="csrf-token" content="test-token">'
    render(<HierarchyExplorer roots={[root, sibling]} />)

    await user.click(screen.getByRole("button", { name: "Expand Showcase Company" }))
    await user.click(await screen.findByRole("button", { name: "Expand Engineering" }))
    expect(await screen.findByRole("button", { name: "Platform" })).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Studio" }))
    await user.click(screen.getAllByRole("button", { name: "Move Studio here" })[0])

    await waitFor(() => expect(fetch).toHaveBeenCalledWith(sibling.moveUrl, expect.objectContaining({ method: "PATCH" })))
    expect(screen.getByRole("treeitem", { name: /Showcase Company/ })).toHaveTextContent("Studio")
    expect(screen.getByRole("navigation", { name: "Selected node breadcrumbs" })).toHaveTextContent("Showcase Company / Studio")
  })

  it("supports pointer drag and restores the prior tree after rejection", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ error: "Cycle rejected" }, false))
    render(<HierarchyExplorer roots={[root, sibling]} />)

    fireEvent.dragStart(screen.getByRole("treeitem", { name: /Studio/ }))
    fireEvent.dragOver(screen.getByRole("treeitem", { name: /Showcase Company/ }))
    fireEvent.drop(screen.getByRole("treeitem", { name: /Showcase Company/ }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Cycle rejected. The tree was restored.")
    expect(screen.getAllByRole("treeitem")).toHaveLength(2)
  })

  it("renders an empty hierarchy", () => {
    render(<HierarchyExplorer roots={[]} />)
    expect(screen.getByText("Empty branch")).toBeVisible()
  })

  it("restores a move when a successful response omits its canonical node", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({}))
    const user = userEvent.setup()
    render(<HierarchyExplorer roots={[root, sibling]} />)

    await user.click(screen.getByRole("button", { name: "Studio" }))
    await user.click(screen.getByRole("button", { name: "Move Studio here" }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Hierarchy move failed. The tree was restored.")
  })

  it("accepts a move into a branch whose children have not loaded", async () => {
    const moved = { ...sibling, breadcrumbs: [{ id: "1", title: root.title }], lockVersion: 1 }
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ node: moved }))
    const user = userEvent.setup()
    render(<HierarchyExplorer roots={[root, sibling]} />)

    await user.click(screen.getByRole("button", { name: "Studio" }))
    await user.click(screen.getByRole("button", { name: "Move Studio here" }))

    expect(await screen.findByRole("navigation", { name: "Selected node breadcrumbs" })).toHaveTextContent("Studio")
  })

  it("covers empty child payloads, default failures, cached expansion, and self drops", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockReturnValueOnce(response({}))
      .mockReturnValueOnce(response({}, false))
    const user = userEvent.setup()
    render(<HierarchyExplorer roots={[root, sibling]} />)

    await user.click(screen.getByRole("button", { name: "Expand Showcase Company" }))
    expect(await screen.findByText("Empty branch")).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Collapse Showcase Company" }))
    await user.click(screen.getByRole("button", { name: "Expand Showcase Company" }))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    fireEvent.drop(screen.getByRole("treeitem", { name: /Studio/ }))
    fireEvent.dragStart(screen.getByRole("treeitem", { name: /Studio/ }))
    fireEvent.drop(screen.getByRole("treeitem", { name: /Studio/ }))
    expect(fetchMock).toHaveBeenCalledTimes(1)

    await user.click(screen.getByRole("button", { name: "Collapse Showcase Company" }))
    // Re-rendering with an uncached expandable node exercises the default fetch error.
    render(<HierarchyExplorer roots={[{ ...root, id: "9", childrenUrl: "/missing" }]} />)
    await user.click(screen.getAllByRole("button", { name: "Expand Showcase Company" }).at(-1)!)
    expect(await screen.findByText("Children could not be loaded")).toBeVisible()
  })
})
