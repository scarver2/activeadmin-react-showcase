// app/frontend/components/SocialGraphExplorer.test.tsx

import { act, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

const state = vi.hoisted(() => ({ instances: [] as any[] }))
vi.mock("cytoscape", () => ({ default: vi.fn((options: object) => { const instance = { addClass: vi.fn(), destroy: vi.fn(), fit: vi.fn(), getElementById: vi.fn(() => ({ addClass: instance.addClass })), handler: null as Function | null, on: vi.fn((_event: string, _selector: string, handler: Function) => { instance.handler = handler }), options }; state.instances.push(instance); return instance }) }))
import SocialGraphExplorer from "./SocialGraphExplorer"

const people = [{ id: "1", name: "Avery" }, { id: "2", name: "Diego" }, { id: "3", name: "Priya" }]
const node = (id: string, name: string, degree: number | null = 0) => ({ degree, headline: `${name} role`, id, name, url: `/people/${id}` })
const graph = { edges: [{ id: "1-2", source: "1", target: "2" }], mutuals: [node("3", "Priya", null)], nodes: [node("1", "Avery"), node("2", "Diego", 1)], path: ["1", "2"] }
const response = (body: object, ok = true) => Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)
afterEach(() => { state.instances.length = 0; vi.restoreAllMocks() })

describe("SocialGraphExplorer", () => {
  it("creates, highlights, selects, fits, changes depth/root/target, and disposes", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockReturnValue(response(graph))
    const { unmount } = render(<SocialGraphExplorer endpoint="/graph" graph={graph} people={people} rootId="1" />)
    const instance = state.instances[0]
    expect(instance.addClass).toHaveBeenCalledTimes(2)
    act(() => instance.handler({ target: { id: () => "2" } }))
    expect(screen.getByRole("region", { name: "Selected person" })).toHaveTextContent("Diego role")
    await userEvent.click(screen.getByRole("button", { name: "Fit graph" }))
    expect(instance.fit).toHaveBeenCalled()
    await userEvent.click(screen.getByRole("button", { name: "Avery" }))
    await userEvent.click(screen.getByRole("button", { name: "2 degrees" }))
    await userEvent.selectOptions(screen.getByLabelText("Start"), "2")
    await userEvent.selectOptions(screen.getByLabelText("Target"), "3")
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
    unmount()
    expect(state.instances.at(-1).destroy).toHaveBeenCalled()
  })
  it("renders disconnected/empty projections and explicit/default errors", async () => {
    const empty = { edges: [], mutuals: [], nodes: [], path: [] }
    vi.spyOn(globalThis, "fetch").mockReturnValueOnce(response({ ...empty, error: "Depth rejected" }, false)).mockReturnValueOnce(response({}, false))
    render(<SocialGraphExplorer endpoint="/graph" graph={empty} people={people} rootId="1" />)
    expect(screen.getByText("No connected people.")).toBeVisible()
    expect(screen.getByText("No path within three degrees.")).toBeVisible()
    expect(screen.getByText("None")).toBeVisible()
    expect(screen.getByText("Select a person.")).toBeVisible()
    await userEvent.click(screen.getByRole("button", { name: "3 degrees" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Depth rejected")
    await userEvent.click(screen.getByRole("button", { name: "1 degree" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Graph could not be loaded")
  })
  it("uses an id when a path node is absent from the people projection", () => {
    render(<SocialGraphExplorer endpoint="/graph" graph={{ ...graph, path: ["missing"] }} people={people} rootId="1" />)
    expect(screen.getByText("missing")).toBeVisible()
  })
  it("defaults the target to the root when it is the only person", () => {
    render(<SocialGraphExplorer endpoint="/graph" graph={{ ...graph, path: [] }} people={[people[0]]} rootId="1" />)
    expect(screen.getByLabelText("Target")).toHaveValue("1")
  })
})
