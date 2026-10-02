// app/frontend/components/ContextualRelationships.tsx

import cytoscape from "cytoscape"
import { useEffect, useRef, useState } from "react"

type Node = { id: string, kind: string, name: string, detail: string, url: string, exploreUrl: string }
type Edge = { id: string, source: string, target: string, label: string }
export type ContextualRelationshipsProps = { rootId: string, nodes: Node[], edges: Edge[], bounded: boolean }

export default function ContextualRelationships({ rootId, nodes, edges, bounded }: ContextualRelationshipsProps) {
  const container = useRef<HTMLDivElement>(null)
  const [selectedId, setSelectedId] = useState(rootId)
  const selected = nodes.find(({ id }) => id === selectedId)

  useEffect(() => {
    const graph = cytoscape({
      container: container.current!,
      elements: [...nodes.map(node => ({ data: { id: node.id, label: node.name } })), ...edges.map(edge => ({ data: edge }))],
      layout: { name: "breadthfirst", directed: false, roots: [rootId], animate: false },
      style: [
        { selector: "node", style: { label: "data(label)", "background-color": "#0f766e", color: "#111827", "text-background-color": "#ffffff", "text-background-opacity": 1, "font-size": 11 } },
        { selector: "edge", style: { label: "data(label)", "line-color": "#64748b", "target-arrow-shape": "triangle", "target-arrow-color": "#64748b", "curve-style": "bezier", "font-size": 9 } }
      ]
    })
    graph.on("tap", "node", event => setSelectedId(event.target.id()))
    const observer = new ResizeObserver(() => { graph.resize(); graph.fit() })
    observer.observe(container.current!)
    return () => { observer.disconnect(); graph.destroy() }
  }, [edges, nodes, rootId])

  return <section className="space-y-4" data-testid="contextual-relationships">
    {bounded && <p role="status">Context limit reached. Explore from a nearby record to narrow the view.</p>}
    <div aria-hidden="true" className="relative h-80 overflow-hidden rounded border bg-white" ref={container} />
    <section aria-label="Selected context" aria-live="polite" className="rounded border p-4">
      {selected ? <><h2>{selected.kind}: {selected.name}</h2><p>{selected.detail}</p><a className="underline" href={selected.url}>Open source record</a>{" · "}<a className="underline" href={selected.exploreUrl}>Explore from this record</a></> : <p>Select an available record from the list.</p>}
    </section>
    <h2>Records</h2>
    <ul className="grid gap-2 md:grid-cols-2">{nodes.map(node => <li className="rounded border p-3" key={node.id}><button aria-pressed={node.id === selectedId} className="underline" onClick={() => setSelectedId(node.id)} type="button">{node.kind}: {node.name}</button>{" · "}<a href={node.url}>Open {node.name}</a></li>)}</ul>
    <h2>Relationships</h2>
    <ul>{edges.map(edge => <li key={edge.id}>{nodes.find(node => node.id === edge.source)!.name} → {edge.label} → {nodes.find(node => node.id === edge.target)!.name}</li>)}</ul>
    <p>Use the record buttons and links with a keyboard; the graph presents the same Rails-authorized context.</p>
  </section>
}
