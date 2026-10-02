// app/frontend/components/ActivityTimeline.tsx

import { useState } from "react"

export type TimelineEvent = {
  actor: string
  details: Record<string, string>
  family: string
  id: string
  occurredAt: string
  sourceUrl: string | null
  state: string
  summary: string
}
export type ActivityTimelineProps = {
  families: Record<string, string>
  filters: { group: string }
  items: TimelineEvent[]
  nextUrl: string | null
  pageSize: number
  startUrl: string
}

export default function ActivityTimeline({ families, filters, items, nextUrl, pageSize, startUrl }: ActivityTimelineProps) {
  const [expanded, setExpanded] = useState<string[]>([])
  const groups = new Map<string, TimelineEvent[]>()
  items.forEach(event => {
    const label = filters.group === "family" ? families[event.family] : filters.group === "actor" ? event.actor : event.occurredAt.slice(0, 10)
    const events = groups.get(label) ?? []
    events.push(event)
    groups.set(label, events)
  })

  return <section aria-label="Activity history" data-testid="activity-timeline" className="space-y-4">
    <p>{items.length} events on this page (maximum {pageSize}); newest first within each group. Source context stays with its owning domain.</p>
    {items.length === 0 && <p role="status">No events match these filters.</p>}
    {[...groups].map(([label, events]) => <section aria-label={label} key={label}>
      <h2 className="mb-3 text-xl font-semibold">{label}</h2>
      <ol className="space-y-3">
        {events.map(event => <li className="rounded border p-4" key={event.id}>
          <p className="text-sm">{families[event.family]} · {event.actor} · <time dateTime={event.occurredAt}>{event.occurredAt.replace("T", " ").replace("Z", " UTC")}</time></p>
          <h3 className="my-2 font-semibold">{event.summary}</h3>
          {event.sourceUrl && <>
            <button aria-controls={`context-${event.id}`} aria-expanded={expanded.includes(event.id)} className="mr-4 rounded border px-3 py-2" onClick={() => setExpanded(current => current.includes(event.id) ? current.filter(id => id !== event.id) : [...current, event.id])} type="button">Context for {event.id}</button>
            <a className="underline" href={event.sourceUrl}>Open source {event.id}</a>
            <dl className="mt-3" hidden={!expanded.includes(event.id)} id={`context-${event.id}`}>
              {Object.entries(event.details).map(([key, value]) => <div key={key}><dt className="font-semibold">{key}</dt><dd className="break-words">{value}</dd></div>)}
            </dl>
          </>}
        </li>)}
      </ol>
    </section>)}
    <nav aria-label="Timeline pages" className="flex flex-wrap gap-4">
      {nextUrl && <a className="rounded border px-4 py-2" href={nextUrl}>Older events</a>}
      <a className="rounded border px-4 py-2" href={startUrl}>Newest events</a>
    </nav>
  </section>
}
