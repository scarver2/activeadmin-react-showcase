// app/frontend/components/SocialGraphExplorer.tsx

import cytoscape, { type Core } from "cytoscape"
import { useEffect, useRef, useState } from "react"

type Person = { degree: number | null, headline: string, id: string, name: string, url: string }
type Edge = { id: string, source: string, target: string }
type Graph = { edges: Edge[], mutuals: Person[], nodes: Person[], path: string[] }
export type SocialGraphExplorerProps = { endpoint: string, graph: Graph, people: Pick<Person, "id" | "name">[], rootId: string }

export default function SocialGraphExplorer({ endpoint, graph: initialGraph, people, rootId: initialRoot }: SocialGraphExplorerProps) {
  const container = useRef<HTMLDivElement>(null)
  const cy = useRef<Core | null>(null)
  const [depth, setDepth] = useState(1)
  const [error, setError] = useState<string | null>(null)
  const [graph, setGraph] = useState(initialGraph)
  const [loading, setLoading] = useState(false)
  const [rootId, setRootId] = useState(initialRoot)
  const [selectedId, setSelectedId] = useState(initialRoot)
  const [targetId, setTargetId] = useState(people.find((person) => person.id !== initialRoot)?.id || initialRoot)
  const selected = graph.nodes.find((node) => node.id === selectedId)

  useEffect(() => {
    /* v8 ignore next -- React attaches the ref before running this effect. */
    if (!container.current) return
    const instance = cytoscape({ container: container.current, elements: [
      ...graph.nodes.map((node) => ({ data: { id: node.id, label: node.name } })),
      ...graph.edges.map((edge) => ({ data: edge }))
    ], layout: { name: "cose", animate: false }, style: [
      { selector: "node", style: { "background-color": "#0f766e", label: "data(label)", "font-size": 10 } },
      { selector: "edge", style: { "line-color": "#94a3b8", width: 2 } },
      { selector: ".path", style: { "background-color": "#b45309", "line-color": "#b45309", width: 4 } }
    ] })
    instance.on("tap", "node", (event) => setSelectedId(event.target.id()))
    graph.path.forEach((id) => instance.getElementById(id).addClass("path"))
    cy.current = instance
    return () => { instance.destroy(); cy.current = null }
  }, [graph])

  async function load(nextDepth = depth, nextRoot = rootId, nextTarget = targetId) {
    setLoading(true)
    setError(null)
    try {
      const query = new URLSearchParams({ depth: String(nextDepth), root_id: nextRoot, target_id: nextTarget })
      const response = await fetch(`${endpoint}?${query}`, { credentials: "same-origin", headers: { Accept: "application/json" } })
      const payload = await response.json() as Graph & { error?: string }
      if (!response.ok) throw new Error(payload.error || "Graph could not be loaded")
      setGraph(payload)
      setSelectedId(nextRoot)
    } catch (loadError) { setError((loadError as Error).message) } finally { setLoading(false) }
  }

  return <section className="space-y-5" data-testid="social-graph-explorer">
    {error && <p role="alert" className="text-red-700">{error}</p>}{loading && <p role="status">Loading network…</p>}
    <div className="flex flex-wrap gap-3"><label>Start<select value={rootId} onChange={(event) => { setRootId(event.target.value); void load(depth, event.target.value, targetId) }}>{people.map((person) => <option key={person.id} value={person.id}>{person.name}</option>)}</select></label><label>Target<select value={targetId} onChange={(event) => { setTargetId(event.target.value); void load(depth, rootId, event.target.value) }}>{people.map((person) => <option key={person.id} value={person.id}>{person.name}</option>)}</select></label>{[1, 2, 3].map((value) => <button aria-pressed={depth === value} key={value} onClick={() => { setDepth(value); void load(value) }} type="button">{value} degree{value > 1 ? "s" : ""}</button>)}<button onClick={() => cy.current?.fit()} type="button">Fit graph</button></div>
    <div aria-label="Interactive social graph" className="h-96 rounded border" data-testid="social-graph" ref={container} />
    <div className="grid gap-4 lg:grid-cols-3"><section aria-label="People" className="rounded border p-4"><h3>People</h3>{graph.nodes.length ? <ul>{graph.nodes.map((person) => <li key={person.id}><button className="underline" onClick={() => setSelectedId(person.id)} type="button">{person.name}</button> — degree {person.degree}</li>)}</ul> : <p>No connected people.</p>}</section><section aria-label="Selected person" className="rounded border p-4"><h3>Selected</h3>{selected ? <><strong>{selected.name}</strong><p>{selected.headline}</p><a href={selected.url}>Open Rails record</a></> : <p>Select a person.</p>}</section><section aria-label="Relationship path" className="rounded border p-4"><h3>Degrees of separation</h3>{graph.path.length ? <p>{graph.path.map((id) => people.find((person) => person.id === id)?.name || id).join(" → ")}</p> : <p>No path within three degrees.</p>}<h4>Mutual connections</h4><p>{graph.mutuals.map(({ name }) => name).join(", ") || "None"}</p></section></div>
    <div className="grid gap-4 lg:grid-cols-3"><Guidance title="Ruby">Rails caps depth, nodes, edges, ownership, mutuals, and shortest-path work.</Guidance><Guidance title="JavaScript">Cytoscape owns bounded layout, pan/zoom, selection, and path highlighting.</Guidance><Guidance title="Architecture">Normalized undirected edges stay portable; no graph database is implied.</Guidance></div>
  </section>
}
function Guidance({ children, title }: { children: React.ReactNode, title: string }) { return <section className="rounded border p-4"><h3>{title}</h3><p>{children}</p></section> }
