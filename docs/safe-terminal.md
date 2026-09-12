<!-- docs/safe-terminal.md -->

# Safe Terminal Console

The **Operations → Safe Terminal** page demonstrates a terminal-shaped admin
workflow without exposing a shell. It uses the real xterm.js renderer, but Rails
accepts only these exact application-owned command keys:

- `showcase:status`
- `showcase:backup:verify`
- `showcase:deploy:plan`

Arguments, shell syntax, environment interpolation, executable paths, and
arbitrary programs are deliberately unsupported. Each key maps to a fixed,
deterministic set of bounded demo steps in `SafeTerminal::Commands`.

## Ruby

`SafeTerminal::Create` authorizes through the signed-in ActiveAdmin user,
validates the exact registry key, deduplicates with a request idempotency key,
and persists the execution and first transcript line before enqueueing
`SafeTerminalDemoJob`. The worker reads only the fixed registry and appends
bounded output under a database lock. `SafeTerminal::Cancel` is an authenticated,
owner-scoped Rails command; workers stop before the next step after cancellation.

The transcript is durable SQLite application state. Solid Queue performs the
work. Solid Cable is transport only: losing Cable cannot lose or fail the job,
and broadcast errors are isolated from persistence.

## JavaScript

`SafeTerminal.tsx` owns the xterm.js instance and accepts keyboard input only
when it exactly matches a command advertised by Rails. Buttons expose the same
catalog. Control characters are stripped from server output before rendering.

Each active execution subscribes to `SafeTerminalChannel`. After Action Cable
confirms the stream, the client sends its current sequence cursor with `resume`.
Rails replays committed transcript rows in order, buffers output committed
during activation, and then switches to live delivery. Duplicate or stale
sequences are ignored; terminal subscriptions are released promptly.

## Architecture and security boundary

```text
allowlisted key → authenticated Rails command → SQLite execution/transcript
                                               ↓
                                         Solid Queue job
                                               ↓
SQLite replay/source of truth → Solid Cable transport → React + xterm.js
```

This example does not call a shell API (`system`, `spawn`, backticks, or
equivalents). Adding a command requires a reviewed registry definition and
security tests. Never turn command input into a process string. The HTML fallback
retains the catalog, durable transcript, cancellation, and implementation
guidance when JavaScript is unavailable.

Run focused checks with:

```sh
mise exec -- bundle exec rspec spec/models/terminal_* spec/services/safe_terminal_spec.rb spec/jobs/safe_terminal_demo_job_spec.rb spec/requests/safe_terminal_spec.rb spec/channels/safe_terminal_channel_spec.rb
/usr/local/bin/npm run test:run -- app/frontend/components/SafeTerminal.test.tsx
/usr/local/bin/npm run browser:test -- test/browser/safe_terminal.spec.ts
```

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
