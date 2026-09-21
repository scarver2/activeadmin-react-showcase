<!-- docs/privacy-mode.md -->

# Privacy Mode extraction

Privacy Mode is a presentation-only Showcase experiment extracted unchanged in
scope from the former master-dashboard implementation. It defaults on and masks
only the three designated home-dashboard totals: account count, active users,
and monthly revenue.

The state is stored in the authenticated administrator's Rails session. The
control updates optimistically, sends an authenticated CSRF-protected request,
and fails closed to a masked view when persistence fails. The ordinary Rails
form remains usable without JavaScript.

## Security boundary

Privacy Mode is not authorization, secure redaction, or a guarantee that values
are absent from delivered HTML or React properties. It does not change database
queries, permissions, exports, other pages, or API responses. Its only purpose
is reducing casual disclosure during screen sharing, demonstrations, and
shoulder-surfing on this synthetic dashboard.

## Product hold

Further product and visual development is intentionally **on hold** pending
Sheriff's direction. This extraction does not expand masking semantics,
persistence, chart behavior, export/print handling, or accessibility-tree
policy.

## Browser evidence

The committed images were captured from application source
`838ffd946ba4bdeba8d496055a6faaea99f8eb52` using Playwright 1.63.0 and its
bundled Chromium at default zoom with deterministic synthetic data. Both were
visually inspected; the narrow capture also has an automated document-overflow
regression.

- `privacy-mode-1440.png` — 1440 × 1000 viewport; SHA-256
  `a837b93343a47002af28b4850c07d06671c8c309d9ecd12dabedc1a6417b2fa8`.
- `privacy-mode-390.png` — 390 × 1000 viewport; SHA-256
  `fe9cef1a1fb1a5e8b7c1b7d23a0dae0d6103db66c0f88127b1a8e1ed28e11bcf`.

These captures demonstrate presentation only. They do not broaden the security
claim or lift the product hold.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
