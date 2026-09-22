<!-- docs/tinymce-editor.md -->

# TinyMCE WYSIWYG Editor

This showcase integrates a self-hosted TinyMCE 8 editor into an ordinary
ActiveAdmin 4 form. React owns the editor lifecycle; Rails owns the record,
administrator scope, validation, sanitization, optimistic locking, and final
HTML preview.

The experiment is also a modern continuation of Stan Carver II's first coding
video, [TinyMCE WYSIWYG Editor Integration in ActiveAdmin: A 2014 Time
Capsule](https://stancarver.com/blog/first-youtube-video/). The original
[Ruby on Rails: Add a WYSIWYG Editor to
ActiveAdmin](https://www.youtube.com/watch?v=FVfnqV4lr_c) was recorded on
February 14, 2014. This implementation preserves the useful idea while
replacing global JavaScript and trusted browser HTML with an explicit modern
boundary.

## Demo

Open **Collaboration → TinyMCE Editor** and edit the seeded synthetic briefing.
The toolbar provides headings, bold and italic emphasis, ordered and unordered
lists, links, blockquotes, and source-code inspection. The code button is an
HTML-source editor; persisted `pre` and `code` elements provide bounded code
formatting.

TinyMCE enhances the server-rendered `textarea` in place. If JavaScript is
unavailable or initialization fails, that textarea remains visible and
submittable. A validation response reuses the submitted sanitized HTML and
mounts exactly one new editor. Turbo navigation tears down the old instance
before the island is removed.

## Authority and safety

`TinyMceArticle` belongs to the signed-in `AdminUser`, and the ActiveAdmin
resource scopes every read and mutation through that relationship. The server
allows only:

- `p`, `h2`, `h3`, `strong`, `em`, `ul`, `ol`, `li`, `blockquote`, `pre`,
  `code`, `a`, and `br` elements;
- `href` and `title` attributes on links; and
- documents no larger than 50 KB.

Scripts, event handlers, inline styles, iframes, embeds, images, audio, video,
unsafe link protocols, and arbitrary attributes are removed before validation
and persistence. Browser HTML is always untrusted input.

Image and media insertion is intentionally absent. Upload authorization and
storage remain in the Showcase's Rails-owned Asset Manager; this editor does
not accept data URLs, remote embeds, or direct uploads. A future bounded picker
would have to select an already-authorized Rails asset and submit an explicit
host-owned reference policy.

## Self-hosting and license

The application bundles TinyMCE from the npm package and initializes it with
the GPL license key. It uses only the open-source core and the bundled
`autolink`, `code`, `link`, `lists`, and `wordcount` plugins. There is no Tiny
Cloud script, API key, CDN, paid plugin, telemetry endpoint, or proprietary
service dependency. See the package's `license.md` for the GPLv2-or-later and
commercial dual-license terms.

| Dependency | Version | Source | License used here |
| --- | --- | --- | --- |
| TinyMCE | `8.8.2` | [upstream source](https://github.com/tinymce/tinymce/tree/8.8.2/modules/tinymce) | [GNU GPL v2 or later](https://github.com/tinymce/tinymce/blob/8.8.2/modules/tinymce/license.md) |

`package-lock.json` is the immutable installation record used by local and
hosted CI. No copied TinyMCE source or plugin artifact is committed separately.

## TinyMCE and Lexical

The neighboring [Lexical editor](lexical-editor.md) persists canonical
structured JSON and derives HTML on the server. TinyMCE begins with HTML and
therefore offers a more familiar, mature WYSIWYG integration with a thinner
application component, but it demands especially strict server sanitization
and a deliberately narrow plugin/media policy.

Lexical gives the host stronger control over the document schema and React
composition. TinyMCE gives administrators a conventional HTML-authoring
surface with less application-owned toolbar code. This experiment does not
declare a winner: the appropriate boundary depends on whether a host values a
structured document model or direct, sanitized HTML compatibility.

## Verification

- RSpec proves ownership scope, validation, sanitization, unsafe-protocol
  removal, document bounds, and stale-write preservation.
- Vitest proves the bounded TinyMCE configuration, form synchronization,
  failure fallback, and lifecycle cleanup.
- Playwright runs real Chromium through editing, validation, persistence,
  sanitized preview, Turbo navigation/remount, and a JavaScript-disabled
  submission.
- The screenshots use deterministic synthetic content and contain no real
  customer information.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
