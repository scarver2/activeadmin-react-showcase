<!-- docs/calendar-scheduler.md -->

# Calendar Scheduler

The Calendar Scheduler demonstrates FullCalendar 6 inside one ActiveAdmin page
without giving the browser scheduling authority. It is synthetic, deterministic,
credential-free, and backed by the same SQLite database as the rest of the
showcase.

## Demo

Open **Data & Workflows → Calendar Scheduler**. Switch month, week, and day
views, select a time range to create an event, select an event to inspect it,
use the keyboard-accessible one-hour move, or drag an event. Rails accepts a
valid proposal and returns the canonical event; overlap, validation, network,
and stale-write failures restore the previous presentation.

The seeded schedule includes Central, London, Tokyo, and UTC presentation zones.
All instants are stored in UTC. Queries are limited to 93 days, event duration is
limited to 12 hours, and events belonging to one administrator cannot overlap.

## Ruby

`Calendar::EventQuery` scopes events to the authenticated administrator and
validates ISO 8601 range bounds. `Calendar::SaveEvent` parses local input through
an allowlisted Rails time zone, rejects stale lock versions, and persists only
validated `ScheduleEvent` records. `Calendar::EventSerializer` publishes bounded
presentation metadata and server-generated update/edit URLs.

The ordinary `ScheduleEvent` ActiveAdmin resource remains available for create,
show, and edit workflows without JavaScript.

## JavaScript

The `CalendarScheduler` React island uses
[`@fullcalendar/react`](https://fullcalendar.io/docs/react) with the day-grid,
time-grid, and interaction plugins. FullCalendar owns view rendering, selection,
and drag interaction. The component sends authenticated JSON proposals, replaces
accepted events with Rails responses, and calls FullCalendar's rollback contract
when persistence fails.

Vitest covers loading, empty, error, creation, selection, optimistic rescheduling,
rollback, accessibility controls, and request cleanup. Playwright exercises the
real Rails page and FullCalendar interaction in Chromium.

## Architecture

`ScheduleEvent` is an application-owned scheduling record, not a generic
calendar abstraction. FullCalendar remains a showcase dependency. PostgreSQL,
Redis, external calendar providers, recurrence engines, and resource-planning
domains are intentionally absent until measured requirements justify them.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
