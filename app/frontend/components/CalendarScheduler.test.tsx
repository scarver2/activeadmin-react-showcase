// app/frontend/components/CalendarScheduler.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import type { EventApi } from "@fullcalendar/core"

import CalendarScheduler from "./CalendarScheduler"

const calendarHarness = vi.hoisted(() => ({ props: {} as Record<string, unknown> }))

vi.mock("@fullcalendar/react", () => ({
  default: (props: Record<string, unknown>) => {
    calendarHarness.props = props
    return <div data-testid="mock-full-calendar">FullCalendar</div>
  }
}))
vi.mock("@fullcalendar/daygrid", () => ({ default: { name: "day-grid" } }))
vi.mock("@fullcalendar/interaction", () => ({ default: { name: "interaction" } }))
vi.mock("@fullcalendar/timegrid", () => ({ default: { name: "time-grid" } }))

const storedEvent = {
  end: "2026-09-15T15:00:00.000Z",
  extendedProps: {
    editUrl: "/admin/schedule_events/1/edit",
    location: "Austin room",
    lockVersion: 0,
    notes: "Synthetic notes",
    timeZone: "America/Chicago",
    updateUrl: "/admin/calendar/events/1"
  },
  id: "1",
  start: "2026-09-15T14:00:00.000Z",
  title: "Launch review"
}

function renderScheduler(initialEvents = [storedEvent]) {
  return render(<CalendarScheduler endpoint="/admin/calendar/events" initialEvents={initialEvents} timeZones={["America/Chicago", "UTC"]} />)
}

function mockEvent(overrides: Partial<EventApi> = {}) {
  const event = {
    end: new Date(storedEvent.end),
    extendedProps: { ...storedEvent.extendedProps },
    id: storedEvent.id,
    setDates: vi.fn(function setDates(start: Date, end: Date) {
      event.start = start
      event.end = end
    }),
    setExtendedProp: vi.fn(function setExtendedProp(key: string, value: unknown) {
      event.extendedProps = { ...event.extendedProps, [key]: value }
    }),
    start: new Date(storedEvent.start),
    title: storedEvent.title,
    ...overrides
  }
  return event as unknown as EventApi
}

