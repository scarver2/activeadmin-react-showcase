// app/frontend/components/CalendarScheduler.tsx

import dayGridPlugin from "@fullcalendar/daygrid"
import interactionPlugin from "@fullcalendar/interaction"
import FullCalendar from "@fullcalendar/react"
import timeGridPlugin from "@fullcalendar/timegrid"
import { useEffect, useRef, useState } from "react"
import type { DateSelectArg, DatesSetArg, EventApi, EventClickArg, EventDropArg, EventInput } from "@fullcalendar/core"
import type { FormEvent } from "react"

type CalendarEvent = EventInput & {
  id: string
  extendedProps: {
    editUrl: string
    location: string | null
    lockVersion: number
    notes: string | null
    timeZone: string
    updateUrl: string
  }
}

type Draft = {
  end: string
  location: string
  notes: string
  start: string
  timeZone: string
  title: string
}

export type CalendarSchedulerProps = {
  endpoint: string
  initialEvents: CalendarEvent[]
  timeZones: string[]
}

const ONE_HOUR_MS = 60 * 60 * 1_000

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

function localInput(date: Date) {
  return date.toISOString().slice(0, 16)
}

function calendarEvent(event: EventApi): CalendarEvent {
  return {
    end: event.end?.toISOString(),
    extendedProps: event.extendedProps as CalendarEvent["extendedProps"],
    id: event.id,
    start: event.start?.toISOString(),
    title: event.title
  }
}

async function responsePayload(response: Response) {
  return await response.json() as { error?: string, event?: CalendarEvent, events?: CalendarEvent[] }
}

