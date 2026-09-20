<!-- docs/master-dashboard.md -->

# Master Dashboard, Global Search, and Privacy Mode

Issue [#87](https://github.com/scarver2/activeadmin-react-showcase/issues/87)
adds a Showcase-owned application launcher, not a new ActiveAdmin runtime or
authorization layer. The dashboard uses a continuous operating strip and grouped
links for Sales & Relationships, Production & Content, Operations, and
Collaboration & Reporting. Its navigation drawer remains on demand on desktop.
Other existing admin pages retain their native layout.

The header reinitializes ActiveAdmin's existing Flowbite drawer/dropdown handlers
on `turbo:load` and closes the main drawer before Turbo caches a page. This avoids
requiring a full reload after sign-in; it does not replace the native controls.
Flowbite 3.1.2 is declared directly at the version already used by ActiveAdmin.

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

## Captured Evidence

Application/test source: `dbd14d724ee6085dd556827eba72b050809aab65`.
Captured on 2026-09-20 using Playwright 1.63.0 Chromium on macOS, full-page
screenshots with 1440 × 1000 and 390 × 1000 browser viewports, synthetic seeded
data, and Privacy Mode on. Light/dark presentation is selected through the same
root `dark` class used by the native toggle. The evidence commit adds only these
images and this record; it does not alter application source.

| Presentation | Desktop | Narrow |
| --- | --- | --- |
| Light | [1440 px](screenshots/master-dashboard-1440-light.png) | [390 px](screenshots/master-dashboard-390-light.png) |
| Dark | [1440 px](screenshots/master-dashboard-1440-dark.png) | [390 px](screenshots/master-dashboard-390-dark.png) |

SHA-256 artifact hashes:

```text
972483c2953f62c5676ab0a7d01a565fff94d3e9f1b1df9b247f605192ff7dc1  master-dashboard-1440-light.png
88d82639b68dfa0b46d6e8b102f64e4a6336b84b7495fa8e59c91fe2cf593a86  master-dashboard-1440-dark.png
ab2b0e9e371df6bc278f911369e81b51ac26d42dcb1c8b0ccf70cf8e1eed73d8  master-dashboard-390-light.png
9c820c710a78d68b59d893eae1dd1f8941bd8870284a425d62fa8dbabe0325e9  master-dashboard-390-dark.png
```

The final source passes 38 Chromium scenarios and 170 frontend tests, including
100% statements/branches/functions/lines for the configured component coverage
scope. TypeScript and the production Vite build pass. The native-navigation
lifecycle has its own unit test plus real sign-in/drawer/navigation browser
coverage. Ruby verification reports 394 examples, zero failures, 92.24% line
coverage; RuboCop, RBS, Brakeman and dependency audits pass. Vite still reports
the existing large-chunk advisory; no bundling redesign is included here.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
