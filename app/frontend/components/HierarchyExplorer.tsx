// app/frontend/components/HierarchyExplorer.tsx

import { useState } from "react"

type Crumb = { id: string, title: string }
type TreeNode = {
  breadcrumbs: Crumb[]
  childCount: number
  childrenUrl: string
  id: string
  lockVersion: number
  moveUrl: string
  title: string
}

export type HierarchyExplorerProps = { roots: TreeNode[] }

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

export default function HierarchyExplorer({ roots: initialRoots }: HierarchyExplorerProps) {
  const [children, setChildren] = useState<Record<string, TreeNode[]>>({})
  const [draggedId, setDraggedId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [expanded, setExpanded] = useState<string[]>([])
  const [loading, setLoading] = useState<string | null>(null)
  const [roots, setRoots] = useState(initialRoots)
  const [selected, setSelected] = useState<TreeNode | null>(null)

  async function toggle(node: TreeNode) {
    if (expanded.includes(node.id)) {
      setExpanded((current) => current.filter((id) => id !== node.id))
      return
    }

    setExpanded((current) => [...current, node.id])
    if (children[node.id] || node.childCount === 0) return

    setLoading(node.id)
    setError(null)
    try {
      const response = await fetch(node.childrenUrl, { credentials: "same-origin", headers: { Accept: "application/json" } })
      const payload = await response.json() as { error?: string, nodes?: TreeNode[] }
      if (!response.ok) throw new Error(payload.error || "Children could not be loaded")
      setChildren((current) => ({ ...current, [node.id]: payload.nodes || [] }))
    } catch (loadError) {
      setExpanded((current) => current.filter((id) => id !== node.id))
      setError((loadError as Error).message)
    } finally {
      setLoading(null)
    }
  }

  function allNodes() {
    return [...roots, ...Object.values(children).flat()]
  }

  async function move(nodeId: string, parent: TreeNode) {
    if (nodeId === parent.id) return
    const node = allNodes().find((candidate) => candidate.id === nodeId)!

    const priorRoots = roots
    const priorChildren = children
    setError(null)
    setRoots((current) => current.filter((candidate) => candidate.id !== nodeId))
    setChildren((current) => Object.fromEntries(Object.entries(current).map(([id, values]) => [
      id,
      id === parent.id ? [...values.filter((candidate) => candidate.id !== nodeId), node] : values.filter((candidate) => candidate.id !== nodeId)
    ])))
    setExpanded((current) => current.includes(parent.id) ? current : [...current, parent.id])

    try {
      const response = await fetch(node.moveUrl, {
        body: JSON.stringify({ lock_version: node.lockVersion, parent_id: parent.id, position: children[parent.id]?.length || 0 }),
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        method: "PATCH"
      })
      const payload = await response.json() as { error?: string, node?: TreeNode }
      if (!response.ok || !payload.node) throw new Error(payload.error || "Hierarchy move failed")
      setChildren((current) => ({
        ...current,
        [parent.id]: (current[parent.id] || []).map((candidate) => candidate.id === nodeId ? payload.node! : candidate)
      }))
      setSelected(payload.node)
    } catch (moveError) {
      setRoots(priorRoots)
      setChildren(priorChildren)
      setError(`${(moveError as Error).message}. The tree was restored.`)
    } finally {
      setDraggedId(null)
    }
  }

  function branch(nodes: TreeNode[], level = 1) {
    if (nodes.length === 0) return <p className="ml-4 text-sm text-gray-600">Empty branch</p>

    return (
      <ul aria-label={level === 1 ? "Organization hierarchy" : undefined} className="space-y-2" role={level === 1 ? "tree" : "group"}>
        {nodes.map((node) => (
          <li
            aria-expanded={node.childCount > 0 ? expanded.includes(node.id) : undefined}
            aria-level={level}
            className="rounded border bg-white p-3 text-gray-900"
            draggable
            key={node.id}
            onDragOver={(event) => event.preventDefault()}
            onDragStart={() => setDraggedId(node.id)}
            onDrop={() => draggedId && void move(draggedId, node)}
            role="treeitem"
          >
            <div className="flex flex-wrap items-center gap-2">
              {node.childCount > 0 && <button aria-label={`${expanded.includes(node.id) ? "Collapse" : "Expand"} ${node.title}`} className="rounded border px-2" onClick={() => void toggle(node)} type="button">{expanded.includes(node.id) ? "−" : "+"}</button>}
              <button className="font-semibold underline" onClick={() => setSelected(node)} type="button">{node.title}</button>
              {selected && selected.id !== node.id && <button className="rounded border px-2 text-sm" onClick={() => void move(selected.id, node)} type="button">Move {selected.title} here</button>}
              {loading === node.id && <span aria-live="polite">Loading…</span>}
            </div>
            {expanded.includes(node.id) && branch(children[node.id] || [], level + 1)}
          </li>
        ))}
      </ul>
    )
  }

  return (
    <section className="space-y-5" data-testid="hierarchy-explorer">
      {error && <p className="text-red-700" role="alert">{error}</p>}
      {selected && (
        <nav aria-label="Selected node breadcrumbs" className="rounded border p-3">
          {[...selected.breadcrumbs, { id: selected.id, title: selected.title }].map((crumb, index) => <span key={crumb.id}>{index > 0 && " / "}{crumb.title}</span>)}
        </nav>
      )}
      {branch(roots)}
      <div className="grid gap-4 lg:grid-cols-3">
        <Guidance title="Ruby">Queries and moves remain owner-scoped, bounded, cycle-safe, depth-safe, and lock-versioned.</Guidance>
        <Guidance title="JavaScript">Expansion and selection are transient; drag and keyboard moves are optimistic proposals with rollback.</Guidance>
        <Guidance title="Architecture">A Rails-owned adjacency list stays portable and avoids inventing a generic hierarchy package.</Guidance>
      </div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><p className="mt-2 text-sm">{children}</p></section>
}
