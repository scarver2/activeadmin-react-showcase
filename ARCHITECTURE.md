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

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