export default function CalendarScheduler({ endpoint, initialEvents, timeZones }: CalendarSchedulerProps) {
  const [draft, setDraft] = useState<Draft | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [events, setEvents] = useState<CalendarEvent[]>(initialEvents)
  const [loading, setLoading] = useState(false)
  const [selectedEvent, setSelectedEvent] = useState<EventApi | null>(null)
  const requestController = useRef<AbortController | null>(null)

  useEffect(() => () => requestController.current?.abort(), [])

  async function loadRange({ end, start }: DatesSetArg) {
    requestController.current?.abort()
    const controller = new AbortController()
    requestController.current = controller
    setLoading(true)
    setError(null)

    try {
      const url = new URL(endpoint, window.location.origin)
      url.searchParams.set("start", start.toISOString())
      url.searchParams.set("end", end.toISOString())
      const response = await fetch(url, { credentials: "same-origin", headers: { Accept: "application/json" }, signal: controller.signal })
      const payload = await responsePayload(response)
      if (!response.ok) throw new Error(payload.error || "Calendar loading failed")
      setEvents(payload.events || [])
    } catch (loadError) {
      if ((loadError as Error).name !== "AbortError") setError((loadError as Error).message)
    } finally {
      if (requestController.current === controller) setLoading(false)
    }
  }

  function openDraft(start: Date, end: Date) {
    setDraft({ end: localInput(end), location: "", notes: "", start: localInput(start), timeZone: timeZones[0], title: "" })
    setError(null)
  }

  async function createEvent(submission: FormEvent, eventDraft: Draft) {
    submission.preventDefault()

    setError(null)
    try {
      const response = await fetch(endpoint, {
        body: JSON.stringify({ event: {
          ends_at: eventDraft.end,
          location: eventDraft.location,
          notes: eventDraft.notes,
          starts_at: eventDraft.start,
          time_zone: eventDraft.timeZone,
          title: eventDraft.title
        } }),
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        method: "POST"
      })
      const payload = await responsePayload(response)
      if (!response.ok || !payload.event) throw new Error(payload.error || "Calendar event creation failed")
      setEvents((current) => [...current, payload.event!])
      setDraft(null)
    } catch (createError) {
      setError((createError as Error).message)
    }
  }

  async function persistMove(event: EventApi, rollback: () => void) {
    const details = calendarEvent(event)
    setError(null)
    try {
      const response = await fetch(details.extendedProps.updateUrl, {
        body: JSON.stringify({
          event: { ends_at: details.end, starts_at: details.start, time_zone: details.extendedProps.timeZone },
          lock_version: details.extendedProps.lockVersion
        }),
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        method: "PATCH"
      })
      const payload = await responsePayload(response)
      if (!response.ok || !payload.event) throw new Error(payload.error || "Calendar reschedule failed")
      setEvents((current) => current.map((candidate) => candidate.id === payload.event!.id ? payload.event! : candidate))
      event.setExtendedProp("lockVersion", payload.event.extendedProps.lockVersion)
      setSelectedEvent(event)
    } catch (moveError) {
      rollback()
      setError(`${(moveError as Error).message}. The calendar was restored.`)
    }
  }

  function dropEvent({ event, revert }: EventDropArg) {
    void persistMove(event, revert)
  }

  function moveSelectedLater() {
    if (!selectedEvent?.start || !selectedEvent.end) return

    const priorStart = selectedEvent.start
    const priorEnd = selectedEvent.end
    selectedEvent.setDates(new Date(priorStart.getTime() + ONE_HOUR_MS), new Date(priorEnd.getTime() + ONE_HOUR_MS))
    void persistMove(selectedEvent, () => selectedEvent.setDates(priorStart, priorEnd))
  }

  function selectRange({ end, start, view }: DateSelectArg) {
    openDraft(start, end)
    view.calendar.unselect()
  }

  function selectEvent({ event }: EventClickArg) {
    setSelectedEvent(event)
  }

  function newEvent() {
    const start = new Date()
    start.setUTCMinutes(0, 0, 0)
    openDraft(start, new Date(start.getTime() + ONE_HOUR_MS))
  }

  return (
    <section className="space-y-5" data-testid="calendar-scheduler">
      <div className="flex flex-wrap items-center gap-3">
        <button className="rounded bg-blue-700 px-3 py-2 text-white" onClick={newEvent} type="button">Create event</button>
        {loading && <p aria-live="polite" role="status">Loading schedule…</p>}
        {error && <p className="text-red-700" role="alert">{error}</p>}
      </div>

      {events.length === 0 && !loading && <p>No events are scheduled in this range.</p>}
      <div className="rounded border bg-white p-3 text-gray-900" data-testid="full-calendar">
        <FullCalendar
          datesSet={(range) => void loadRange(range)}
          editable
          eventClick={selectEvent}
          eventDrop={dropEvent}
          events={events}
          headerToolbar={{ center: "title", left: "prev,next today", right: "dayGridMonth,timeGridWeek,timeGridDay" }}
          initialView="timeGridWeek"
          plugins={[dayGridPlugin, timeGridPlugin, interactionPlugin]}
          select={selectRange}
          selectable
          timeZone="UTC"
        />
      </div>

      {selectedEvent && (
        <section aria-label="Selected event" className="rounded border p-4">
          <h2 className="font-semibold">{selectedEvent.title}</h2>
          <p>{selectedEvent.extendedProps.timeZone} · {selectedEvent.extendedProps.location || "No location"}</p>
          {selectedEvent.extendedProps.notes && <p>{selectedEvent.extendedProps.notes}</p>}
          <div className="mt-3 flex gap-2">
            <button className="rounded border px-3 py-2" onClick={moveSelectedLater} type="button">Move one hour later</button>
            <a className="rounded border px-3 py-2" href={selectedEvent.extendedProps.editUrl}>Open Rails edit form</a>
          </div>
        </section>
      )}

      {draft && (
        <section aria-label="Create scheduled event" className="rounded border p-4">
          <h2 className="font-semibold">Create scheduled event</h2>
          <form className="mt-3 grid gap-3 md:grid-cols-2" onSubmit={(submission) => void createEvent(submission, draft)}>
            <label>Title<input className="block w-full rounded border p-2" maxLength={120} onChange={(change) => setDraft({ ...draft, title: change.target.value })} required value={draft.title} /></label>
            <label>Time zone<select className="block w-full rounded border p-2" onChange={(change) => setDraft({ ...draft, timeZone: change.target.value })} value={draft.timeZone}>{timeZones.map((zone) => <option key={zone}>{zone}</option>)}</select></label>
            <label>Starts<input className="block w-full rounded border p-2" onChange={(change) => setDraft({ ...draft, start: change.target.value })} required type="datetime-local" value={draft.start} /></label>
            <label>Ends<input className="block w-full rounded border p-2" onChange={(change) => setDraft({ ...draft, end: change.target.value })} required type="datetime-local" value={draft.end} /></label>
            <label>Location<input className="block w-full rounded border p-2" maxLength={120} onChange={(change) => setDraft({ ...draft, location: change.target.value })} value={draft.location} /></label>
            <label>Notes<textarea className="block w-full rounded border p-2" maxLength={500} onChange={(change) => setDraft({ ...draft, notes: change.target.value })} value={draft.notes} /></label>
            <div className="flex gap-2 md:col-span-2">
              <button className="rounded bg-blue-700 px-3 py-2 text-white" type="submit">Save event</button>
              <button className="rounded border px-3 py-2" onClick={() => setDraft(null)} type="button">Cancel</button>
            </div>
          </form>
        </section>
      )}

      <div className="grid gap-4 lg:grid-cols-3">
        <Guidance title="Ruby"><code>Calendar::SaveEvent.call(...)</code><p>Rails scopes ownership, normalizes zones, rejects overlaps, and detects stale writes.</p></Guidance>
        <Guidance title="JavaScript"><code>select / eventDrop → JSON → canonical event</code><p>FullCalendar renders interaction; rejected optimistic moves invoke its rollback.</p></Guidance>
        <Guidance title="Architecture"><p>UTC instants and an allowlisted display zone remain portable SQLite records. Calendar UI state is never persistence authority.</p></Guidance>
      </div>
    </section>
  )
}

function Guidance({ children, title }: { children: React.ReactNode, title: string }) {
  return <section className="rounded border p-4"><h3 className="font-semibold">{title}</h3><div className="mt-2 space-y-2 text-sm">{children}</div></section>
}
