<!-- docs/master-dashboard.md -->

# Master Dashboard

Issue [#87](https://github.com/scarver2/activeadmin-react-showcase/issues/87)
adds Texas Bluebonnet's Showcase-owned operating home, not a new ActiveAdmin
runtime or authorization layer. It combines a restrained three-signal operating
strip with grouped capability launchers for Sales & Relationships, Production &
Content, Operations, and Collaboration & Reporting. The continuous surface and
shared grid lines deliberately avoid generic dashboard card soup. Its navigation
drawer remains on demand at every viewport. Other admin pages retain their native
layout unless they explicitly opt into the approved Bluebonnet composition.

## Reference translation

Three Sheriff-supplied reference captures informed this replacement without
contributing source assets, copied markup, names, or palette values:

- the capability launcher suggested grouping destinations by business work;
- the operational cockpit suggested a small set of meaningful live indicators;
- the workflow map established a pattern for future focused subdashboards, where
  sequence and handoffs have domain meaning, rather than decoration on the master
  dashboard.

The result preserves #73's editorial hierarchy, full-width continuous workspace,
on-demand navigation, restrained geometry, and light/dark Bluebonnet palette.
Heroicons from the landed semantic registry remain the ordinary functional
vocabulary. No dashboard-only icon library or ad-hoc SVG vocabulary was added.

## Rails and React boundary

`Showcase::WorkspaceCatalog` is the Rails-owned dashboard vocabulary. It groups
native ActiveAdmin destinations and keeps every URL server-generated; each
destination continues to own its authorization and behavior. Rails also supplies
the seeded operating metrics and a complete no-JavaScript launcher fallback.

`MasterDashboard` composes that contract into the operating picture and grouped
capability launcher. It does not query records, authorize destinations, or create
a second navigation system. The component uses the merged semantic icon registry
rather than importing an icon package or defining a dashboard-only vocabulary.
The no-JavaScript fallback continues to expose every Rails-owned destination.

The dashboard reinitializes ActiveAdmin's existing Flowbite drawer/dropdown
handlers on `turbo:load` and closes the main drawer before Turbo caches a page.
This keeps the on-demand native navigation useful after sign-in and across Turbo
visits without replacing ActiveAdmin behavior. On composition pages it also
starts the native drawer closed, including above ActiveAdmin's desktop breakpoint,
while preserving the native trigger, Escape behavior and focus contract. Flowbite
3.1.2 is declared directly at the version already used by ActiveAdmin.

Global Search remains isolated in PR #112. Privacy remains extracted and on HOLD
in PR #111. Neither capability is implemented or presented by this dashboard PR.

## Verification

Run the normal Ruby and frontend checks plus:

```sh
CI=1 PLAYWRIGHT_PORT=3187 mise exec -- npx playwright test test/browser/master_dashboard.spec.ts
```

The browser test covers the server-owned operating metrics, all four capability
groups and twelve native destinations, semantic icon presentation, the initially
closed native drawer plus open/Escape interaction, representative navigation,
and horizontal overflow at 1440 and 390 pixels in light and dark presentation.

`CI=1 bin/ci` passed at exact code-and-test head
`4cecf4d84342a2f9077375bd8625c5c08ae0a54c`: 402 RSpec examples with 92.23%
line / 85.17% branch coverage; 175 Vitest tests with 100% configured coverage;
TypeScript and production Vite build; 44 Chromium scenarios; 395 RuboCop files;
RBS validation; Brakeman with 0 warnings; and Ruby dependency audit with no
known vulnerabilities.

Fresh dashboard-only screenshots use exact application source
`57bee65a5fab9a2a0fd538b9a11ad9b721cf5371` and Playwright 1.63.0 Chromium on
macOS. They were captured on 2026-09-21 with seeded synthetic data at 1440 × 1000
and 390 × 1000 browser viewports through the same light/dark root class used by
the native toggle. All four primary captures show the drawer closed and the full
top shell. Drawer-open behavior is interaction evidence, not substituted visual
evidence. Earlier mixed captures were removed because they also displayed Global
Search and the former Privacy Mode.

| Presentation | Desktop | Narrow |
| --- | --- | --- |
| Light | [1440 px](screenshots/master-dashboard-1440-light.png) | [390 px](screenshots/master-dashboard-390-light.png) |
| Dark | [1440 px](screenshots/master-dashboard-1440-dark.png) | [390 px](screenshots/master-dashboard-390-dark.png) |

SHA-256 artifact hashes:

```text
d2709d2c8ff307749c4726cb88251af03fd02822311ea13c5c46ae52350e3308  master-dashboard-1440-light.png
4cb435703d8dfefbd567225c6bbd75653856848092fe81fc3f82cb61d18ed8d1  master-dashboard-1440-dark.png
9c48693b27809ecf3d0b47343259c5fe540944adfa88d47695a650d6d75aa6f2  master-dashboard-390-light.png
dca04861c36fa3909c597839e236b2b70ab88d22eee2f9cdcfca2c6fe4d6a15c  master-dashboard-390-dark.png
```

This Chromium check does not substitute for human visual approval or physical
device/multi-browser acceptance. No Global Search, Privacy View, gem publication,
deployment, or broader release-gate closure is part of this slice.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
