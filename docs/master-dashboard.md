<!-- docs/master-dashboard.md -->

# Master Dashboard, Global Search, and Privacy Mode

Issue [#87](https://github.com/scarver2/activeadmin-react-showcase/issues/87)
adds a Showcase-owned application launcher, not a new ActiveAdmin runtime or
authorization layer. The dashboard uses a continuous operating strip and grouped
links for Sales & Relationships, Production & Content, Operations, and
Collaboration & Reporting. Its navigation drawer remains on demand on desktop.
Other existing admin pages retain their native layout.

## Shared Navigation and Search

`Showcase::WorkspaceCatalog` supplies the dashboard links and the global command
palette's Page results. Every authenticated admin page mounts one search palette
in the header. Command-K / Control-K opens it; Tab wraps inside the dialog,
arrow keys select results, Enter follows the native link, and Escape returns
focus to the trigger. The existing Rails search form remains usable without
JavaScript. Accounts and articles retain their bounded, authenticated search
contract; destination controllers retain authorization authority.

Heroicons **2.2.0**, MIT licensed, supplies the functional outline icons through
named imports from `@heroicons/react/24/outline`. Icons support visible labels;
they do not replace accessible names. No proprietary reference assets or new
hand-drawn icon vocabulary are included.

## Privacy Scope and Persistence Decision

Privacy Mode is a presentation aid for screen sharing, **not access control**.
It masks only these home-dashboard values: account count, today's active-user
total, and today's monthly-revenue snapshot. Search results, account pages,
analytics, and other islands are not masked. Raw values remain delivered in
React props and available through developer tools and ordinary authorized
requests. The UI explicitly describes this limited scope.

Persistence options were considered before implementation:

| Scope | Decision |
| --- | --- |
| Browser local storage | Rejected: an exposed setting could linger independently of sign-in. |
| Permanent account preference | Deferred: adds durable user policy without an established requirement. |
| Rails session, bound to admin ID | Chosen: default masked, survives navigation/reload, does not share an unmasked preference with another admin login. |

Session lifetime follows the application's existing Rails/browser session policy;
closing a restored browser is not a guaranteed reset. There is no new database
column or client-storage preference. The authenticated PATCH endpoint accepts
only explicit boolean values and uses the existing CSRF protection. Without
JavaScript, the toggle submits an ordinary Rails form and dashboard totals always
remain masked.

The React toggle masks/unmasks immediately and disables overlapping saves.
Network or server failure leaves the current view masked and announces that
reloading may restore the previous saved session setting. Masking uses a fixed
metric block height to avoid layout reflow. The button exposes `aria-pressed`
and a scope description; a dashboard status message announces the current state.

## Verification and Review

Run the normal Ruby and frontend checks plus:

```sh
CI=1 PLAYWRIGHT_PORT=3187 CAPTURE_SHOWCASE_SCREENSHOTS=1 mise exec -- npx playwright test test/browser/master_dashboard.spec.ts test/browser/command_palette.spec.ts
```

The browser tests cover session persistence, stable metric height, one global
palette across navigation, authenticated record/page search, no-JavaScript search,
drawer dismissal, and horizontal overflow at 1440 and 390 pixels. Screenshot
capture uses seeded synthetic data and the existing Limestone & Ink palette
(legacy internal key `v3_texas`), in light and dark presentation. The palette name
is not a claim to generalize the separately explored Texas Bluebonnet theme.

These Chromium checks do not substitute for human visual approval or physical
device/multi-browser acceptance. No gem publication, upstream theme promotion,
deployment, or broader release-gate closure is part of this slice.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
