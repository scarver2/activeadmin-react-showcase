<!-- docs/privacy-view.md -->

# Privacy View

Privacy View is a presentation convenience for an authorized operator who wants
to reduce casual disclosure while a customer is present, during screen sharing,
or while working in public. It is **off by default**. The conventional switch in
the global ActiveAdmin top navigation makes its state explicit and keeps that
state in the authenticated administrator's Rails session across navigation.

When enabled, the shell sets `data-privacy-view="on"` on the root HTML element.
Owning surfaces opt values in with semantic markers such as
`data-private="financial"`; shared CSS then replaces each marked value with the
same fixed `••••` placeholder. The surrounding panel, label, chart, and layout
remain present. The current proof marks monthly revenue on the home dashboard
and revenue values in Analytics. The demonstrated Analytics charts visualize
non-financial active-user and plan data, so their tooltips remain visible; any
future chart or tooltip that exposes marked commercial values must use the same
semantic boundary rather than a feature-specific conditional.

## Three distinct layers

1. **Privacy View** is client presentation. Authorized values may still be
   delivered in HTML, React properties, JSON, or the DOM.
2. **Masking** is a server or policy transformation that changes the value sent
   to the client.
3. **Authorization/RBAC** determines whether an actor may receive a value at
   all.

Privacy View implements only the first layer. It does not change authorization,
server responses, audit permissions, tenant isolation, exports, database
queries, or masking policy. It must never be described as redaction or used as a
security control.

The control updates optimistically, sends an authenticated CSRF-protected
request, and keeps concealment on in the current page if persistence fails. A
plain Rails form preserves the same session preference when JavaScript is
unavailable.

## Browser evidence

The committed images were captured from application source
`53670781ef73e22c4fa8507ebf4e68657dc88ba5` using Playwright 1.63.0 and its
bundled Chromium with deterministic synthetic data at default zoom. Both were
visually inspected after the header-cascade correction.

- `privacy-view-off-1440.png` — global top navigation with Privacy View off and
  the marked revenue visible; 1440 × 1000; SHA-256
  `bacb0dace7fb40d59421ff8ef921f734603df84a0234c64c05da96753ecfbf8e`.
- `privacy-view-on-1440.png` — the same surface with Privacy View on, the
  `••••` placeholder visible, and surrounding context unchanged; 1440 × 1000;
  SHA-256
  `f1838ed582a777994c01ef5ccd9ba233750da6b5e33a42a8590f1f3eb0f227f4`.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
