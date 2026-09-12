// app/frontend/components/GeospatialExplorer.test.tsx

import { act, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

const state = vi.hoisted(() => ({ instances: [] as any[], missingSource: false }))
vi.mock("maplibre-gl", () => {
  class Map {
    handlers: Record<string, Function[]> = {}
    source = { setData: vi.fn() }
    constructor(public options: object) { state.instances.push(this) }
    addControl = vi.fn()
    addLayer = vi.fn()
    addSource = vi.fn()
    flyTo = vi.fn()
    getBounds = () => ({ getEast: () => -95, getNorth: () => 32, getSouth: () => 28, getWest: () => -100 })
    getSource = () => state.missingSource ? undefined : this.source
    on(event: string, layerOrHandler: string | Function, possible?: Function) {
      const handler = typeof layerOrHandler === "function" ? layerOrHandler : possible!
      this.handlers[event] ||= []
      this.handlers[event].push(handler)
    }
    remove = vi.fn()
    emit(event: string, payload?: object) { this.handlers[event]?.forEach((handler) => handler(payload)) }
  }
  return { Map, NavigationControl: class NavigationControl {} }
})

import GeospatialExplorer from "./GeospatialExplorer"

const first = { category: "Workshop", id: "1", latitude: 30.2, longitude: -97.7, name: "Austin Workshop", summary: "Fabrication", url: "/admin/showcase_locations/1" }
const second = { ...first, id: "2", name: "Taylor Hangar", summary: "Assembly" }
const response = (body: object, ok = true) => Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)

afterEach(() => { state.instances.length = 0; state.missingSource = false; vi.restoreAllMocks() })

describe("GeospatialExplorer", () => {
  it("initializes, clusters, selects from list and map, refreshes viewport, and disposes", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockReturnValue(response({ locations: [second] }))
    const { unmount } = render(<GeospatialExplorer endpoint="/locations" initialLocations={[first, second]} />)
    const map = state.instances[0]
    act(() => map.emit("load"))
    expect(map.addSource).toHaveBeenCalledWith("locations", expect.objectContaining({ cluster: true }))
    await userEvent.click(screen.getByRole("button", { name: "Taylor Hangar" }))
    expect(map.flyTo).toHaveBeenCalled()
    act(() => map.emit("click", { features: [{ properties: { id: "1" } }] }))
    expect(screen.getByRole("region", { name: "Selected location" })).toHaveTextContent("Austin Workshop")
    act(() => map.emit("click", { features: [] }))
    await userEvent.click(screen.getByRole("button", { name: "Taylor Hangar" }))
    act(() => map.emit("moveend"))
    expect(screen.getByRole("status")).toHaveTextContent("Loading viewport")
    await waitFor(() => expect(fetchMock).toHaveBeenCalled())
    expect(await screen.findByRole("button", { name: "Taylor Hangar" })).toHaveAttribute("aria-pressed", "true")
    expect(map.source.setData).toHaveBeenCalled()
    unmount()
    expect(map.remove).toHaveBeenCalled()
  })

  it("renders empty viewport and default server errors", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValueOnce(response({})).mockReturnValueOnce(response({}, false))
    const { unmount } = render(<GeospatialExplorer endpoint="/locations" initialLocations={[]} />)
    expect(screen.getByText("Select a location from the list or map.")).toBeVisible()
    act(() => state.instances.at(-1).emit("moveend"))
    expect(await screen.findByText("No locations in this region.")).toBeVisible()
    unmount()
    render(<GeospatialExplorer endpoint="/locations" initialLocations={[first]} />)
    act(() => state.instances.at(-1).emit("moveend"))
    expect(await screen.findByRole("alert")).toHaveTextContent("Locations could not be loaded")
  })

  it("reports explicit errors but ignores aborts and post-unmount completion", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValueOnce(response({ error: "Window rejected" }, false))
    render(<GeospatialExplorer endpoint="/locations" initialLocations={[first]} />)
    act(() => state.instances[0].emit("moveend"))
    expect(await screen.findByRole("alert")).toHaveTextContent("Window rejected")

    let reject!: (reason: Error) => void
    vi.spyOn(globalThis, "fetch").mockReturnValue(new Promise((_resolve, rejectPromise) => { reject = rejectPromise }))
    const { unmount } = render(<GeospatialExplorer endpoint="/other" initialLocations={[first]} />)
    act(() => state.instances[1].emit("moveend"))
    unmount()
    await act(async () => reject(Object.assign(new Error("aborted"), { name: "AbortError" })))
  })

  it("accepts viewport data before the map source is ready", async () => {
    state.missingSource = true
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ locations: [first] }))
    render(<GeospatialExplorer endpoint="/locations" initialLocations={[first]} />)
    act(() => state.instances[0].emit("moveend"))
    expect(await screen.findByRole("button", { name: "Austin Workshop" })).toBeVisible()
  })
})
