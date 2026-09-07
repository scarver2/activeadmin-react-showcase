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
  kind: "successful_demo",
  request_idempotency_key: request.headers.fetch("Idempotency-Key")
)
```

`Operations::Transition` serializes each state change under a database lock,
assigns the next sequence and idempotency key, and persists both the current
state and immutable event before attempting a best-effort broadcast. A Cable
failure is logged but cannot roll back durable progress or prevent enqueueing.
`DemoOperationJob` claims a short lease with a fresh execution token and
monotonic generation. Every worker transition verifies and renews that fence,
so overlapping delivery and an expired owner cannot write after takeover.
`OperationsChannel` only authorizes, streams, and replays; it never performs
expensive work.

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
After Action Cable confirms stream activation, the bridge sends its current
cursor through the channel's public `resume` action. It reads the mutable cursor
again on every reconnect, while the channel serializes replay and live delivery.
The bridge rejects duplicate idempotency keys, stale sequences, events for a
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

Application-local telemetry adapters report recent request count/p95/errors
from bounded SQLite samples, Active Record pool utilization, actual Cable
subscriptions and live/replay delivery activity, process CPU time,
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
