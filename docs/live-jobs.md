<!-- docs/live-jobs.md -->

# Live Jobs / Operations Center

The Live Jobs page is the executable reference for asynchronous work in an
ActiveAdmin React island. It demonstrates successful, failed, cancelled, and
retried operations without introducing a database server, Redis, or a telemetry
vendor.

## Demo

Open **Operations → Live Jobs** and start either bounded demo job. Every
operation and event is written to the primary SQLite database before the UI is
updated. The reconnect control briefly drops the actual Action Cable consumer;
the next connection resumes after the client’s last monotonic sequence and
replays missed persistent events.

Cancellation and retry are authenticated Rails commands. Cancellation records
intent; the worker observes it between bounded steps and produces a terminal
`cancelled` event. Retry creates a new operation linked to the terminal original
rather than mutating history.

The HTML fallback can start a successful operation and lists current persistent
state. JavaScript enhances that foundation with progress, actions, telemetry,
and live transport.

## Ruby

```ruby
operation = Operations::Create.call(
  admin_user: current_admin_user,
  kind: "successful_demo"
)
```

`Operations::Transition` serializes each state change under an optimistic lock,
assigns the next sequence and idempotency key, persists both the current state
and immutable event, then broadcasts the saved envelope. `DemoOperationJob`
does the work. `OperationsChannel` only authorizes, streams, and replays; it
never performs expensive work.

## JavaScript

```ts
const operationState = new OperationState({ operationId, sequence })

subscribeToOperation({
  consumer,
  channel: "OperationsChannel",
  params: { operation_id: operationId },
  operationState,
  onEvent: (_event, current) => render(current)
})
```

The showcase consumes the shipped
[`activeadmin-react` operation bridge](https://github.com/scarver2/activeadmin-react#asynchronous-action-cable-operations).
That bridge rejects duplicate idempotency keys, stale sequences, events for a
different operation, and updates after a terminal event. The gem’s `start()`
remains the sole owner of Turbo mount/unmount lifecycle.

## Architecture

```text
authenticated Rails command
        ↓
operation + queued event in primary SQLite
        ↓
Solid Queue → DemoOperationJob → persistent progress events
        ↓
Solid Cable transport and authorized replay
        ↓
activeadmin-react OperationState → React presentation
```

Application-local telemetry adapters report recent request count/p95/errors,
Active Record pool utilization, operation/Cable activity, process CPU time,
Ruby heap estimate, SQLite file size, and database health. They expose plain
hashes, so a future OpenTelemetry or hosted backend can replace collection
without changing the page contract. These values are operational signals for a
single-host showcase, not a replacement for host-level monitoring.

The normalized operation/event schema, foreign keys, unique constraints, and
adapter boundaries remain portable to PostgreSQL if measured concurrency later
justifies scale-out. Solid Queue, Solid Cache, Solid Cable, and SQLite are the
only runtime infrastructure today.

## Verification

- RSpec proves transitions, durable events, bounded completion/failure/cancel,
  authorization, command endpoints, replay, telemetry, and fallback.
- Vitest exercises UI state, live terminal updates, authenticated commands,
  telemetry, guidance, and reconnect controls.
- Playwright uses real Chromium, a real Solid Queue worker, and Solid Cable to
  prove progress/replay, cancellation/retry, and expected failure end to end.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
