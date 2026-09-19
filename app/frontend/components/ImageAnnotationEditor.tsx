// app/frontend/components/ImageAnnotationEditor.tsx

import { useEffect, useRef, useState } from "react"

type EditSpecification = {
  brightness: number | string
  contrast: number | string
  crop_height: number | string
  crop_width: number | string
  crop_x: number | string
  crop_y: number | string
  flip_x: boolean
  flip_y: boolean
  grayscale: boolean
  rotation: number | string
  saturation: number | string
  sepia: boolean
}
type Annotation = {
  edit_specification?: Partial<EditSpecification>
  focal_x: number | string
  focal_y: number | string
  label: string
  region_height?: number | string | null
  region_width?: number | string | null
  region_x?: number | string | null
  region_y?: number | string | null
}
type Asset = { annotation: Annotation, id: number, saveUrl: string, title: string, url: string }
type Point = { x: number, y: number }
type Tool = "crop" | "focal"
export type ImageAnnotationEditorProps = { assets: Asset[] }

const DEFAULT_EDIT_SPECIFICATION: EditSpecification = {
  brightness: 1, contrast: 1, crop_height: 1, crop_width: 1, crop_x: 0, crop_y: 0,
  flip_x: false, flip_y: false, grayscale: false, rotation: 0, saturation: 1, sepia: false
}
const ASPECT_PRESETS = {
  "1:1": { crop_height: 0.8, crop_width: 0.45, crop_x: 0.275, crop_y: 0.1 },
  "4:3": { crop_height: 0.8, crop_width: 0.6, crop_x: 0.2, crop_y: 0.1 },
  "16:9": { crop_height: 0.8, crop_width: 0.8, crop_x: 0.1, crop_y: 0.1 },
  Original: { crop_height: 1, crop_width: 1, crop_x: 0, crop_y: 0 }
} as const

