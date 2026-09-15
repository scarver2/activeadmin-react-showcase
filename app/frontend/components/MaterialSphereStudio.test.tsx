// app/frontend/components/MaterialSphereStudio.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const state = vi.hoisted(() => ({ frame: null as Function | null, reducedMotion: false, renderer: null as any, throwRenderer: false }))
vi.mock("three", () => {
  class Position { set = vi.fn() }
  class Color { copy = vi.fn(); constructor(_value?: string) {} }
  class Geometry { dispose = vi.fn() }
  class Material { clearcoat = 0; color = new Color(); dispose = vi.fn(); metalness = 0; needsUpdate = false; roughness = 0; constructor(values: Record<string, unknown> = {}) { Object.assign(this, values); this.color = new Color(values.color as string | undefined) } }
  class Mesh { geometry: Geometry; material: Material; position = { y: 0 }; rotation = { x: 0 }; constructor(geometry: Geometry, material: Material) { this.geometry = geometry; this.material = material } }
  class Scene { background: unknown; add = vi.fn() }
  class Light { position = new Position() }
  class Camera { position = new Position(); lookAt = vi.fn() }
  class Vector3 { copy = vi.fn(); constructor(_x?: number, _y?: number, _z?: number) {} }
  class WebGLRenderer { dispose = vi.fn(); render = vi.fn(); setPixelRatio = vi.fn(); setSize = vi.fn(); outputColorSpace = ""; toneMapping = 0; toneMappingExposure = 0; constructor() { if (state.throwRenderer) throw new Error("WebGL unavailable"); state.renderer = this } }
  return { ACESFilmicToneMapping: 4, AmbientLight: Light, CircleGeometry: Geometry, Color, DirectionalLight: Light, Mesh, MeshPhysicalMaterial: Material, MeshStandardMaterial: Material, PerspectiveCamera: Camera, Scene, SphereGeometry: Geometry, SRGBColorSpace: "srgb", Vector3, WebGLRenderer }
})
vi.mock("three/examples/jsm/controls/OrbitControls.js", () => ({ OrbitControls: class OrbitControls { dispose = vi.fn(); enableDamping = false; enablePan = true; maxDistance = 0; minDistance = 0; target = { copy: vi.fn() }; update = vi.fn() } }))

import MaterialSphereStudio from "./MaterialSphereStudio"

const finishes = [
  { clearcoat: 1, color: "#d20a2e", id: "candy-red", label: "Candy red", metalness: 0.12, roughness: 0.08 },
  { clearcoat: 0.9, color: "#b5082d", id: "ruby-metal", label: "Ruby metal", metalness: 0.72, roughness: 0.14 },
  { clearcoat: 0.65, color: "#e11d48", id: "soft-red", label: "Soft red", metalness: 0, roughness: 0.32 },
]
const model = { finish: "candy-red", finishes, id: "1", lockVersion: 0, name: "Glossy red material sphere", updateUrl: "/material-sphere/1" }
const response = (body: object, ok = true) => Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)

beforeEach(() => { state.frame = null; state.reducedMotion = false; state.throwRenderer = false; vi.stubGlobal("requestAnimationFrame", vi.fn((callback: Function) => { state.frame = callback; return 7 })); vi.stubGlobal("cancelAnimationFrame", vi.fn()); vi.stubGlobal("matchMedia", vi.fn(() => ({ matches: state.reducedMotion } as MediaQueryList))) })
afterEach(() => { vi.unstubAllGlobals(); vi.restoreAllMocks() })

describe("MaterialSphereStudio", () => {
  it("renders the procedural sphere, controls cameras, persists recipes, and disposes", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ model: { ...model, finish: "ruby-metal", lockVersion: 1 } }))
    const { unmount } = render(<MaterialSphereStudio model={model} />)
    expect(screen.getByLabelText("Interactive glossy red material sphere")).toHaveAttribute("data-render-state", "ready")
    await userEvent.click(screen.getByRole("button", { name: "Front view" })); await userEvent.click(screen.getByRole("button", { name: "Highlight detail" })); await userEvent.click(screen.getByRole("button", { name: "Reset camera" }))
    await userEvent.selectOptions(screen.getByLabelText("Red finish"), "ruby-metal")
    await waitFor(() => expect(screen.getByLabelText("Red finish")).toHaveValue("ruby-metal"))
    expect(screen.getByRole("region", { name: "Material recipe" })).toHaveTextContent("0.14")
    unmount(); expect(state.renderer.dispose).toHaveBeenCalled(); expect(cancelAnimationFrame).toHaveBeenCalledWith(7); state.frame!()
  })

  it("rolls back failed persistence and surfaces canonical errors", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValueOnce(response({ error: "Stale material recipe" }, false)).mockReturnValueOnce(response({}, false))
    render(<MaterialSphereStudio model={model} />)
    await userEvent.selectOptions(screen.getByLabelText("Red finish"), "ruby-metal")
    expect(await screen.findByRole("alert")).toHaveTextContent("Stale material recipe")
    expect(screen.getByLabelText("Red finish")).toHaveValue("candy-red")
    await userEvent.selectOptions(screen.getByLabelText("Red finish"), "soft-red")
    expect(await screen.findByRole("alert")).toHaveTextContent("Material recipe could not be saved")
  })

  it("respects reduced motion and handles context loss and WebGL initialization failure", () => {
    state.reducedMotion = true
    const { unmount } = render(<MaterialSphereStudio model={model} />)
    fireEvent(screen.getByLabelText("Interactive glossy red material sphere"), new Event("webglcontextlost", { cancelable: true }))
    expect(screen.getByRole("alert")).toHaveTextContent("context was lost")
    unmount(); state.throwRenderer = true
    render(<MaterialSphereStudio model={model} />)
    expect(screen.getByRole("alert")).toHaveTextContent("WebGL unavailable")
    fireEvent.click(screen.getByRole("button", { name: "Front view" }))
  })
})
