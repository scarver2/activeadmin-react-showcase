// app/frontend/components/MaterialSphereStudio.tsx

import {
  ACESFilmicToneMapping,
  AmbientLight,
  CircleGeometry,
  Color,
  DirectionalLight,
  Mesh,
  MeshPhysicalMaterial,
  MeshStandardMaterial,
  PerspectiveCamera,
  Scene,
  SphereGeometry,
  SRGBColorSpace,
  Vector3,
  WebGLRenderer,
} from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import { useEffect, useRef, useState } from "react"

type Finish = { clearcoat: number, color: string, id: string, label: string, metalness: number, roughness: number }
type Model = { finish: string, finishes: Finish[], id: string, lockVersion: number, name: string, updateUrl: string }
export type MaterialSphereStudioProps = { model: Model }
type CameraPreset = "detail" | "front" | "reset"
type ViewerApi = { dispose: () => void, preset: (name: CameraPreset) => void, setFinish: (finish: Finish) => void }

function csrfToken() { return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" }
function finishById(finishes: Finish[], id: string) { return finishes.find((finish) => finish.id === id)! }

export default function MaterialSphereStudio({ model: initial }: MaterialSphereStudioProps) {
  const canvas = useRef<HTMLCanvasElement>(null)
  const viewer = useRef<ViewerApi | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [finish, setFinish] = useState(initial.finish)
  const [loading, setLoading] = useState(true)
  const [lockVersion, setLockVersion] = useState(initial.lockVersion)
  const selectedFinish = finishById(initial.finishes, finish)

  useEffect(() => {
    /* v8 ignore next -- React attaches the ref before running this effect. */
    if (!canvas.current) return
    try {
      viewer.current = createViewer(canvas.current, selectedFinish, () => setLoading(false), (message) => { setError(message); setLoading(false) })
    } catch (viewerError) { setError((viewerError as Error).message); setLoading(false) }
    return () => { viewer.current?.dispose(); viewer.current = null }
    // The scene is created once; material changes are applied through the viewer API.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  async function persist(nextFinish: string) {
    const previousFinish = finish
    const recipe = finishById(initial.finishes, nextFinish)
    setError(null); setFinish(nextFinish); viewer.current?.setFinish(recipe)
    try {
      const response = await fetch(initial.updateUrl, { body: JSON.stringify({ lock_version: lockVersion, material_sphere: { finish: nextFinish } }), credentials: "same-origin", headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() }, method: "PATCH" })
      const payload = await response.json() as { error?: string, model?: Model }
      if (!response.ok || !payload.model) throw new Error(payload.error || "Material recipe could not be saved")
      const canonical = finishById(initial.finishes, payload.model.finish)
      setFinish(payload.model.finish); viewer.current?.setFinish(canonical); setLockVersion(payload.model.lockVersion)
    } catch (saveError) {
      const previous = finishById(initial.finishes, previousFinish)
      setFinish(previousFinish); viewer.current?.setFinish(previous); setError((saveError as Error).message)
    }
  }

  return <section className="space-y-5" data-testid="material-sphere-studio">
    {error && <p role="alert" className="text-red-700">{error}</p>}
    {loading && <p role="status">Preparing the Three.js material studio…</p>}
    <div className="overflow-hidden rounded-xl border border-slate-700 bg-[radial-gradient(circle_at_45%_32%,#354052_0%,#141922_48%,#05070a_100%)] p-2 shadow-2xl">
      <canvas aria-label="Interactive glossy red material sphere" className="h-[34rem] w-full rounded-lg" data-render-state={loading ? "loading" : error ? "fallback" : "ready"} ref={canvas} />
    </div>
    <div className="flex flex-wrap gap-2" aria-label="Camera controls">
      <button onClick={() => viewer.current?.preset("front")} type="button">Front view</button>
      <button onClick={() => viewer.current?.preset("detail")} type="button">Highlight detail</button>
      <button onClick={() => viewer.current?.preset("reset")} type="button">Reset camera</button>
    </div>
    <div className="grid gap-4 lg:grid-cols-2">
      <section aria-label="Material recipe" className="rounded border p-4">
        <h3>Material recipe</h3>
        <label>Red finish
          <select value={finish} onChange={(event) => void persist(event.target.value)}>
            {initial.finishes.map((value) => <option key={value.id} value={value.id}>{value.label}</option>)}
          </select>
        </label>
        <dl className="mt-3 grid grid-cols-2 gap-2">
          <dt>Base color</dt><dd>{selectedFinish.color}</dd>
          <dt>Roughness</dt><dd>{selectedFinish.roughness.toFixed(2)}</dd>
          <dt>Metalness</dt><dd>{selectedFinish.metalness.toFixed(2)}</dd>
          <dt>Clearcoat</dt><dd>{selectedFinish.clearcoat.toFixed(2)}</dd>
        </dl>
      </section>
      <section aria-label="Interaction guide" className="rounded border p-4">
        <h3>Studio controls</h3>
        <p>Drag to orbit, scroll to zoom, or use the named camera views. The default candy-red recipe uses a tight roughness value and full clearcoat for a bright, readable specular highlight.</p>
      </section>
    </div>
    <div className="grid gap-4 lg:grid-cols-3">
      <Guidance title="Ruby">Rails owns identity, authorization, optimistic locking, and the allowlisted physical-material recipes.</Guidance>
      <Guidance title="JavaScript">Three.js owns procedural geometry, physically based rendering, studio lighting, orbit controls, and camera state.</Guidance>
      <Guidance title="Architecture">A lazy procedural scene proves lifecycle-safe WebGL integration without remote assets, licensing ambiguity, or a speculative scene-editor API.</Guidance>
    </div>
  </section>
}

function createViewer(canvas: HTMLCanvasElement, initialFinish: Finish, ready: () => void, fail: (message: string) => void): ViewerApi {
  const renderer = new WebGLRenderer({ alpha: true, antialias: true, canvas, powerPreference: "high-performance" })
  renderer.outputColorSpace = SRGBColorSpace; renderer.toneMapping = ACESFilmicToneMapping; renderer.toneMappingExposure = 1.2
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); renderer.setSize(canvas.clientWidth || 900, canvas.clientHeight || 544, false)
  const scene = new Scene(); scene.background = null
  const camera = new PerspectiveCamera(35, (canvas.clientWidth || 900) / (canvas.clientHeight || 544), 0.1, 100)
  const controls = new OrbitControls(camera, canvas); controls.enableDamping = !window.matchMedia("(prefers-reduced-motion: reduce)").matches; controls.enablePan = false; controls.minDistance = 4.5; controls.maxDistance = 11
  const material = new MeshPhysicalMaterial({ clearcoat: initialFinish.clearcoat, clearcoatRoughness: 0.025, color: initialFinish.color, metalness: initialFinish.metalness, reflectivity: 1, roughness: initialFinish.roughness })
  const sphere = new Mesh(new SphereGeometry(2.15, 72, 54), material); sphere.position.y = 0.15; scene.add(sphere)
  const floor = new Mesh(new CircleGeometry(5.2, 72), new MeshStandardMaterial({ color: "#090b10", metalness: 0.2, roughness: 0.72 })); floor.rotation.x = -Math.PI / 2; floor.position.y = -2.05; scene.add(floor)
  scene.add(new AmbientLight(0xa8b4c8, 0.55))
  const key = new DirectionalLight(0xffffff, 5.4); key.position.set(-4.5, 6, 5); scene.add(key)
  const fill = new DirectionalLight(0xffd8d8, 2.2); fill.position.set(5, 1.5, 4); scene.add(fill)
  const rim = new DirectionalLight(0x8db8ff, 4.2); rim.position.set(2.5, 4, -5); scene.add(rim)
  const focus = new Vector3(0, 0.1, 0); controls.target.copy(focus)
  let frame = 0; let disposed = false
  const render = () => { if (disposed) return; controls.update(); renderer.render(scene, camera); frame = requestAnimationFrame(render) }
  const preset = (name: CameraPreset) => {
    const positions: Record<CameraPreset, [number, number, number]> = { detail: [-1.6, 1.15, 5.2], front: [0, 0.15, 7.2], reset: [1.4, 0.8, 7.4] }
    camera.position.set(...positions[name]); camera.lookAt(focus); controls.update(); renderer.render(scene, camera)
  }
  const setFinish = (finish: Finish) => { material.color.copy(new Color(finish.color)); material.roughness = finish.roughness; material.metalness = finish.metalness; material.clearcoat = finish.clearcoat; material.needsUpdate = true; renderer.render(scene, camera) }
  const onLost = (event: Event) => { event.preventDefault(); fail("WebGL context was lost; use the Rails-owned material recipe below.") }
  canvas.addEventListener("webglcontextlost", onLost)
  preset("reset"); render(); ready()
  return { preset, setFinish, dispose() { disposed = true; cancelAnimationFrame(frame); canvas.removeEventListener("webglcontextlost", onLost); controls.dispose(); sphere.geometry.dispose(); material.dispose(); floor.geometry.dispose(); floor.material.dispose(); renderer.dispose() } }
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) { return <section className="rounded border p-4"><h3>{title}</h3><p>{children}</p></section> }
