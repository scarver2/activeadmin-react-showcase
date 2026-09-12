// app/frontend/components/SpacecraftViewer.tsx

import { AmbientLight, Box3, Color, DirectionalLight, Mesh, PerspectiveCamera, Raycaster, Scene, SRGBColorSpace, Vector2, Vector3, WebGLRenderer } from "three"
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import { useEffect, useRef, useState } from "react"

type ComponentMetadata = { dimensions: string, id: string, material: string, name: string, notes: string, partNumber: string, status: string }
type Model = { assetUrl: string, components: ComponentMetadata[], finish: string, finishes: string[], id: string, lockVersion: number, name: string, selectedComponentId: string, updateUrl: string }
export type SpacecraftViewerProps = { model: Model }
type ViewerApi = { dispose: () => void, explode: (enabled: boolean) => void, preset: (name: string) => void }

function csrfToken() { return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" }

export default function SpacecraftViewer({ model: initial }: SpacecraftViewerProps) {
  const canvas = useRef<HTMLCanvasElement>(null)
  const viewer = useRef<ViewerApi | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [exploded, setExploded] = useState(false)
  const [finish, setFinish] = useState(initial.finish)
  const [loading, setLoading] = useState(true)
  const [lockVersion, setLockVersion] = useState(initial.lockVersion)
  const [selectedId, setSelectedId] = useState(initial.selectedComponentId)
  const selected = initial.components.find((component) => component.id === selectedId)

  useEffect(() => {
    /* v8 ignore next -- React attaches the ref before running this effect. */
    if (!canvas.current) return
    try {
      viewer.current = createViewer(canvas.current, initial.assetUrl, setSelectedId, () => { setLoading(false) }, (message) => { setError(message); setLoading(false) })
    } catch (viewerError) { setError((viewerError as Error).message); setLoading(false) }
    return () => { viewer.current?.dispose(); viewer.current = null }
  }, [initial.assetUrl])

  async function persist(nextFinish = finish, nextSelected = selectedId) {
    setError(null)
    try {
      const response = await fetch(initial.updateUrl, { body: JSON.stringify({ lock_version: lockVersion, spacecraft: { finish: nextFinish, selected_component_id: nextSelected } }), credentials: "same-origin", headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() }, method: "PATCH" })
      const payload = await response.json() as { error?: string, model?: Model }
      if (!response.ok || !payload.model) throw new Error(payload.error || "Configuration could not be saved")
      setFinish(payload.model.finish); setSelectedId(payload.model.selectedComponentId); setLockVersion(payload.model.lockVersion)
    } catch (saveError) { setFinish(initial.finish); setSelectedId(initial.selectedComponentId); setError((saveError as Error).message) }
  }

  function toggleExploded() { const next = !exploded; setExploded(next); viewer.current?.explode(next) }
  return <section className="space-y-5" data-testid="spacecraft-viewer">
    {error && <p role="alert" className="text-red-700">{error}</p>}{loading && <p role="status">Loading local spacecraft model…</p>}
    <canvas aria-label="Interactive Odyssey spacecraft" className="h-96 w-full rounded bg-slate-950" data-render-state={loading ? "loading" : error ? "fallback" : "ready"} ref={canvas} />
    <div className="flex flex-wrap gap-2"><button onClick={() => viewer.current?.preset("front")} type="button">Front camera</button><button onClick={() => viewer.current?.preset("top")} type="button">Top camera</button><button onClick={() => viewer.current?.preset("reset")} type="button">Reset camera</button><button aria-pressed={exploded} onClick={toggleExploded} type="button">Exploded view</button></div>
    <div className="grid gap-4 lg:grid-cols-2"><section aria-label="Spacecraft components" className="rounded border p-4"><h3>Components</h3>{initial.components.map((component) => <button aria-pressed={component.id === selectedId} className="mr-2 underline" key={component.id} onClick={() => { setSelectedId(component.id); void persist(finish, component.id) }} type="button">{component.name}</button>)}</section><section aria-label="Selected component" className="rounded border p-4"><h3>Selected component</h3>{selected ? <dl><dt>Part</dt><dd>{selected.name} — {selected.partNumber}</dd><dt>Material</dt><dd>{selected.material}</dd><dt>Status</dt><dd>{selected.status}</dd><dt>Dimensions</dt><dd>{selected.dimensions}</dd><dt>Inspection notes</dt><dd>{selected.notes}</dd></dl> : <p>Select a component.</p>}<label>Finish<select value={finish} onChange={(event) => { setFinish(event.target.value); void persist(event.target.value) }}>{initial.finishes.map((value) => <option key={value}>{value}</option>)}</select></label></section></div>
    <div className="grid gap-4 lg:grid-cols-3"><Guidance title="Ruby">Rails owns identity, metadata, local asset URL, authorization, selection, and finish allowlists.</Guidance><Guidance title="JavaScript">Three.js owns bounded rendering, raycasting, camera controls, and exploded presentation.</Guidance><Guidance title="Architecture">The lazy, local, low-polygon glTF proves lifecycle-safe WebGL integration without a CAD abstraction.</Guidance></div>
  </section>
}

