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

## Inventory and ownership preservation

The CKEditor delta owns one administrator-scoped `CkeditorArticle` resource,
one React enhancement around the ordinary ActiveAdmin textarea, one bounded
server sanitizer, one seeded synthetic article, and the associated unit,
request, and browser evidence. It does not own or modify the Master Dashboard,
Global Search, Privacy View, Texas Bluebonnet, Workbench 1.3 or Workbench 2.x
laboratories, Lexical, or TinyMCE behavior. Those capabilities remain inherited
from `master`; their appearance in the shared shell and navigation is
composition evidence only.

The integration continues to use the native ActiveAdmin menu, header, theme,
authorization, form, validation, and Turbo lifecycle. The browser remount check
uses the current native drawer route without introducing CKEditor-specific
navigation behavior.

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

Representative evidence was captured on 2026-09-28 from normal-merge
application source `26243e431fe936f582feb082130245482dc14457` against accepted
`master` `fc965527093ee5b1146531ce01977b96c2933a9c`, with Playwright 1.63.0
and Chromium on macOS. The editor capture remained byte-identical after the
refresh; the preview capture changed only with inherited shared-shell
composition.

```text
5da218b2a7da27c54e054c1ac01ac52638219ed1f0f1dd185e30f1909b3c90ee  ckeditor-editor.png
6f14fb85fff6090bb6f6f7369c34e6b894966cc29755e752787e33d9a498443e  ckeditor-preview.png
a1a0a409ac0a5d4b93d80837b94de658d37a92d52509f85d328d933ad2353329  package-lock.json
```

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
