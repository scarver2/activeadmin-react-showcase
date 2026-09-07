<!-- docs/command-palette.md -->

# Command Palette and Global Search

The Command Palette demonstrates keyboard-first navigation across existing
showcase records. It is an authenticated query surface, not a new persistence
model or a browser-owned search engine.

## Rails contract

`Showcase::GlobalSearch` requires a persisted administrator and accepts no more
than 80 normalized characters. It queries Accounts by name and Showcase
Articles by title or summary, caps each candidate relation, and returns at most
eight results. Every result contains only a stable identifier, kind, label,
description, and a Rails-generated ActiveAdmin URL.

Ranking is deterministic:

1. exact field matches;
2. field-prefix matches;
3. field-substring matches;
4. resource kind, normalized label, then record ID for ties.

The endpoint rejects unauthenticated requests before querying. Adding another
resource requires an explicit searchable-field, authorization, description,
URL, ranking, and test decision in Rails. The application does not persist
`SearchResult` rows or copy durable records into a speculative local index.

## Browser interaction

React owns the Command-K / Control-K shortcut, focus transfer into and out of
the modal dialog, arrow-key selection, Enter navigation, Escape dismissal, and
loading, empty, and error feedback. It submits only the bounded text query and
cannot select columns, alter ranking, construct resource URLs, or bypass Rails
authentication.

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
showcase dataset and remains portable to PostgreSQL. A specialized index or
external search service belongs here only after measured relevance, latency,
or scale demonstrates the need.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
