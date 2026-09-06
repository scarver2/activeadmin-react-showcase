<!-- docs/roadmap.md -->

# Showcase Roadmap

Create one accomplishment-sized GitHub issue and PR for each item after Sheriff
creates the remote repository. The first priorities are:

1. **Analytics Dashboard** — KPI cards, Recharts visualizations, date filtering, authorized Rails endpoints, refresh states, and optional Cable refresh.
2. **Lexical Editor** — one React island inside an ordinary ActiveAdmin form with meaningful fallback, validation round trips, and documented JSON/HTML persistence.

Delivered showcase slices:

- **Live Jobs / Operations Center** — persistent operation state, Solid Queue work, Solid Cable reconnect/replay, retry/cancellation, provider-neutral telemetry adapters, and real-browser proof. See [Live Jobs](live-jobs.md).

Focused later candidates:

- Advanced TanStack data explorer
- Operator chat
- File and image manager
- Kanban workflow
- Relationship / CRM explorer
- Command palette and global search
- Safe allowlisted terminal console
- Provider-neutral deterministic agent console

Every major page must provide a working demo, what it proves, the Ruby/Arbre and
JavaScript registration snippets, data-flow explanation, upstream libraries,
and a backlink to `activeadmin-react`. Rich application libraries stay in this
repository unless repeated evidence identifies a missing generic gem primitive.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
