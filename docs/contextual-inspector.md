<!-- docs/contextual-inspector.md -->

# Contextual Inspector

The Account Data Explorer demonstrates a reusable right-side inspector for dense
operator work. Selecting an account keeps the filtered table mounted while an
accessible drawer loads bounded account context from Rails.

## Ownership contract

- Rails owns account data, authentication, authorization, canonical record and
  edit destinations, relationship counts, current metrics, errors, and whether
  the edit action is present.
- React owns the drawer, loading and error presentation, keyboard focus, Escape
  dismissal, and the transient browser-history entry.
- The account name remains an ordinary link to the canonical ActiveAdmin record.
  With JavaScript disabled, modified-clicked, refreshed, or opened in a new tab,
  it navigates normally.
- A drawer history entry uses the canonical record URL. Back closes the drawer
  and restores the preserved table/filter state; Forward reopens it by replaying
  the Rails request. A Cable event or client cache is never authoritative.

## Failure behavior

- A deleted account produces a stale-record message and retains a canonical
  navigation option.
- A 401, 403, or authentication redirect is presented as changed access rather
  than silently retaining previously loaded data.
- Inspector payloads are replaced on every selection and aborted requests are
  ignored, so context from one account cannot leak into another.

## Verification

- RSpec covers the serializer, authenticated endpoint, unauthenticated response,
  stale record, canonical destinations, and authorization-shaped actions.
- Vitest covers history state, Back/Forward replay, Escape, focus return, focus
  trapping, access changes, stale records, and semantic-icon accessibility.
- Playwright covers the authenticated desktop workflow, a 390-pixel viewport,
  canonical no-JavaScript navigation, browser history, and screenshots.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
