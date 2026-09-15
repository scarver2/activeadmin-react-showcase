<!-- docs/lexical-editor.md -->

# Lexical WYSIWYG Editor

The Lexical Editor is one React island inside an ordinary ActiveAdmin resource
form. It demonstrates headings, inline emphasis, links, lists, block quotes,
undo/redo, clear formatting, keyboard shortcuts, validation round trips, and
optimistic concurrency without asking React to own the record lifecycle.

## Canonical document and trust boundary

`ShowcaseArticle#editor_state` stores normalized Lexical JSON as the canonical
document. The browser submits no authoritative HTML. Rails recursively validates
the supported node vocabulary and link protocols, then
`Showcase::LexicalDocument` renders escaped HTML from that accepted JSON for safe
display. Links may use `http`, `https`, or `mailto`, a same-application absolute
path, or an in-document anchor; executable, protocol-relative, malformed, and
unknown protocols are rejected.

This deliberate subset prevents a browser from smuggling arbitrary HTML through
the editor. Adding another Lexical node requires matching Rails validation,
rendering, fallback, and test coverage.

## Ownership

- **React and Lexical** own selection, toolbar interaction, keyboard shortcuts,
  history, and the editable preview.
- **Rails** owns authentication, accepted nodes and URLs, canonical persistence,
  rendered safety, validation, and optimistic locking.
- **ActiveAdmin** owns the form, error summary, submit lifecycle, and record
  navigation.

A failed validation response rehydrates the submitted JSON. A stale
`lock_version` returns HTTP 409 with the submitted draft still in the editor,
while leaving the concurrently saved record unchanged.

## No-JavaScript fallback

The resource includes an ordinary textarea inside `noscript`. Rails converts its
plain text into the same canonical JSON structure, escapes every character while
rendering, and later exposes a readable plain-text version of rich documents.
The fallback is intentionally less expressive, but it remains useful and safe.

## Verification

RSpec covers authentication, canonical persistence, server rendering, URL
policy, validation, stale writes, and the no-JavaScript form path. Vitest covers
hydration, the toolbar contract, link insertion, accessibility, history, and
error behavior. Playwright exercises formatting, save/reload fidelity, rejected
unsafe links, draft preservation, keyboard focus, and the real Chromium mount.

The [gallery capture](screenshots/lexical-editor.png) uses deterministic synthetic
content and shows the full WYSIWYG toolbar with headings, emphasis, a list, a
quote, and a safe link.

The editor remains showcase-local. Nothing in this experiment expands the
generic `activeadmin-react` component API.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
