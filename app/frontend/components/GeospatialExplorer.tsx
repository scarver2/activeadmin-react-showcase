// app/frontend/components/GeospatialExplorer.tsx

import { type GeoJSONSource, Map as MapLibreMap, type MapLayerMouseEvent, Marker, NavigationControl } from "maplibre-gl"
import "maplibre-gl/dist/maplibre-gl.css"
import { useEffect, useRef, useState } from "react"

type Location = { category: string, id: string, latitude: number, longitude: number, name: string, summary: string, url: string }
export type GeospatialExplorerProps = { endpoint: string, initialLocations: Location[] }

const mapContext = {
  type: "FeatureCollection" as const,
  features: [
    { type: "Feature" as const, geometry: { type: "Polygon" as const, coordinates: [[[-96.59, 33.338], [-96.542, 33.338], [-96.542, 33.356], [-96.59, 33.356], [-96.59, 33.338]]] }, properties: { kind: "city" } },
    { type: "Feature" as const, geometry: { type: "LineString" as const, coordinates: [[-96.589, 33.3442], [-96.5765, 33.3445], [-96.5657, 33.3448], [-96.55, 33.345]] }, properties: { kind: "street", name: "West White Street" } },
    { type: "Feature" as const, geometry: { type: "LineString" as const, coordinates: [[-96.5513, 33.339], [-96.5512, 33.357]] }, properties: { kind: "street", name: "Powell Parkway" } },
    { type: "Feature" as const, geometry: { type: "LineString" as const, coordinates: [[-96.557, 33.349], [-96.546, 33.349]] }, properties: { kind: "street", name: "West 4th Street" } },
    { type: "Feature" as const, geometry: { type: "LineString" as const, coordinates: [[-96.584, 33.337], [-96.584, 33.357]] }, properties: { kind: "highway", name: "US 75" } }
  ]
}
const contextLabels = [
  ["Anna, Texas", -96.5605, 33.353], ["West White Street", -96.5705, 33.3436]
] as const

function geoJson(locations: Location[]) {
  return { type: "FeatureCollection" as const, features: locations.map((location) => ({
    type: "Feature" as const,
    geometry: { type: "Point" as const, coordinates: [location.longitude, location.latitude] },
    properties: { id: location.id, name: location.name }
  })) }
}

