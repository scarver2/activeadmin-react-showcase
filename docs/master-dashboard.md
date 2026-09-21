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

Fresh dashboard-only screenshots are intentionally pending. Earlier captures
also displayed Global Search and the former Privacy Mode, so they are not valid
evidence for this focused dashboard PR and are not retained here.

This Chromium check does not substitute for human visual approval or physical
device/multi-browser acceptance. No Global Search, Privacy View, gem publication,
deployment, or broader release-gate closure is part of this slice.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
