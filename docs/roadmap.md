<!-- docs/roadmap.md -->

# Showcase Roadmap

Track each showcase capability in one accomplishment-sized GitHub issue and PR.
Delivered showcase slices:

1. **Analytics Dashboard** — delivered in issue #6 with KPI cards, Recharts visualizations, date filtering, an authorized Rails endpoint, and bounded refresh states.
2. **Lexical Editor** — one React island inside an ordinary ActiveAdmin form with meaningful fallback, validation round trips, and documented JSON/HTML persistence.
3. **Live Jobs / Operations Center** — persistent operation state, Solid Queue work, Solid Cable reconnect/replay, retry/cancellation, provider-neutral telemetry adapters, and real-browser proof. See [Live Jobs](live-jobs.md).
4. **Advanced TanStack data explorer** — authenticated server-backed sorting, filtering, pagination, bounded query controls, semantic table rendering, and real-browser proof. See [Account Data Explorer](data-explorer.md).
5. **Operator Chat** — resettable synthetic participants, Rails-authorized persisted messages, Solid Cable replay, and a focused React conversation island. See [Operator Chat](operator-chat.md).
6. **File & Image Manager** — Active Storage-backed synthetic assets with authorized upload/delete, explicit confirmation, bounded validation, previews, and meaningful Rails fallback. See [File & Image Manager](file-image-manager.md).
7. **Kanban Workflow** — persisted work items, fixed workflow vocabulary, transactionally bounded moves, optimistic rollback, and meaningful Rails fallback. See [Kanban Workflow](kanban-workflow.md).
8. **Provider-neutral deterministic agent console** — authorized prompts, Solid Queue execution, persisted activity/output/citations, cancellation, Solid Cable replay, and no external credential. See [Deterministic Agent Console](agent-console.md).
9. **Relationship and CRM Explorer** — synthetic Accounts and Contacts, bounded Rails-owned search and filtering, useful record navigation, and real-browser proof. See [Relationship and CRM Explorer](relationship-explorer.md).
10. **Command Palette and Global Search** — authenticated, bounded, deterministically ranked search across existing Rails records, keyboard navigation, and a complete no-JavaScript fallback. See [Command Palette and Global Search](command-palette.md).
11. **Safe Terminal Console** — an xterm.js interaction surface over fixed Rails-owned commands, durable SQLite transcripts, Solid Queue execution, Solid Cable replay, and authenticated cancellation. See [Safe Terminal Console](safe-terminal.md).
12. **Calendar Scheduler** — FullCalendar month/week/day views, Rails-owned UTC instants and display zones, bounded queries, overlap policy, optimistic drag rollback, and ordinary ActiveAdmin editing. See [Calendar Scheduler](calendar-scheduler.md).
13. **Hierarchy Explorer** — lazy recursive navigation, Rails-owned adjacency relationships, cycle/depth enforcement, optimistic reparent rollback, and nested ActiveAdmin fallback. See [Hierarchy Explorer](hierarchy-explorer.md).
14. **Activity Center** — durable unread activity, bounded history, local deep links, optimistic rollback, and Solid Cable replay/deduplication. See [Activity Center](activity-center.md).
15. **CSV Import and Column Mapping** — bounded Active Storage input, server-owned mapping and row validation, explicit confirmation, idempotent Solid Queue processing, and durable progress. See [CSV Import](csv-import.md).

Every major page must provide a working demo, what it proves, the Ruby/Arbre and
JavaScript registration snippets, data-flow explanation, upstream libraries,
and a backlink to `activeadmin-react`. Rich application libraries stay in this
repository unless repeated evidence identifies a missing generic gem primitive.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
