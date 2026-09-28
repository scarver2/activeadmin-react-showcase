<!-- docs/roadmap.md -->

# Showcase Roadmap

Track each showcase capability in one accomplishment-sized GitHub issue and PR.
Delivered showcase slices:

1. **Analytics Dashboard** — delivered in issue #6 with KPI cards, Recharts visualizations, date filtering, an authorized Rails endpoint, and bounded refresh states.
2. **Lexical WYSIWYG Editor** — official Lexical React packages, a familiar accessible toolbar, Rails-validated canonical JSON and links, derived safe HTML, optimistic concurrency, meaningful fallback, and real-browser proof. See [Lexical WYSIWYG Editor](lexical-editor.md).
3. **Live Jobs / Operations Center** — persistent operation state, Solid Queue work, Solid Cable reconnect/replay, retry/cancellation, provider-neutral telemetry adapters, and real-browser proof. See [Live Jobs](live-jobs.md).
4. **Advanced TanStack data explorer** — authenticated server-backed sorting, filtering, pagination, bounded query controls, semantic table rendering, and real-browser proof. See [Account Data Explorer](data-explorer.md).
5. **Operator Chat** — resettable synthetic participants, Rails-authorized persisted messages, Solid Cable replay, and a focused React conversation island. See [Operator Chat](operator-chat.md).
6. **File & Image Manager** — Active Storage-backed synthetic assets with authorized upload/delete, explicit confirmation, bounded validation, previews, and meaningful Rails fallback. See [File & Image Manager](file-image-manager.md).
7. **Kanban Workflow** — persisted work items, fixed workflow vocabulary, transactionally bounded moves, optimistic rollback, and meaningful Rails fallback. See [Kanban Workflow](kanban-workflow.md).
8. **Provider-neutral deterministic agent console** — authorized prompts, Solid Queue execution, persisted activity/output/citations, cancellation, Solid Cable replay, and no external credential. See [Deterministic Agent Console](agent-console.md).
9. **Relationship and CRM Explorer** — synthetic Accounts and Contacts, bounded Rails-owned search and filtering, useful record navigation, and real-browser proof. See [Relationship and CRM Explorer](relationship-explorer.md).
10. **Global Search contract** — authenticated, bounded, deterministically ranked search across Rails-owned workspace pages and existing records, one global header control, keyboard navigation, and a complete no-JavaScript fallback. The richer issue #88 Command Palette remains downstream. See [Command Palette and Global Search](command-palette.md).
11. **Safe Terminal Console** — an xterm.js interaction surface over fixed Rails-owned commands, durable SQLite transcripts, Solid Queue execution, Solid Cable replay, and authenticated cancellation. See [Safe Terminal Console](safe-terminal.md).
12. **Calendar Scheduler** — FullCalendar month/week/day views, Rails-owned UTC instants and display zones, bounded queries, overlap policy, optimistic drag rollback, and ordinary ActiveAdmin editing. See [Calendar Scheduler](calendar-scheduler.md).
13. **Hierarchy Explorer** — lazy recursive navigation over Ancestry tree mechanics, Rails-owned authorization/depth/order policy, optimistic reparent rollback, and nested ActiveAdmin fallback. See [Hierarchy Explorer](hierarchy-explorer.md).
14. **Onboarding Wizard** — resumable Rails-owned drafts, conditional fields, validation round trips, review, submission, and stale-write protection. See [Onboarding Wizard](onboarding-wizard.md).
15. **Audit History** — deterministic PaperTrail provenance, structured `paper_trail_diff` comparisons, field filtering, and non-mutating restoration previews. See [Audit History](audit-history.md).
16. **Notifications and Activity Center** — a live accessible title-bar unread projection, durable activity history, local deep links, optimistic rollback, and Solid Cable replay/deduplication. See [Activity Center](activity-center.md).
17. **Content Builder** — a bounded Rails-owned document schema with allowlisted blocks, transactional saves, live React preview, drag and keyboard ordering, optimistic rollback, and readable server fallback. See [Content Builder](content-builder.md).
18. **CSV Import and Column Mapping** — bounded Active Storage input, server-owned mapping and row validation, explicit confirmation, idempotent Solid Queue processing, and durable progress. See [CSV Import](csv-import.md).
19. **Image Editor & Annotation Studio** — nondestructive crop, rotation, flips, tonal filters, focal/region metadata, responsive pointer interaction, accessible controls, and Rails-enforced recipes over immutable Active Storage originals. See [Image Editor & Annotation Studio](image-annotation.md).
20. **Social Relationship Graph** — a sparse cross-generation synthetic network with labeled canonical edges, bounded first- through third-degree projections, mutual connections, accessible paths, and Cytoscape highlighting. See [Social Relationship Graph](social-network.md).
21. **Optimistic Inline Editing** — small field-level islands, record-and-field authorization, validation, stale-write recovery, rollback, and complete ActiveAdmin navigation. See [Inline Editing](inline-editing.md).
22. **Development Message Preview** — `letter_opener_web` delivery, sandboxed HTML/text inspection, allowlisted rich attachments, and direct server fallback. See [Development Message Preview](message-preview.md).
23. **Three.js Material Sphere Studio** — a procedural glossy red sphere, Rails-owned allowlisted physical-material recipes, optimistic rollback, named camera views, lifecycle-safe WebGL cleanup, and real-browser proof. See [Material Sphere Studio](material-sphere-studio.md).

Every major page must provide a working demo, what it proves, the Ruby/Arbre and
JavaScript registration snippets, data-flow explanation, upstream libraries,
and a backlink to `activeadmin-react`. Rich application libraries stay in this
repository unless repeated evidence identifies a missing generic gem primitive.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