export default function GeospatialExplorer({ endpoint, initialLocations }: GeospatialExplorerProps) {
  const container = useRef<HTMLDivElement>(null)
  const map = useRef<MapLibreMap | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [ready, setReady] = useState(false)
  const [locations, setLocations] = useState(initialLocations)
  const [selectedId, setSelectedId] = useState(initialLocations[0]?.id || null)
  const selected = locations.find((location) => location.id === selectedId)

  useEffect(() => {
    /* v8 ignore next -- React attaches the ref before running this effect. */
    if (!container.current) return
    const controller = new AbortController()
    const instance = new MapLibreMap({
      attributionControl: false,
      center: [-96.565, 33.347],
      container: container.current,
      style: { version: 8, sources: {}, layers: [{ id: "background", type: "background", paint: { "background-color": "#eef6f4" } }] },
      zoom: 13
    })
    map.current = instance
    instance.addControl(new NavigationControl(), "top-right")
    instance.on("load", () => {
      instance.addSource("context", { type: "geojson", data: mapContext })
      instance.addLayer({ id: "context-region", type: "fill", source: "context", paint: { "fill-color": "#d8eadf", "fill-opacity": 0.78 } })
      instance.addLayer({ id: "context-streets", type: "line", source: "context", paint: { "line-color": "#64748b", "line-width": 5 } })
      contextLabels.forEach(([name, longitude, latitude]) => {
        const marker = document.createElement("div")
        marker.className = "-translate-y-3"
        const label = document.createElement("span")
        label.className = "mt-1 rounded bg-white/90 px-1.5 py-0.5 text-xs font-semibold text-slate-700 shadow"
        label.textContent = name
        marker.append(label)
        new Marker({ element: marker }).setLngLat([longitude, latitude]).addTo(instance)
      })
      initialLocations.forEach((location) => {
        const marker = document.createElement("div")
        marker.className = "flex -translate-y-3 cursor-pointer flex-col items-center"
        marker.setAttribute("aria-hidden", "true")
        marker.title = location.name
        const pin = document.createElement("span")
        pin.className = "h-4 w-4 rounded-full border-2 border-white bg-red-700 shadow"
        const label = document.createElement("span")
        label.className = "mt-1 max-w-36 rounded bg-white/95 px-1.5 py-0.5 text-center text-[10px] font-semibold leading-tight text-slate-800 shadow"
        label.textContent = location.name
        marker.append(pin)
        if (location.name === "Texas Embroidery Ranch") marker.append(label)
        new Marker({ element: marker }).setLngLat([location.longitude, location.latitude]).addTo(instance)
      })
      instance.addSource("locations", { type: "geojson", data: geoJson(initialLocations), cluster: true, clusterMaxZoom: 12, clusterRadius: 38 })
      instance.addLayer({ id: "clusters", type: "circle", source: "locations", filter: ["has", "point_count"], paint: { "circle-color": "#0f766e", "circle-radius": 22, "circle-stroke-color": "#ffffff", "circle-stroke-width": 2 } })
      instance.addLayer({ id: "points", type: "circle", source: "locations", filter: ["!", ["has", "point_count"]], paint: { "circle-color": "#b45309", "circle-radius": 9, "circle-stroke-color": "#ffffff", "circle-stroke-width": 2 } })
      instance.on("click", "points", (event: MapLayerMouseEvent) => {
        const id = event.features?.[0]?.properties?.id as string | undefined
        if (id) setSelectedId(id)
      })
      instance.once("render", () => {
        window.requestAnimationFrame(() => window.requestAnimationFrame(() => setReady(true)))
      })
    })
    instance.on("moveend", async () => {
      const bounds = instance.getBounds()
      setLoading(true)
      setError(null)
      try {
        const query = [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()].join(",")
        const response = await fetch(`${endpoint}?bounds=${encodeURIComponent(query)}`, { credentials: "same-origin", headers: { Accept: "application/json" }, signal: controller.signal })
        const payload = await response.json() as { error?: string, locations?: Location[] }
        if (!response.ok) throw new Error(payload.error || "Locations could not be loaded")
        const next = payload.locations || []
        setLocations(next)
        ;(instance.getSource("locations") as GeoJSONSource | undefined)?.setData(geoJson(next))
      } catch (loadError) {
        if ((loadError as Error).name !== "AbortError") setError((loadError as Error).message)
      } finally {
        if (!controller.signal.aborted) setLoading(false)
      }
    })
    return () => {
      controller.abort()
      instance.remove()
      map.current = null
    }
  }, [endpoint, initialLocations])

  function select(location: Location) {
    setSelectedId(location.id)
    map.current?.flyTo({ center: [location.longitude, location.latitude], zoom: 10 })
  }

  return (
    <section className="space-y-5" data-testid="geospatial-explorer">
      {error && <p className="text-red-700" role="alert">{error}</p>}
      {loading && <p aria-live="polite" role="status">Loading viewport…</p>}
      <div className="relative">
        <div aria-label="Interactive location map" className="h-96 overflow-hidden rounded border" data-ready={ready} data-testid="map" ref={container} />
        <p className="absolute bottom-3 left-3 rounded bg-white/90 px-3 py-2 text-xs shadow">Anna, Texas · local points of interest</p>
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <section aria-label="Locations" className="rounded border p-4"><h3 className="font-semibold">Locations in viewport</h3>
          {locations.length === 0 ? <p>No locations in this region.</p> : <ul className="mt-3 space-y-2">{locations.map((location) => <li key={location.id}><button aria-pressed={selectedId === location.id} className="underline" onClick={() => select(location)} type="button">{location.name}</button> <span>— {location.category}</span></li>)}</ul>}
        </section>
        <section aria-label="Selected location" className="rounded border p-4"><h3 className="font-semibold">Selected location</h3>
          {selected ? <><p className="mt-2 font-semibold">{selected.name}</p><p>{selected.summary}</p><p>{selected.latitude}, {selected.longitude}</p><a className="underline" href={selected.url}>Open Rails record</a></> : <p>Select a location from the list or map.</p>}
        </section>
      </div>
      <div className="grid gap-4 lg:grid-cols-3"><Guidance title="Ruby">Bounded viewport queries and generated resource URLs remain Rails-owned.</Guidance><Guidance title="JavaScript">MapLibre clusters local GeoJSON and synchronizes transient map/list selection.</Guidance><Guidance title="Architecture">No credentials, remote tiles, or provider-specific domain abstraction are required.</Guidance></div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><p className="mt-2 text-sm">{children}</p></section>
}
