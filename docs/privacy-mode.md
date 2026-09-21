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

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