function createViewer(canvas: HTMLCanvasElement, assetUrl: string, select: (id: string) => void, ready: () => void, fail: (message: string) => void): ViewerApi {
  const renderer = new WebGLRenderer({ antialias: true, canvas, powerPreference: "high-performance" })
  renderer.outputColorSpace = SRGBColorSpace
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); renderer.setSize(canvas.clientWidth || 800, canvas.clientHeight || 384, false)
  const scene = new Scene(); scene.background = new Color("#020617")
  const camera = new PerspectiveCamera(45, (canvas.clientWidth || 800) / (canvas.clientHeight || 384), 0.1, 100)
  const controls = new OrbitControls(camera, canvas); controls.enableDamping = !window.matchMedia("(prefers-reduced-motion: reduce)").matches
  scene.add(new AmbientLight(0xffffff, 1.5)); const key = new DirectionalLight(0xffffff, 3); key.position.set(4, 6, 5); scene.add(key)
  let root: import("three").Object3D | null = null; let frame = 0; let disposed = false
  const render = () => { if (disposed) return; controls.update(); renderer.render(scene, camera); frame = requestAnimationFrame(render) }
  const preset = (name: string) => { const positions: Record<string, [number, number, number]> = { front: [0, 0, 8], top: [0, 8, 0.01], reset: [5, 4, 8] }; camera.position.set(...positions[name]); camera.lookAt(0, 0, 0); controls.update(); renderer.render(scene, camera) }
  new GLTFLoader().load(assetUrl, (gltf) => { /* v8 ignore next -- guards a loader callback racing unmount. */ if (disposed) return; root = gltf.scene; scene.add(root); new Box3().setFromObject(root).getCenter(controls.target); preset("reset"); render(); ready() }, undefined, () => fail("The local spacecraft model could not be loaded."))
  const raycaster = new Raycaster(); const pointer = new Vector2()
  const onPointer = (event: PointerEvent) => { const bounds = canvas.getBoundingClientRect(); pointer.set(((event.clientX - bounds.left) / bounds.width) * 2 - 1, -((event.clientY - bounds.top) / bounds.height) * 2 + 1); raycaster.setFromCamera(pointer, camera); const hit = root && raycaster.intersectObject(root, true)[0]?.object; const id = hit && [hit.name, hit.parent?.name].find((name) => ["fuselage", "port-wing", "starboard-wing"].includes(name || "")); if (id) select(id) }
  const onLost = (event: Event) => { event.preventDefault(); fail("WebGL context was lost; use the Rails metadata below.") }
  canvas.addEventListener("pointerup", onPointer); canvas.addEventListener("webglcontextlost", onLost)
  return { preset, explode(enabled) { root?.children.forEach((child, index) => { child.position.z = enabled ? (index - 1) * 0.8 : 0 }); renderer.render(scene, camera) }, dispose() { disposed = true; cancelAnimationFrame(frame); canvas.removeEventListener("pointerup", onPointer); canvas.removeEventListener("webglcontextlost", onLost); controls.dispose(); root?.traverse((object) => { if (object instanceof Mesh) { object.geometry.dispose(); const materials = Array.isArray(object.material) ? object.material : [object.material]; materials.forEach((material) => material.dispose()) } }); renderer.dispose() } }
}
function Guidance({ children, title }: { children: React.ReactNode, title: string }) { return <section className="rounded border p-4"><h3>{title}</h3><p>{children}</p></section> }
