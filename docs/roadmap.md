<!-- docs/roadmap.md -->

# Showcase Roadmap

Track each showcase capability in one accomplishment-sized GitHub issue and PR.
Delivered showcase slices:

1. **Analytics Dashboard** — delivered in issue #6 with KPI cards, Recharts visualizations, date filtering, an authorized Rails endpoint, and bounded refresh states.
2. **Lexical Editor** — one React island inside an ordinary ActiveAdmin form with meaningful fallback, validation round trips, and documented JSON/HTML persistence.
3. **Live Jobs / Operations Center** — persistent operation state, Solid Queue work, Solid Cable reconnect/replay, retry/cancellation, provider-neutral telemetry adapters, and real-browser proof. See [Live Jobs](live-jobs.md).
4. **File & Image Manager** — Active Storage-backed synthetic assets with authorized upload/delete/reset, bounded validation, previews, and meaningful Rails fallback. See [File & Image Manager](file-image-manager.md).

Focused later candidates:

- Advanced TanStack data explorer
- Operator chat
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
