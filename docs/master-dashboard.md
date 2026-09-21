<!-- docs/master-dashboard.md -->

# Master Dashboard

Issue [#87](https://github.com/scarver2/activeadmin-react-showcase/issues/87)
adds a Showcase-owned application launcher, not a new ActiveAdmin runtime or
authorization layer. The dashboard uses a continuous operating strip and grouped
links for Sales & Relationships, Production & Content, Operations, and
Collaboration & Reporting. Its navigation drawer remains on demand on desktop.
Other existing admin pages retain their native layout.

## Rails and React boundary

`Showcase::WorkspaceCatalog` is the Rails-owned dashboard vocabulary. It groups
native ActiveAdmin destinations and keeps every URL server-generated; each
destination continues to own its authorization and behavior. Rails also supplies
the seeded operating metrics and a complete no-JavaScript launcher fallback.

`MasterDashboard` composes that contract into the operating picture and grouped
workspace launcher. It does not query records, authorize destinations, or create
a second navigation system. The component uses the merged semantic icon registry
rather than importing an icon package or defining a dashboard-only vocabulary.

The dashboard reinitializes ActiveAdmin's existing Flowbite drawer/dropdown
handlers on `turbo:load` and closes the main drawer before Turbo caches a page.
This keeps the on-demand native navigation useful after sign-in and across Turbo
visits without replacing ActiveAdmin behavior. Flowbite 3.1.2 is declared
directly at the version already used by ActiveAdmin.

## Verification

Run the normal Ruby and frontend checks plus:

```sh
CI=1 PLAYWRIGHT_PORT=3187 mise exec -- npx playwright test test/browser/master_dashboard.spec.ts
```

The browser test covers the server-owned operating metrics, all four capability
groups, semantic icon presentation, the native on-demand drawer, representative
navigation, and horizontal overflow at 1440 and 390 pixels in light and dark
presentation.

Fresh dashboard-only screenshots use application source
`b1c77558e5b7808ac4e01f005052371fef51ba19` and Playwright 1.63.0 Chromium on macOS. They were captured on
2026-09-21 with seeded synthetic data at 1440 × 1000 and 390 × 1000 browser
viewports through the same light/dark root class used by the native toggle.
Earlier mixed captures were removed because they also displayed Global Search
and the former Privacy Mode.

| Presentation | Desktop | Narrow |
| --- | --- | --- |
| Light | [1440 px](screenshots/master-dashboard-1440-light.png) | [390 px](screenshots/master-dashboard-390-light.png) |
| Dark | [1440 px](screenshots/master-dashboard-1440-dark.png) | [390 px](screenshots/master-dashboard-390-dark.png) |

SHA-256 artifact hashes:

```text
fd592134ea02dbea2edf0e465126140815ef83dfc1d3497b437eb639fdbd9def  master-dashboard-1440-light.png
1351f0d3a318bba832ee477491c394d010f626508e87c43fd4eb6f5ecd840c0b  master-dashboard-1440-dark.png
f2410c811ff2f9c12c79a4732751e56aaab985a654d67f24804987e158d935c7  master-dashboard-390-light.png
e1b72a8c20cd3594ee6f093984f053cdc7b05dc12aa3432f6436fdc2623cffe9  master-dashboard-390-dark.png
```

This Chromium check does not substitute for human visual approval or physical
device/multi-browser acceptance. No Global Search, Privacy View, gem publication,
deployment, or broader release-gate closure is part of this slice.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
