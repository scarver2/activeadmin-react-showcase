<!-- docs/ckeditor-editor.md -->

# CKEditor 5 WYSIWYG Editor

This showcase integrates the self-hosted open-source CKEditor 5 editor with an
ordinary ActiveAdmin 4 textarea. CKEditor owns authoring interaction. Rails owns
the administrator-scoped record, authorization boundary, validation,
sanitization, optimistic locking, persistence, and rendered preview.

## Demo and fallback

Open **Collaboration → CKEditor 5** and edit the seeded synthetic editorial
briefing. The deliberately bounded toolbar provides headings, bold and italic
emphasis, links, ordered and unordered lists, block quotes, code blocks, and
undo/redo.

The server renders a real `textarea` before JavaScript runs. CKEditor enhances
that control and synchronizes accepted HTML back into it. If JavaScript is
disabled or editor initialization fails, the textarea remains visible,
submittable, and covered by the same Rails sanitizer. Validation and stale-write
responses preserve the submitted draft. Turbo cache teardown destroys the
current editor before a later page visit mounts exactly one fresh instance.

## Rails authority and media boundary

`CkeditorArticle` belongs to the signed-in `AdminUser`; ActiveAdmin scopes every
read and mutation through that relationship. Rails allows only:

- `p`, `h2`, `h3`, `strong`, `em`, `ul`, `ol`, `li`, `blockquote`, `pre`,
  `code`, `a`, and `br` elements;
- `href` and `title` link attributes; and
- sanitized documents no larger than 50 KB.

Scripts, event handlers, arbitrary attributes, inline styles, images, iframes,
embeds, audio, video, and unsafe URL protocols are removed. The browser's HTML
is always untrusted input.

No upload adapter or media plugin is enabled. Upload authorization, storage,
metadata, and access remain separate Rails responsibilities. A future media
integration would need an explicit application-owned picker and reference
policy rather than giving the editor direct storage authority.

## Package, license, and provenance

The only direct CKEditor dependency is the official `ckeditor5` npm package.
Vite imports the OSS `ClassicEditor` plus a named set of locally bundled
plugins; tree-shaking excludes plugins that are not imported. The separate
`ckeditor5-premium-features` package is not installed.

| Dependency | Version | Source | License used here |
| --- | --- | --- | --- |
| CKEditor 5 | `48.5.2` | [official source](https://github.com/ckeditor/ckeditor5/tree/v48.5.2) | [GNU GPL v2 or later](https://github.com/ckeditor/ckeditor5/blob/v48.5.2/packages/ckeditor5/LICENSE.md) |

The required configuration uses `licenseKey: "GPL"`. Everything is served from
the application's compiled assets. There is no CKEditor Cloud script, CDN,
account, API key, premium/proprietary plugin, telemetry endpoint, CKBox,
CKFinder, or remote service configuration. `package-lock.json` is the exact
installation record used by local and hosted CI.

This experiment and its fixtures were developed from public CKEditor
documentation and synthetic Showcase requirements. It contains no University
of Texas Southwestern source code, configuration, data, private implementation
detail, or other institutional intellectual property.

## Factual comparison

The independent [Lexical experiment](lexical-editor.md) stores canonical JSON
and renders HTML through an application-owned Ruby document interpreter. That
gives the host a narrow structured schema but requires more application-owned
editor and server-renderer code.

The independent TinyMCE experiment and this CKEditor experiment both enhance a
textarea and submit HTML for Rails sanitization. TinyMCE demonstrates a mature
HTML-first integration with its own plugin vocabulary; CKEditor demonstrates a
model/plugin architecture and a different accessible editing experience. All
three preserve Rails authority and meaningful fallback. This comparison does
not select a winner or change any Rodeo product direction.

## Verification

- RSpec proves administrator ownership, authorization scope, allowlist
  sanitization, size bounds, validation recovery, and stale-write preservation.
- Vitest proves the exact GPL/plugin configuration, textarea synchronization,
  accessible failure fallback, and idempotent teardown.
- Playwright drives real Chromium through editing, validation, persistence,
  server-rendered sanitized preview, Turbo remount, keyboard input, narrow dark
  presentation, and a JavaScript-disabled submission.
- The committed editor and preview screenshots contain deterministic synthetic
  content only.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
