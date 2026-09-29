<!-- docs/command-palette.md -->

# Command Palette and Global Search

Global Search demonstrates keyboard-first navigation across existing showcase
pages and records. One palette lives in the global header on every authenticated
admin page. It is an authenticated query surface, not a new persistence model
or a browser-owned search engine. Issue #88's richer Command Palette remains
downstream and must consume this contract rather than duplicate search rules.

## Rails contract

`Showcase::GlobalSearch` requires a persisted administrator and accepts no more
than 80 normalized characters. It queries Accounts by name and Showcase
Articles by title or summary, and matches labels, descriptions, and group names
from the shared Rails `WorkspaceCatalog`. It caps each candidate relation and
returns at most eight results. Every result contains only a stable identifier,
kind, label, description, and a Rails-generated ActiveAdmin URL.

Ranking is deterministic:

1. exact field matches;
2. field-prefix matches;
3. field-substring matches;
4. resource kind, normalized label, then record ID for ties.

Workspace pages participate in the same deterministic ranking. The catalogue
contains canonical deep links and presentation vocabulary only; each destination
retains its own Rails authorization when followed.

The endpoint rejects unauthenticated requests before querying. Adding another
resource requires an explicit searchable-field, authorization, description,
URL, ranking, and test decision in Rails. The application does not persist
`SearchResult` rows.

## Active Search plumbing

Durable Account and Showcase Article candidates use Basecamp Active Search
v0.1.0 at exact release commit
`1fb3967b4a3243e363947ccf141f66d3f929bcf8` (MIT). The release is not yet
published to RubyGems, so Bundler pins the official Git source. Active Search
owns FTS5 document storage, indexing callbacks, record loading, and supported
full-text candidate discovery. `Showcase::GlobalSearchRecords` keeps that
dependency behind a replaceable Rails boundary; neither the endpoint nor React
knows it exists.

The SQLite indexes use FTS5's built-in trigram tokenizer so Active Search can
preserve the accepted case-insensitive mid-token substring contract. FTS5
trigrams cannot match a query shorter than three characters, so the Rails
boundary retains the previous bounded Ransack query only for one- and
two-character searches. It reapplies ID order and the 25-record candidate cap
before `Showcase::GlobalSearch` owns exact/prefix/substring ranking, resource
order, result shaping, canonical URLs, and the global eight-result cap. This is
an application compatibility boundary, not a private Active Search patch.

Account and Showcase Article writes index inline after commit to preserve the
existing immediate-consistency behavior. Creating, updating, and destroying a
record adds, replaces, and removes its document. Rebuilding after index loss is
the application-owned operation described by Active Search: iterate each model
and call `reindex`, preferably through the gem's bounded batch API for a large
dataset. The two document migrations are ordinary application migrations; no
separate search service or credential is required.

The production topology remains SQLite and uses the gem's FTS5 adapter. Active
Search also supplies a PostgreSQL `tsvector` adapter, but PostgreSQL would need
adapter-specific generated migrations and a measured migration plan; the
Showcase does not claim byte-compatible index portability. Replacing Active
Search requires changing only the durable-candidate service and index lifecycle,
not the browser contract.

## Browser interaction

React owns the header trigger, Command-K / Control-K shortcut, modal focus trap,
focus restoration, arrow-key selection, Enter navigation, Escape dismissal, and
loading, empty, stale-response, and error feedback. It submits only the bounded
text query and cannot select columns, alter ranking, construct resource URLs,
or bypass Rails authentication.

Without JavaScript, the same page renders an ordinary GET search form and
server-ranked links. This fallback uses the same service and authorization
boundary as the JSON endpoint.

## Verification

- RSpec proves authorization, bounds, searchable resource scope, stable
  ranking, result caps, Rails URLs, fallback rendering, and endpoint errors.
- Vitest proves shortcuts, focus restoration, dialog dismissal, keyboard
  selection, navigation, loading, empty, error, and retry states.
- Playwright proves authenticated Rails search and navigation in Chromium plus
  the complete no-JavaScript form and link path.

The current SQLite query boundary is sufficient for the deliberately small
showcase dataset. An external search service belongs here only after measured
relevance, latency, or scale demonstrates the need.

## Screenshot

The [gallery capture](screenshots/command-palette.png) shows the global header
control and focused search results over authorized synthetic Rails data. The
accepted Privacy View control from the base branch is visible in the shared
header, but this remains a Search-owned capture and makes no Master Dashboard or
Privacy View evidence claims.

Captured from committed source `657c9dfc114124d898906488ddf6cf822d5edc3d`
on September 28, 2026 with Playwright 1.63.0 / Chromium, Desktop Chrome's
1280×720 viewport (1280×1201 full-page output), default zoom, and the seeded
test host. The complete focused scenario passed, including the workspace-page
result, Account result, deep-link navigation, empty/error states, keyboard
interaction, and no-JavaScript fallback.

```sh
CAPTURE_SHOWCASE_SCREENSHOTS=1 CI=1 PLAYWRIGHT_PORT=3191 mise exec -- npx playwright test test/browser/command_palette.spec.ts
```

SHA256: `e564613f7ab4b888da23867c9f3a7ad2d376717114fbebaaff48eddae1a70f61`

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
