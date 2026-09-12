<!-- ARCHITECTURE.md -->

# Architecture

The application is Rails-first. ActiveAdmin owns the document, navigation,
authentication, authorization, form contracts, and meaningful server fallback.
`activeadmin-react` supplies mount and lifecycle primitives. Application-owned
React components consume authorized Rails data and may subscribe to state
transported by Action Cable.

```text
Rails / ActiveAdmin / Arbre
          |
          v
activeadmin-react mount contract
          |
          v
showcase-owned React component
```

Background work follows one rule: a job performs work, persistent application
state records progress, Solid Cable transports state, and React displays it.
Cable never performs expensive work.

File management follows the same Rails-first boundary. Active Storage owns blob
metadata and bytes, `ShowcaseAsset` allowlists formats and enforces a 5 MB limit,
and authenticated controllers own upload and delete. Page rendering only reads
persisted records; seeds and maintenance tooling provision deterministic demo
state. React receives only signed application URLs and presentation metadata—never storage credentials.
Production's local Active Storage root is part of the persistent Kamal-mounted
storage and the documented SQLite/volume backup boundary.

Kanban work items are persisted records; columns are fixed state-machine
vocabulary. React proposes a target state and position, while Rails validates
ordering bounds, transactionally resequences affected columns, and returns the
canonical board. Browser optimism is always reconciled or visibly rolled back.

Operator Chat applies the same rule to collaboration: Rails chooses the
authenticated operator from persisted room participants, validates and commits
every message with a participant foreign key, and owns the deterministic reset.
Solid Cable only delivers persisted message envelopes and bounded replay after
a sequence cursor. The browser cannot select or spoof a participant identity.

The deterministic agent console records an administrator-owned `AgentRun` and
an ordered `AgentEvent` history before transporting activity, response,
citation, and result events through Solid Cable. Solid Queue performs bounded
credential-free work; React renders state and requests cancellation but does not
define lifecycle meaning. Providers and tools remain fixed application rules,
not speculative records.

The [Live Jobs / Operations Center](docs/live-jobs.md) makes this boundary
executable. An authenticated Rails command persists the operation before Solid
Queue receives it. Each transition appends a uniquely sequenced event. Solid
Cable authorizes and transports snapshots/replay, while the shipped
`activeadmin-react` operation state rejects duplicates and stale events.

## Initial topology

One Rails container runs Puma and the Solid Queue supervisor. Four SQLite files
hold primary, queue, cache, and cable data on one persistent Kamal volume. Daily
consistent snapshots go to a separate host bind mount that must be copied to
encrypted off-host storage.

This topology minimizes cost and operational surface for the showcase. Scale-out
begins only after measurements show a need. The first database escalation is a
documented adapter migration to PostgreSQL; Redis is introduced only for a
measured cache, queue, or fan-out constraint.

## Trust boundaries

- Rails authorizes every data endpoint and mutation.
- Component props contain no credentials or sensitive tenant context.
- Public examples use resettable demo data and bounded actions.
- Terminal and agent examples will use allowlisted or deterministic backends.
- No showcase dependency becomes a gem runtime dependency by default.

## Rich-text boundary

The Lexical Editor is an application-owned enhancement of one ActiveAdmin form
field. Its serialized JSON is checked for a Lexical root and canonicalized;
its rendered HTML is independently sanitized on the server before either value
is persisted. A `noscript` textarea enters through the same model boundary and
is converted into safe JSON and HTML. Lexical remains a showcase dependency and
does not expand `activeadmin-react`.

The initial editor form opts out of Turbo submission so a validation response is
a full Rails page load. `activeadmin-react 0.1` listens for navigation lifecycle
events but does not currently remount an island after Turbo replaces a form with
a `422` response. Keeping that limitation explicit preserves correct behavior
without adding generic lifecycle policy to this application.

## Server-backed table boundary

The [Account Data Explorer](docs/data-explorer.md) keeps TanStack Table headless
and browser-only. Rails authenticates the request, validates fixed query bounds,
composes the Active Record relation, and returns resource URLs plus pagination
metadata. The browser never selects database columns or supplies SQL.

## Relationship data boundary

The [Relationship and CRM Explorer](docs/relationship-explorer.md) introduces
only normalized Accounts and Contacts. Rails validates and persists them,
authorizes the JSON endpoint, allowlists query controls, caps search text and
result size, and generates record URLs. React owns transient search and
master-detail selection only. Pipelines, campaigns, activity streams, write
workflows, and real-PII policy remain outside this focused demonstration.

## Global search boundary

The [Command Palette](docs/command-palette.md) queries existing Accounts and
Showcase Articles through one authenticated, bounded Rails service. Rails owns
searchable fields, deterministic relevance, result limits, descriptions, and
ActiveAdmin URLs. React owns only dialog and keyboard interaction. The ordinary
GET fallback calls the same service, so disabling JavaScript does not change
authorization or ranking.

There is no `SearchResult` persistence model or speculative index. The bounded
SQLite query is appropriate for the current showcase data and keeps a future
PostgreSQL migration straightforward. Specialized search infrastructure is a
measured scale or relevance decision, not an initial dependency.

## Calendar boundary

The [Calendar Scheduler](docs/calendar-scheduler.md) persists UTC instants and
an allowlisted presentation time zone on administrator-owned `ScheduleEvent`
records. Rails bounds range queries, validates duration and overlap rules,
detects stale writes, and returns canonical events and resource URLs.
FullCalendar owns month/week/day rendering, selection, drag interaction, and
optimistic presentation; a rejected mutation immediately restores the prior
calendar state. Ordinary ActiveAdmin forms remain the complete editing fallback.

## Hierarchy boundary

`HierarchyNode` stores a portable administrator-owned adjacency list. Rails
validates parent ownership, cycles, maximum depth, sibling position, and
optimistic locks. React owns only expansion, selection, breadcrumbs, and
reversible drag/keyboard presentation. Direct-child endpoints are owner-scoped
and capped; the application does not expose arbitrary recursive traversal.

## Wizard boundary

The [Onboarding Wizard](docs/onboarding-wizard.md) persists administrator-owned
drafts after every step transition. Rails owns conditional validation,
authorization, optimistic locking, and the final submission timestamp. React
owns progress, conditional presentation, review, and error focus; it is not a
generic workflow engine.

## Audit-history boundary

PaperTrail records version provenance for administrator-owned synthetic
profiles. `paper_trail_diff` compares a selected historical endpoint with the
current record. React filters and visualizes immutable results; restoration is
only previewed because a future mutation requires separate authorization.

## Image-annotation boundary

Active Storage owns image bytes while `ImageAnnotation` stores only allowlisted,
normalized coordinates and labels. Rails validates bounds and asset MIME type;
React maps responsive pointer and keyboard interaction onto those portable
values. The surface is intentionally not a general graphics editor.

## Development preview boundary

`letter_opener_web` remains the development mail-delivery mailbox. The
ActiveAdmin preview island is also absent in production and consumes only
synthetic database records plus Active Storage attachments. Rails sanitizes
HTML and bounds MIME type and size; sandboxed React presentation cannot browse
arbitrary files or execute office-document content.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
