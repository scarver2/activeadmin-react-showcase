// app/frontend/components/GeospatialExplorer.tsx

import { type GeoJSONSource, Map as MapLibreMap, type MapLayerMouseEvent, NavigationControl } from "maplibre-gl"
import "maplibre-gl/dist/maplibre-gl.css"
import { useEffect, useRef, useState } from "react"

type Location = { category: string, id: string, latitude: number, longitude: number, name: string, summary: string, url: string }
export type GeospatialExplorerProps = { endpoint: string, initialLocations: Location[] }

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
  const [locations, setLocations] = useState(initialLocations)
  const [selectedId, setSelectedId] = useState(initialLocations[0]?.id || null)
  const selected = locations.find((location) => location.id === selectedId)

  useEffect(() => {
    /* v8 ignore next -- React attaches the ref before running this effect. */
    if (!container.current) return
    const controller = new AbortController()
    const instance = new MapLibreMap({
      attributionControl: false,
      center: [-97.65, 30.2],
      container: container.current,
      style: { version: 8, sources: {}, layers: [{ id: "background", type: "background", paint: { "background-color": "#eef6f4" } }] },
      zoom: 7
    })
    map.current = instance
    instance.addControl(new NavigationControl(), "top-right")
    instance.on("load", () => {
      instance.addSource("locations", { type: "geojson", data: geoJson(initialLocations), cluster: true, clusterMaxZoom: 12, clusterRadius: 45 })
      instance.addLayer({ id: "clusters", type: "circle", source: "locations", filter: ["has", "point_count"], paint: { "circle-color": "#0f766e", "circle-radius": 22 } })
      instance.addLayer({ id: "points", type: "circle", source: "locations", filter: ["!", ["has", "point_count"]], paint: { "circle-color": "#b45309", "circle-radius": 9 } })
      instance.on("click", "points", (event: MapLayerMouseEvent) => {
        const id = event.features?.[0]?.properties?.id as string | undefined
        if (id) setSelectedId(id)
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
      <div aria-label="Interactive location map" className="h-96 overflow-hidden rounded border" data-testid="map" ref={container} />
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