function csrfToken() { return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" }
const number = (value: number | string | null | undefined, fallback = 0) => value == null || value === "" ? fallback : Number(value)
const canonicalEdit = (annotation: Annotation): EditSpecification => ({ ...DEFAULT_EDIT_SPECIFICATION, ...annotation.edit_specification })

function pointOnCanvas(event: React.PointerEvent<HTMLCanvasElement>): Point {
  const bounds = event.currentTarget.getBoundingClientRect()
  return {
    x: Math.max(0, Math.min(1, (event.clientX - bounds.left) / bounds.width)),
    y: Math.max(0, Math.min(1, (event.clientY - bounds.top) / bounds.height))
  }
}

function drawSource(context: CanvasRenderingContext2D, image: HTMLImageElement, annotation: Annotation) {
  const edit = canonicalEdit(annotation)
  const x = number(edit.crop_x) * 800
  const y = number(edit.crop_y) * 450
  const width = number(edit.crop_width, 1) * 800
  const height = number(edit.crop_height, 1) * 450
  context.clearRect(0, 0, 800, 450)
  context.drawImage(image, 0, 0, 800, 450)
  context.fillStyle = "rgba(15, 23, 42, 0.42)"
  context.fillRect(0, 0, 800, y)
  context.fillRect(0, y + height, 800, 450 - y - height)
  context.fillRect(0, y, x, height)
  context.fillRect(x + width, y, 800 - x - width, height)
  context.strokeStyle = "#facc15"
  context.lineWidth = 4
  context.setLineDash([12, 8])
  context.strokeRect(x, y, width, height)
  context.setLineDash([])
  if (annotation.region_width && annotation.region_height) {
    context.strokeStyle = "#38bdf8"
    context.lineWidth = 4
    context.strokeRect(number(annotation.region_x) * 800, number(annotation.region_y) * 450, number(annotation.region_width) * 800, number(annotation.region_height) * 450)
  }
  context.fillStyle = "#dc2626"
  context.beginPath()
  context.arc(number(annotation.focal_x, 0.5) * 800, number(annotation.focal_y, 0.5) * 450, 9, 0, Math.PI * 2)
  context.fill()
}

function drawProcessed(context: CanvasRenderingContext2D, image: HTMLImageElement, edit: EditSpecification) {
  const rotation = number(edit.rotation)
  const sideways = rotation === 90 || rotation === 270
  context.clearRect(0, 0, 800, 450)
  context.save()
  context.filter = `brightness(${number(edit.brightness, 1)}) contrast(${number(edit.contrast, 1)}) saturate(${number(edit.saturation, 1)}) grayscale(${edit.grayscale ? 1 : 0}) sepia(${edit.sepia ? 1 : 0})`
  context.translate(400, 225)
  context.rotate(rotation * Math.PI / 180)
  context.scale(edit.flip_x ? -1 : 1, edit.flip_y ? -1 : 1)
  context.drawImage(
    image,
    number(edit.crop_x) * image.naturalWidth,
    number(edit.crop_y) * image.naturalHeight,
    number(edit.crop_width, 1) * image.naturalWidth,
    number(edit.crop_height, 1) * image.naturalHeight,
    sideways ? -225 : -400,
    sideways ? -400 : -225,
    sideways ? 450 : 800,
    sideways ? 800 : 450
  )
  context.restore()
}

export default function ImageAnnotationEditor({ assets }: ImageAnnotationEditorProps) {
  const [selectedId, setSelectedId] = useState(assets[0]?.id)
  const selected = assets.find((asset) => asset.id === selectedId)
  const initial = selected?.annotation || { focal_x: 0.5, focal_y: 0.5, label: "Subject" }
  const [annotation, setAnnotation] = useState<Annotation>(initial)
  const [canvasReady, setCanvasReady] = useState(false)
  const [persisted, setPersisted] = useState<Annotation>(initial)
  const [message, setMessage] = useState<string | null>(null)
  const [tool, setTool] = useState<Tool>("crop")
  const dragStart = useRef<Point | null>(null)
  const previewCanvas = useRef<HTMLCanvasElement>(null)
  const sourceCanvas = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    if (!selected) return
    setAnnotation(selected.annotation)
    setPersisted(selected.annotation)
    setMessage(null)
  }, [selected])

  useEffect(() => {
    if (!selected || !sourceCanvas.current || !previewCanvas.current) return
    setCanvasReady(false)
    const sourceContext = sourceCanvas.current.getContext("2d")
    const previewContext = previewCanvas.current.getContext("2d")
    const image = new Image()
    image.onload = () => {
      /* v8 ignore next -- the browser contract supplies 2D contexts; jsdom uses the test double */
      if (!sourceContext || !previewContext) return
      drawSource(sourceContext, image, annotation)
      drawProcessed(previewContext, image, canonicalEdit(annotation))
      setCanvasReady(true)
    }
    image.src = selected.url
  }, [annotation, selected])

  function beginPointer(event: React.PointerEvent<HTMLCanvasElement>) {
    const point = pointOnCanvas(event)
    if (tool === "focal") {
      setAnnotation({ ...annotation, focal_x: point.x, focal_y: point.y })
      return
    }
    dragStart.current = point
    event.currentTarget.setPointerCapture?.(event.pointerId)
    setAnnotation({ ...annotation, edit_specification: { ...canonicalEdit(annotation), crop_height: 0.01, crop_width: 0.01, crop_x: point.x, crop_y: point.y } })
  }

  function dragCrop(event: React.PointerEvent<HTMLCanvasElement>) {
    if (!dragStart.current) return
    const point = pointOnCanvas(event)
    const x = Math.min(dragStart.current.x, point.x)
    const y = Math.min(dragStart.current.y, point.y)
    setAnnotation({ ...annotation, edit_specification: { ...canonicalEdit(annotation), crop_height: Math.max(0.01, Math.abs(point.y - dragStart.current.y)), crop_width: Math.max(0.01, Math.abs(point.x - dragStart.current.x)), crop_x: x, crop_y: y } })
  }

  function endPointer(event: React.PointerEvent<HTMLCanvasElement>) {
    if (!dragStart.current) return
    dragStart.current = null
    event.currentTarget.releasePointerCapture?.(event.pointerId)
  }

  function nudge(event: React.KeyboardEvent<HTMLCanvasElement>) {
    const changes: Record<string, [number, number]> = { ArrowDown: [0, 0.01], ArrowLeft: [-0.01, 0], ArrowRight: [0.01, 0], ArrowUp: [0, -0.01] }
    if (!changes[event.key]) return
    event.preventDefault()
    const [x, y] = changes[event.key]
    setAnnotation({ ...annotation, focal_x: Math.max(0, Math.min(1, number(annotation.focal_x) + x)), focal_y: Math.max(0, Math.min(1, number(annotation.focal_y) + y)) })
  }

  function updateEdit<K extends keyof EditSpecification>(key: K, value: EditSpecification[K]) {
    setAnnotation({ ...annotation, edit_specification: { ...canonicalEdit(annotation), [key]: value } })
  }

  function applyAspect(name: keyof typeof ASPECT_PRESETS | "Free") {
    if (name === "Free") return
    setAnnotation({ ...annotation, edit_specification: { ...canonicalEdit(annotation), ...ASPECT_PRESETS[name] } })
  }

  async function save() {
    /* v8 ignore next -- save control is not rendered without a selected asset */
    if (!selected) return
    setMessage(null)
    try {
      const body = { ...annotation, edit_specification: canonicalEdit(annotation) }
      const response = await fetch(selected.saveUrl, { method: "PATCH", credentials: "same-origin", headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() }, body: JSON.stringify(body) })
      const payload = await response.json() as Annotation & { error?: string }
      if (!response.ok) throw new Error(payload.error || "Image recipe could not be saved")
      setAnnotation(payload)
      setPersisted(payload)
      setMessage("Image recipe saved.")
    } catch (error) { setMessage((error as Error).message) }
  }

  if (!selected) return <p>No synthetic image assets are available.</p>
  const edit = canonicalEdit(annotation)
  return <section className="space-y-5" data-testid="image-annotation-editor">
    <label>Image<select className="ml-2 rounded border p-2" value={selectedId} onChange={(event) => setSelectedId(Number(event.target.value))}>{assets.map((asset) => <option key={asset.id} value={asset.id}>{asset.title}</option>)}</select></label>
    {message && <p aria-live="polite" role={message === "Image recipe saved." ? "status" : "alert"}>{message}</p>}
    <div className="flex flex-wrap gap-2" role="toolbar" aria-label="Editing tools">
      <button aria-pressed={tool === "crop"} className="rounded border px-3 py-2" onClick={() => setTool("crop")} type="button">Crop tool</button>
      <button aria-pressed={tool === "focal"} className="rounded border px-3 py-2" onClick={() => setTool("focal")} type="button">Focal-point tool</button>
      <label className="rounded border px-3 py-2">Aspect <select aria-label="Crop aspect preset" defaultValue="Free" onChange={(event) => applyAspect(event.target.value as keyof typeof ASPECT_PRESETS | "Free")}><option>Free</option><option>Original</option><option>1:1</option><option>4:3</option><option>16:9</option></select></label>
      <button className="rounded border px-3 py-2" onClick={() => updateEdit("rotation", (number(edit.rotation) + 270) % 360)} type="button">Rotate left</button>
      <button className="rounded border px-3 py-2" onClick={() => updateEdit("rotation", (number(edit.rotation) + 90) % 360)} type="button">Rotate right</button>
      <button aria-pressed={edit.flip_x} className="rounded border px-3 py-2" onClick={() => updateEdit("flip_x", !edit.flip_x)} type="button">Flip horizontal</button>
      <button aria-pressed={edit.flip_y} className="rounded border px-3 py-2" onClick={() => updateEdit("flip_y", !edit.flip_y)} type="button">Flip vertical</button>
    </div>
    <div className="grid gap-5 xl:grid-cols-2">
      <figure><figcaption className="mb-2 font-semibold">Source and crop workspace</figcaption><canvas aria-label="Source image editor. Drag to crop or choose the focal-point tool; arrow keys adjust the focal point." className="h-auto w-full border bg-slate-900" data-ready={canvasReady} height="450" onKeyDown={nudge} onPointerDown={beginPointer} onPointerMove={dragCrop} onPointerUp={endPointer} ref={sourceCanvas} role="img" tabIndex={0} width="800" /></figure>
      <figure><figcaption className="mb-2 font-semibold">Processed preview</figcaption><canvas aria-label="Processed image preview" className="h-auto w-full border bg-slate-900" height="450" ref={previewCanvas} role="img" width="800" /></figure>
    </div>
    <div className="grid gap-4 md:grid-cols-3">
      {(["brightness", "contrast", "saturation"] as const).map((key) => <label className="font-medium" key={key}>{key[0].toUpperCase() + key.slice(1)} <output>{number(edit[key], 1).toFixed(2)}</output><input aria-label={key[0].toUpperCase() + key.slice(1)} className="block w-full" max={key === "saturation" ? 2 : 1.5} min={key === "saturation" ? 0 : 0.5} onChange={(event) => updateEdit(key, event.target.value)} step="0.05" type="range" value={edit[key]} /></label>)}
      <label><input checked={edit.grayscale} onChange={(event) => updateEdit("grayscale", event.target.checked)} type="checkbox" /> Grayscale / B&amp;W</label>
      <label><input checked={edit.sepia} onChange={(event) => updateEdit("sepia", event.target.checked)} type="checkbox" /> Sepia</label>
    </div>
    <p aria-live="polite">Crop {number(edit.crop_width, 1).toFixed(2)} × {number(edit.crop_height, 1).toFixed(2)} · Rotation {number(edit.rotation)}°</p>
    <details><summary className="cursor-pointer font-semibold">Focal point and annotation region</summary><div className="mt-3 grid gap-3 md:grid-cols-3"><label>Label<select value={annotation.label} onChange={(event) => setAnnotation({ ...annotation, label: event.target.value })}><option>Subject</option><option>Logo</option><option>Product</option></select></label>{(["focal_x", "focal_y", "region_x", "region_y", "region_width", "region_height"] as const).map((key) => <label key={key}>{key.replaceAll("_", " ")}<input min="0" max="1" step="0.01" type="number" value={annotation[key] ?? ""} onChange={(event) => setAnnotation({ ...annotation, [key]: event.target.value })}/></label>)}</div></details>
    <div className="flex flex-wrap gap-2">
      <button className="rounded bg-blue-700 px-3 py-2 text-white" onClick={() => void save()} type="button">Save edit recipe</button>
      <button className="rounded border px-3 py-2" onClick={() => setAnnotation({ ...annotation, edit_specification: DEFAULT_EDIT_SPECIFICATION })} type="button">Reset transformations</button>
      <button className="rounded border px-3 py-2" onClick={() => { setAnnotation(persisted); setMessage("Reverted to the saved recipe.") }} type="button">Revert unsaved changes</button>
    </div>
  </section>
}
