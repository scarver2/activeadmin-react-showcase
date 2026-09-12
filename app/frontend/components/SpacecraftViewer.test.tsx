// app/frontend/components/SpacecraftViewer.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const state = vi.hoisted(() => ({ failLoad: false, frame: null as Function | null, hit: "port-wing", rootFactory: null as Function | null, throwRenderer: false, renderer: null as any, controls: [] as any[] }))
vi.mock("three", () => {
  class Object3D { children = [{ name: "fuselage", position: { z: 0 } }, { name: "port-wing", position: { z: 0 } }, { name: "starboard-wing", position: { z: 0 } }]; add = vi.fn(); traverse(callback: Function) { callback({}); const first = new Mesh(); callback(first); const second = new Mesh(); second.material = [second.material]; callback(second) } }
  class Mesh { name = ""; parent = { name: state.hit }; geometry = { dispose: vi.fn() }; material: any = { dispose: vi.fn() } }
  class WebGLRenderer { dispose = vi.fn(); render = vi.fn(); setPixelRatio = vi.fn(); setSize = vi.fn(); outputColorSpace = ""; constructor() { if (state.throwRenderer) throw new Error("WebGL unavailable"); state.renderer = this } }
  class PerspectiveCamera { position = { set: vi.fn() }; lookAt = vi.fn() }
  class Scene extends Object3D { background: unknown }
  class Light { position = { set: vi.fn() } }
  class Box3 { setFromObject() { return this } getCenter(target: unknown) { return target } }
  class Raycaster { setFromCamera = vi.fn(); intersectObject() { return state.hit ? [{ object: { name: "", parent: { name: state.hit } } }] : [] } }
  class Vector2 { set = vi.fn() }
  class Vector3 {}
  state.rootFactory = () => new Object3D()
  return { AmbientLight: Light, Box3, Color: class Color {}, DirectionalLight: Light, Mesh, Object3D, PerspectiveCamera, Raycaster, Scene, SRGBColorSpace: "srgb", Vector2, Vector3, WebGLRenderer }
})
vi.mock("three/examples/jsm/controls/OrbitControls.js", () => ({ OrbitControls: class OrbitControls { dispose = vi.fn(); enableDamping = false; target = {}; update = vi.fn(); constructor() { state.controls.push(this) } } }))
vi.mock("three/examples/jsm/loaders/GLTFLoader.js", () => ({ GLTFLoader: class GLTFLoader { load(_url: string, success: Function, _progress: unknown, failure: Function) { if (state.failLoad) failure(); else success({ scene: state.rootFactory!() }) } } }))

import SpacecraftViewer from "./SpacecraftViewer"

const components = [{ dimensions: "8m", id: "fuselage", material: "Titanium", name: "Fuselage", notes: "Vessel", partNumber: "ODY-100", status: "ready" }, { dimensions: "4m", id: "port-wing", material: "Composite", name: "Port wing", notes: "Wing", partNumber: "ODY-210-L", status: "due" }]
const model = { assetUrl: "/models/odyssey.gltf", components, finish: "titanium", finishes: ["titanium", "ceramic"], id: "1", lockVersion: 0, name: "Odyssey", selectedComponentId: "fuselage", updateUrl: "/spacecraft/1" }
const response = (body: object, ok = true) => Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)

beforeEach(() => { state.failLoad = false; state.frame = null; state.hit = "port-wing"; state.throwRenderer = false; vi.stubGlobal("requestAnimationFrame", vi.fn((callback: Function) => { state.frame = callback; return 7 })); vi.stubGlobal("cancelAnimationFrame", vi.fn()); vi.stubGlobal("matchMedia", vi.fn(() => ({ matches: false } as MediaQueryList))) })
afterEach(() => { vi.unstubAllGlobals(); vi.restoreAllMocks() })

describe("SpacecraftViewer", () => {
  it("loads, selects by raycast and keyboard, controls cameras/explode, persists, and disposes", async () => {
    const canonical = { ...model, finish: "ceramic", lockVersion: 1, selectedComponentId: "port-wing" }
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ model: canonical }))
    const { unmount } = render(<SpacecraftViewer model={model} />)
    expect(screen.getByLabelText("Interactive Odyssey spacecraft")).toHaveAttribute("data-render-state", "ready")
    fireEvent.pointerUp(screen.getByLabelText("Interactive Odyssey spacecraft"), { clientX: 1, clientY: 1 })
    expect(screen.getByRole("region", { name: "Selected component" })).toHaveTextContent("Port wing")
    await userEvent.click(screen.getByRole("button", { name: "Front camera" })); await userEvent.click(screen.getByRole("button", { name: "Top camera" })); await userEvent.click(screen.getByRole("button", { name: "Reset camera" }))
    await userEvent.click(screen.getByRole("button", { name: "Exploded view" })); await userEvent.click(screen.getByRole("button", { name: "Exploded view" }))
    await userEvent.click(screen.getByRole("button", { name: "Port wing" }))
    await userEvent.selectOptions(screen.getByLabelText("Finish"), "ceramic")
    await waitFor(() => expect(fetch).toHaveBeenCalled())
    unmount(); expect(state.renderer.dispose).toHaveBeenCalled(); expect(cancelAnimationFrame).toHaveBeenCalledWith(7); state.frame!()
  })
  it("rolls back explicit and default persistence failures", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValueOnce(response({ error: "Stale" }, false)).mockReturnValueOnce(response({}, false))
    render(<SpacecraftViewer model={model} />)
    await userEvent.selectOptions(screen.getByLabelText("Finish"), "ceramic")
    expect(await screen.findByRole("alert")).toHaveTextContent("Stale")
    await userEvent.click(screen.getByRole("button", { name: "Port wing" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Configuration could not be saved")
  })
  it("falls back for model failure, context loss, WebGL initialization, missing selection, and missed raycasts", () => {
    state.failLoad = true
    const { unmount } = render(<SpacecraftViewer model={{ ...model, selectedComponentId: "missing" }} />)
    expect(screen.getByRole("alert")).toHaveTextContent("local spacecraft model")
    expect(screen.getByText("Select a component.")).toBeVisible()
    fireEvent(screen.getByLabelText("Interactive Odyssey spacecraft"), new Event("webglcontextlost", { cancelable: true }))
    expect(screen.getByRole("alert")).toHaveTextContent("context was lost")
    state.hit = ""; fireEvent.pointerUp(screen.getByLabelText("Interactive Odyssey spacecraft")); unmount()
    state.throwRenderer = true
    render(<SpacecraftViewer model={model} />)
    expect(screen.getByRole("alert")).toHaveTextContent("WebGL unavailable")
    fireEvent.click(screen.getByRole("button", { name: "Front camera" })); fireEvent.click(screen.getByRole("button", { name: "Exploded view" }))
  })
})
