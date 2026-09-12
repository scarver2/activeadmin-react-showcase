// app/frontend/components/ImageAnnotationEditor.tsx

import { useEffect, useRef, useState } from "react"

type Annotation = { focal_x: number | string, focal_y: number | string, label: string, region_height?: number | string | null, region_width?: number | string | null, region_x?: number | string | null, region_y?: number | string | null }
type Asset = { annotation: Annotation, id: number, saveUrl: string, title: string, url: string }
export type ImageAnnotationEditorProps = { assets: Asset[] }

function csrfToken() { return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" }
const number = (value: number | string | null | undefined, fallback = 0) => value == null ? fallback : Number(value)

export default function ImageAnnotationEditor({ assets }: ImageAnnotationEditorProps) {
  const [selectedId, setSelectedId] = useState(assets[0]?.id)
  const selected = assets.find((asset) => asset.id === selectedId)
  const [annotation, setAnnotation] = useState<Annotation>(selected?.annotation || { focal_x: 0.5, focal_y: 0.5, label: "Subject" })
  const [message, setMessage] = useState<string | null>(null)
  const canvas = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    if (!selected) return
    setAnnotation(selected.annotation)
  }, [selected])

  useEffect(() => {
    if (!selected || !canvas.current) return
    const context = canvas.current.getContext("2d")
    const image = new Image()
    image.onload = () => {
      /* v8 ignore next -- the browser contract supplies a 2D context; jsdom does not */
      if (!context || !canvas.current) return
      context.clearRect(0, 0, 800, 450); context.drawImage(image, 0, 0, 800, 450)
      context.fillStyle = "#dc2626"; context.beginPath(); context.arc(number(annotation.focal_x, 0.5) * 800, number(annotation.focal_y, 0.5) * 450, 9, 0, Math.PI * 2); context.fill()
      if (annotation.region_width && annotation.region_height) { context.strokeStyle = "#2563eb"; context.lineWidth = 4; context.strokeRect(number(annotation.region_x) * 800, number(annotation.region_y) * 450, number(annotation.region_width) * 800, number(annotation.region_height) * 450) }
    }
    image.src = selected.url
  }, [annotation, selected])

  function place(event: React.PointerEvent<HTMLCanvasElement>) {
    const bounds = event.currentTarget.getBoundingClientRect()
    setAnnotation({ ...annotation, focal_x: Math.max(0, Math.min(1, (event.clientX - bounds.left) / bounds.width)), focal_y: Math.max(0, Math.min(1, (event.clientY - bounds.top) / bounds.height)) })
  }

  function nudge(event: React.KeyboardEvent<HTMLCanvasElement>) {
    const changes: Record<string, [number, number]> = { ArrowDown: [0, 0.01], ArrowLeft: [-0.01, 0], ArrowRight: [0.01, 0], ArrowUp: [0, -0.01] }
    if (!changes[event.key]) return
    event.preventDefault(); const [x, y] = changes[event.key]
    setAnnotation({ ...annotation, focal_x: Math.max(0, Math.min(1, number(annotation.focal_x) + x)), focal_y: Math.max(0, Math.min(1, number(annotation.focal_y) + y)) })
  }

  async function save() {
    /* v8 ignore next -- save control is not rendered without a selected asset */
    if (!selected) return
    setMessage(null)
    try {
      const response = await fetch(selected.saveUrl, { method: "PATCH", credentials: "same-origin", headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() }, body: JSON.stringify(annotation) })
      const payload = await response.json() as Annotation & { error?: string }
      if (!response.ok) throw new Error(payload.error || "Annotation could not be saved")
      setAnnotation(payload); setMessage("Annotation saved.")
    } catch (error) { setMessage((error as Error).message) }
  }

  if (!selected) return <p>No synthetic image assets are available.</p>
  return <section className="space-y-4" data-testid="image-annotation-editor">
    <label>Image<select className="ml-2 rounded border p-2" value={selectedId} onChange={(event) => setSelectedId(Number(event.target.value))}>{assets.map((asset) => <option key={asset.id} value={asset.id}>{asset.title}</option>)}</select></label>
    {message && <p aria-live="polite" role={message === "Annotation saved." ? "status" : "alert"}>{message}</p>}
    <canvas aria-label="Image focal point editor. Use arrow keys to adjust." className="h-auto w-full max-w-3xl border" height="450" onKeyDown={nudge} onPointerDown={place} ref={canvas} role="img" tabIndex={0} width="800" />
    <div className="grid gap-3 md:grid-cols-3"><label>Label<select value={annotation.label} onChange={(event) => setAnnotation({ ...annotation, label: event.target.value })}><option>Subject</option><option>Logo</option><option>Product</option></select></label>{(["focal_x", "focal_y", "region_x", "region_y", "region_width", "region_height"] as const).map((key) => <label key={key}>{key.replaceAll("_", " ")}<input min="0" max="1" step="0.01" type="number" value={annotation[key] ?? ""} onChange={(event) => setAnnotation({ ...annotation, [key]: event.target.value })}/></label>)}</div>
    <button className="rounded bg-blue-700 px-3 py-2 text-white" onClick={() => void save()} type="button">Save normalized metadata</button>
  </section>
}
