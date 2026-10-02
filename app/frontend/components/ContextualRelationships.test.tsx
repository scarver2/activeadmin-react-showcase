// app/frontend/components/ContextualRelationships.test.tsx

import { act, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { vi } from "vitest"

const state = vi.hoisted(() => ({ handler: null as any, resizeHandler: null as any, destroy: vi.fn(), resize: vi.fn(), fit: vi.fn(), disconnect: vi.fn() }))
vi.mock("cytoscape", () => ({ default: vi.fn(() => ({ on: (_type: string, _selector: string, handler: any) => { state.handler = handler }, destroy: state.destroy, resize: state.resize, fit: state.fit })) }))
vi.stubGlobal("ResizeObserver", class { constructor(callback: any) { state.resizeHandler = callback } observe() {} disconnect() { state.disconnect() } })
import ContextualRelationships from "./ContextualRelationships"

const nodes = [
  { id: "customer", kind: "Customer", name: "Juniper", detail: "Customer context", url: "/source/customer", exploreUrl: "/explore/customer" },
  { id: "order", kind: "Order", name: "Crates", detail: "Order context", url: "/source/order", exploreUrl: "/explore/order" }
]
const props = { rootId: "customer", nodes, edges: [{ id: "edge", source: "customer", target: "order", label: "placed" }], bounded: false }

it("selects via keyboard and graph while preserving Rails destinations and disposing the graph", async () => {
  const { unmount } = render(<ContextualRelationships {...props} />)
  expect(screen.getByRole("region", { name: "Selected context" })).toHaveTextContent("Customer context")
  expect(screen.getByText("Juniper → placed → Crates")).toBeVisible()
  await userEvent.click(screen.getByRole("button", { name: "Order: Crates" }))
  expect(screen.getByRole("link", { name: "Open source record" })).toHaveAttribute("href", "/source/order")
  expect(screen.getByRole("link", { name: "Explore from this record" })).toHaveAttribute("href", "/explore/order")
  act(() => state.handler({ target: { id: () => "customer" } }))
  expect(screen.getByRole("region", { name: "Selected context" })).toHaveTextContent("Customer context")
  act(() => state.handler({ target: { id: () => "missing" } }))
  expect(screen.getByText("Select an available record from the list.")).toBeVisible()
  act(() => state.resizeHandler())
  expect(state.resize).toHaveBeenCalled()
  expect(state.fit).toHaveBeenCalled()
  unmount()
  expect(state.disconnect).toHaveBeenCalled()
  expect(state.destroy).toHaveBeenCalled()
})

it("announces the bounded context and retains an accessible record list", () => {
  render(<ContextualRelationships {...props} bounded />)
  expect(screen.getByRole("status")).toHaveTextContent("Context limit reached")
  expect(screen.getByRole("link", { name: "Open Juniper" })).toHaveAttribute("href", "/source/customer")
})
