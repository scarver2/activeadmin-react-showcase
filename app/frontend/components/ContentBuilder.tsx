// app/frontend/components/ContentBuilder.tsx

import { DndContext, type DragEndEvent } from "@dnd-kit/core"
import { arrayMove, SortableContext, useSortable, verticalListSortingStrategy } from "@dnd-kit/sortable"
import { CSS } from "@dnd-kit/utilities"
import { useState } from "react"

type Block = { body: string, id: string, type: "callout" | "heading" | "paragraph" }
type Document = { blocks: Block[], id: string, lockVersion: number, title: string, updateUrl: string }
export type ContentBuilderProps = { document: Document }

function csrfToken() { return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" }

export default function ContentBuilder({ document: initial }: ContentBuilderProps) {
  const [documentState, setDocumentState] = useState(initial)
  const [blocks, setBlocks] = useState(initial.blocks)
  const [selectedId, setSelectedId] = useState(initial.blocks[0]?.id || null)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const selected = blocks.find((block) => block.id === selectedId)

  function add(type: Block["type"]) {
    const block = { body: `New ${type}`, id: `draft-${crypto.randomUUID()}`, type }
    setBlocks((current) => [...current, block])
    setSelectedId(block.id)
  }
  function remove(id: string) {
    setBlocks((current) => current.filter((block) => block.id !== id))
    setSelectedId((current) => current === id ? null : current)
  }
  function move(id: string, offset: number) {
    setBlocks((current) => {
      const from = current.findIndex((block) => block.id === id)
      const to = Math.max(0, Math.min(current.length - 1, from + offset))
      return arrayMove(current, from, to)
    })
  }
  function dragEnded(event: DragEndEvent) {
    if (event.over && event.active.id !== event.over.id) {
      const from = blocks.findIndex((block) => block.id === event.active.id)
      const to = blocks.findIndex((block) => block.id === event.over!.id)
      setBlocks(arrayMove(blocks, from, to))
    }
  }
  async function save() {
    const prior = documentState.blocks
    setSaving(true)
    setError(null)
    try {
      const response = await fetch(documentState.updateUrl, { body: JSON.stringify({ blocks: blocks.map(({ body, type }) => ({ body, type })), lock_version: documentState.lockVersion }), credentials: "same-origin", headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() }, method: "PATCH" })
      const payload = await response.json() as { document?: Document, error?: string }
      if (!response.ok || !payload.document) throw new Error(payload.error || "Document could not be saved")
      setDocumentState(payload.document)
      setBlocks(payload.document.blocks)
      setSelectedId(payload.document.blocks[0]?.id || null)
    } catch (saveError) {
      setBlocks(prior)
      setError(`${(saveError as Error).message}. Unsaved changes were rolled back.`)
    } finally { setSaving(false) }
  }

  return <section className="space-y-5" data-testid="content-builder">
    {error && <p role="alert" className="text-red-700">{error}</p>}
    <div className="flex flex-wrap gap-2">{(["heading", "paragraph", "callout"] as const).map((type) => <button className="rounded border px-3 py-2" key={type} onClick={() => add(type)} type="button">Add {type}</button>)}<button className="rounded bg-teal-700 px-3 py-2 text-white" disabled={saving} onClick={() => void save()} type="button">{saving ? "Saving…" : "Save document"}</button></div>
    <div className="grid gap-5 lg:grid-cols-3">
      <DndContext onDragEnd={dragEnded}><SortableContext items={blocks.map(({ id }) => id)} strategy={verticalListSortingStrategy}><ol aria-label="Content blocks" className="space-y-2">{blocks.map((block, index) => <SortableBlock block={block} index={index} key={block.id} move={move} remove={remove} select={setSelectedId} />)}</ol></SortableContext></DndContext>
      <section aria-label="Block properties" className="rounded border p-4"><h3 className="font-semibold">Block properties</h3>{selected ? <label>Content<textarea className="mt-2 w-full rounded border p-2" value={selected.body} onChange={(event) => setBlocks((current) => current.map((block) => block.id === selected.id ? { ...block, body: event.target.value } : block))} /></label> : <p>Select a block to edit it.</p>}</section>
      <section aria-label="Live preview" className="rounded border p-4"><h3 className="font-semibold">Live preview</h3>{blocks.map((block) => block.type === "heading" ? <h4 className="text-xl font-bold" key={block.id}>{block.body}</h4> : block.type === "callout" ? <aside className="border-l-4 border-teal-700 p-2" key={block.id}>{block.body}</aside> : <p key={block.id}>{block.body}</p>)}</section>
    </div>
    <div className="grid gap-4 lg:grid-cols-3"><Guidance title="Ruby">Normalized blocks, allowlisted types, ordering, ownership, and lock versions are authoritative.</Guidance><Guidance title="JavaScript">dnd-kit and keyboard buttons compose a transient proposal with rollback.</Guidance><Guidance title="Architecture">The deliberately small schema prevents arbitrary markup or executable content.</Guidance></div>
  </section>
}

function SortableBlock({ block, index, move, remove, select }: { block: Block, index: number, move: (id: string, offset: number) => void, remove: (id: string) => void, select: (id: string) => void }) {
  const sortable = useSortable({ id: block.id })
  return <li ref={sortable.setNodeRef} style={{ transform: CSS.Transform.toString(sortable.transform), transition: sortable.transition }}><article className="rounded border bg-white p-3"><button {...sortable.attributes} {...sortable.listeners} aria-label={`Drag ${block.body}`} className="cursor-grab" type="button">↕</button> <button className="font-semibold underline" onClick={() => select(block.id)} type="button">{block.body}</button><div><button aria-label={`Move ${block.body} up`} disabled={index === 0} onClick={() => move(block.id, -1)} type="button">↑</button><button aria-label={`Move ${block.body} down`} onClick={() => move(block.id, 1)} type="button">↓</button><button aria-label={`Remove ${block.body}`} onClick={() => remove(block.id)} type="button">Remove</button></div></article></li>
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) { return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><p>{children}</p></section> }