describe("CalendarScheduler", () => {
  beforeEach(() => {
    vi.stubGlobal("fetch", vi.fn())
    document.head.innerHTML = '<meta content="csrf-example" name="csrf-token">'
  })

  afterEach(() => vi.restoreAllMocks())

  it("renders FullCalendar, initial events, toolbar contract, and teaching guidance", () => {
    renderScheduler()

    expect(screen.getByTestId("mock-full-calendar")).toBeInTheDocument()
    expect(calendarHarness.props.events).toEqual([storedEvent])
    expect(calendarHarness.props.initialView).toBe("timeGridWeek")
    expect(calendarHarness.props.timeZone).toBe("UTC")
    expect(screen.getByText("Ruby")).toBeInTheDocument()
    expect(screen.getByText("JavaScript")).toBeInTheDocument()
    expect(screen.getByText("Architecture")).toBeInTheDocument()
  })

  it("opens, edits, and cancels the keyboard-accessible creation form", () => {
    renderScheduler([])
    expect(screen.getByText("No events are scheduled in this range.")).toBeInTheDocument()

    fireEvent.click(screen.getByRole("button", { name: "Create event" }))
    fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Planning" } })
    fireEvent.change(screen.getByLabelText("Time zone"), { target: { value: "UTC" } })
    fireEvent.change(screen.getByLabelText("Starts"), { target: { value: "2026-09-16T10:00" } })
    fireEvent.change(screen.getByLabelText("Ends"), { target: { value: "2026-09-16T11:00" } })
    fireEvent.change(screen.getByLabelText("Location"), { target: { value: "Room 2" } })
    fireEvent.change(screen.getByLabelText("Notes"), { target: { value: "Notes" } })
    expect(screen.getByDisplayValue("Planning")).toBeInTheDocument()
    expect(screen.getByDisplayValue("UTC")).toBeInTheDocument()
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))
    expect(screen.queryByRole("region", { name: "Create scheduled event" })).not.toBeInTheDocument()
  })

  it("creates and appends a canonical event with CSRF protection", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ event: storedEvent }), { status: 201 }))
    renderScheduler([])
    fireEvent.click(screen.getByRole("button", { name: "Create event" }))
    fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Launch review" } })
    fireEvent.click(screen.getByRole("button", { name: "Save event" }))

    await waitFor(() => expect(calendarHarness.props.events).toEqual([storedEvent]))
    expect(fetch).toHaveBeenCalledWith("/admin/calendar/events", expect.objectContaining({
      headers: expect.objectContaining({ "X-CSRF-Token": "csrf-example" }),
      method: "POST"
    }))
    expect(screen.queryByLabelText("Create scheduled event")).not.toBeInTheDocument()
  })

  it("keeps the creation form open for server and network errors", async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: "Overlap denied" }), { status: 422 }))
      .mockRejectedValueOnce(new Error("Offline"))
    renderScheduler([])
    fireEvent.click(screen.getByRole("button", { name: "Create event" }))
    fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Blocked" } })
    fireEvent.click(screen.getByRole("button", { name: "Save event" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Overlap denied")

    fireEvent.click(screen.getByRole("button", { name: "Save event" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Offline")
  })

  it("uses a generic creation error when a successful response omits its event", async () => {
    document.head.innerHTML = ""
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({}), { status: 200 }))
    renderScheduler([])
    fireEvent.click(screen.getByRole("button", { name: "Create event" }))
    fireEvent.change(screen.getByLabelText("Title"), { target: { value: "Missing" } })
    fireEvent.click(screen.getByRole("button", { name: "Save event" }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Calendar event creation failed")
    expect(fetch).toHaveBeenCalledWith("/admin/calendar/events", expect.objectContaining({
      headers: expect.objectContaining({ "X-CSRF-Token": "" })
    }))
  })

  it("loads bounded view ranges and handles empty and rejected responses", async () => {
    vi.mocked(fetch)
      .mockResolvedValueOnce(new Response(JSON.stringify({ events: [storedEvent] }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ error: "Range rejected" }), { status: 400 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
    renderScheduler([])
    const datesSet = calendarHarness.props.datesSet as (range: unknown) => Promise<void>
    const range = { start: new Date("2026-09-01T00:00:00Z"), end: new Date("2026-10-01T00:00:00Z") }

    await act(() => datesSet(range))
    expect(calendarHarness.props.events).toEqual([storedEvent])
    expect(fetch).toHaveBeenCalledWith(expect.objectContaining({ search: "?start=2026-09-01T00%3A00%3A00.000Z&end=2026-10-01T00%3A00%3A00.000Z" }), expect.anything())

    await act(() => datesSet(range))
    expect(screen.getByText("No events are scheduled in this range.")).toBeInTheDocument()

    await act(() => datesSet(range))
    expect(screen.getByRole("alert")).toHaveTextContent("Range rejected")

    await act(() => datesSet(range))
    expect(screen.getByRole("alert")).toHaveTextContent("Calendar loading failed")
  })

  it("ignores aborted loads, aborts superseded requests, and cleans up on unmount", async () => {
    const abortSpy = vi.spyOn(AbortController.prototype, "abort")
    vi.mocked(fetch).mockRejectedValue(Object.assign(new Error("Aborted"), { name: "AbortError" }))
    const rendered = renderScheduler([])
    const datesSet = calendarHarness.props.datesSet as (range: unknown) => Promise<void>
    const range = { start: new Date("2026-09-01T00:00:00Z"), end: new Date("2026-10-01T00:00:00Z") }

    await act(() => datesSet(range))
    expect(screen.queryByRole("alert")).not.toBeInTheDocument()
    await act(() => datesSet(range))
    expect(abortSpy).toHaveBeenCalled()
    rendered.unmount()
    expect(abortSpy).toHaveBeenCalledTimes(2)
  })

  it("does not clear loading from a superseded aborted request", async () => {
    vi.mocked(fetch)
      .mockImplementationOnce((_input, init) => new Promise((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () => reject(Object.assign(new Error("Aborted"), { name: "AbortError" })))
      }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ events: [storedEvent] }), { status: 200 }))
    renderScheduler([])
    const datesSet = calendarHarness.props.datesSet as (range: unknown) => Promise<void>
    const range = { start: new Date("2026-09-01T00:00:00Z"), end: new Date("2026-10-01T00:00:00Z") }

    await act(async () => {
      const superseded = datesSet(range)
      await datesSet(range)
      await superseded
    })

    expect(calendarHarness.props.events).toEqual([storedEvent])
    expect(screen.queryByRole("status")).not.toBeInTheDocument()
  })

  it("creates from a selected range and clears FullCalendar selection", () => {
    renderScheduler()
    const unselect = vi.fn()
    const select = calendarHarness.props.select as (selection: unknown) => void

    act(() => select({
      end: new Date("2026-09-17T12:00:00Z"),
      start: new Date("2026-09-17T11:00:00Z"),
      view: { calendar: { unselect } }
    }))

    expect(screen.getByLabelText("Starts")).toHaveValue("2026-09-17T11:00")
    expect(unselect).toHaveBeenCalled()
  })

  it("shows event metadata and persists an accessible one-hour move", async () => {
    const canonical = { ...storedEvent, start: "2026-09-15T15:00:00.000Z", end: "2026-09-15T16:00:00.000Z", extendedProps: { ...storedEvent.extendedProps, lockVersion: 1 } }
    const otherEvent = { ...storedEvent, id: "2", title: "Other event" }
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ event: canonical }), { status: 200 }))
    renderScheduler([storedEvent, otherEvent])
    const event = mockEvent()
    const eventClick = calendarHarness.props.eventClick as (selection: unknown) => void
    act(() => eventClick({ event }))

    expect(screen.getByRole("region", { name: "Selected event" })).toHaveTextContent("Austin room")
    expect(screen.getByText("Synthetic notes")).toBeInTheDocument()
    fireEvent.click(screen.getByRole("button", { name: "Move one hour later" }))

    await waitFor(() => expect(event.setExtendedProp).toHaveBeenCalledWith("lockVersion", 1))
    expect(calendarHarness.props.events).toEqual([canonical, otherEvent])
    expect(event.setDates).toHaveBeenCalledWith(new Date(canonical.start), new Date(canonical.end))
    expect(fetch).toHaveBeenCalledWith(storedEvent.extendedProps.updateUrl, expect.objectContaining({ method: "PATCH" }))
  })

  it("reverts a rejected drag and reports a generic reschedule error", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({}), { status: 500 }))
    renderScheduler()
    const revert = vi.fn()
    const eventDrop = calendarHarness.props.eventDrop as (drop: unknown) => void
    act(() => eventDrop({ event: mockEvent(), revert }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Calendar reschedule failed. The calendar was restored.")
    expect(revert).toHaveBeenCalled()
  })

  it("restores an accessible move after a stale response and handles events without a duration", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ error: "Stale event" }), { status: 409 }))
    renderScheduler()
    const eventClick = calendarHarness.props.eventClick as (selection: unknown) => void
    const event = mockEvent({ extendedProps: { ...storedEvent.extendedProps, location: null, notes: null } })
    act(() => eventClick({ event }))
    expect(screen.getByRole("region", { name: "Selected event" })).toHaveTextContent("No location")
    fireEvent.click(screen.getByRole("button", { name: "Move one hour later" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Stale event. The calendar was restored.")
    expect(event.setDates).toHaveBeenCalledTimes(2)

    act(() => eventClick({ event: mockEvent({ end: null }) }))
    vi.mocked(fetch).mockClear()
    fireEvent.click(screen.getByRole("button", { name: "Move one hour later" }))
    expect(fetch).not.toHaveBeenCalled()
  })
})
