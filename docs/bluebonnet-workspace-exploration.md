<!-- docs/bluebonnet-workspace-exploration.md -->

# Texas Bluebonnet Workspace Exploration

This is a screenshot-review prototype, not an approved shared theme or rollout.
PR #69 owns persisted color palettes on the existing composition. This separate
slice explores an entire workspace at `/admin/data_explorer?composition=bluebonnet`.
The normal explorer and every other page retain their current composition.

## Design Direction

- No permanent navigation sidebar: the existing AA4 drawer remains available at
  every width, with its native interaction and keyboard dismissal.
- Full-width workspace, editorial page hierarchy, a contextual action, a compact
  workspace bar, and one continuous table surface instead of stacked cards.
- Contextual field notes sit beside the desktop data and below it on narrow screens.
- Fixed approved cream/navy palette direction for this study; the palette selector
  is intentionally absent here, so it cannot imply a selection changes this theme.
- Original geometric explorer icon; native functional navigation/user controls.
  No third-party icon vocabulary or Western decoration.

## Behavioral Boundary

AccountExplorer behavior and its endpoint are unchanged. Sorting, filters, pagination,
authorization and account URLs remain Rails-owned. The page still renders through
ActiveAdmin, including its menu, user controls, notifications and dark-mode control.
The prototype has a server fallback link to native Account views without JavaScript.
Nothing is promoted to activeadmin-themes.

If approved later, the token block belongs to foundation, shell/workspace rules to
composition, table/control styling to components, this page to surfaces, and narrow,
focus/preference rules to hardening. These are intentionally kept in one scoped
prototype stylesheet until the design itself is accepted.

## Exact Screenshot Provenance

Source: `08c06d32f6b0e76e16eef9272a8e7cecd809bf57`, stacked on #72 branch
`feat/bluebonnet-icon-exploration`. The following documentation/artifact
commit does not alter rendered source. Local macOS Chromium via repository-locked
Playwright; synthetic `bin/browser-server` seed; viewport height 1000, widths 1440
and 390; full-page capture. Light/dark root state is explicitly selected by the
test before capture. No production data or credentials are in these artifacts.

Command:

```sh
CI=1 PLAYWRIGHT_PORT=3173 CAPTURE_SHOWCASE_SCREENSHOTS=1 mise exec -- \
  npx playwright test test/browser/bluebonnet_workspace.spec.ts
```

All four cases pass: render, document overflow check, filter/reset, next page,
native drawer open and Escape dismissal. New assertions cover the accessible Rows
name/native tooltip, visually hidden label, matching header/table background,
compact desktop header/footer heights and retained 44px narrow Rows control.
TypeScript, 161 Vitest tests (100% coverage) and the production build pass.
The earlier 395-example RSpec result belongs to `827e6165d6906317bea9250a8f34431823f74af3`,
not this correction's evidence. No Ruby source changed in this correction.
The browser server builds the assets afresh. This is not a full accessibility,
physical-device, multi-browser, or release acceptance claim.

| Capture | SHA-256 |
| --- | --- |
| 1440 light | `11136c8634c7b7d7d580e6489fa5f1e2c2ea2d36a18b8e86f5c5a8cbfe3bcaba` |
| 1440 dark | `48f9944ed6c4dc940b12c7217a713aae5e6f36879ddcb0cfe31d15b50473c86b` |
| 390 light | `0d049cce2a14712b3aa0a597571363558f7e49962840304efddbf4ccd5a91c7d` |
| 390 dark | `cd941ac68f7a2ec00f5325bad59496450bb82915e29be3f7e2637269d1765f29` |

## Requested Table Refinement

Addresses [the review comment](https://github.com/scarver2/activeadmin-react-showcase/pull/73#issuecomment-5751992958):
the visible Rows label is hidden only in Bluebonnet while its accessible label and
native `title="Rows"` tooltip remain. The column header uses the continuous table
surface rather than a contrasting band. Header and pagination padding are reduced;
body-row density is unchanged. Narrow controls retain their 44px minimum height.
All four refreshed images were visually inspected, including value/arrow spacing.

## Review Images

![Desktop light](screenshots/bluebonnet-workspace-1440-light.png)
![Desktop dark](screenshots/bluebonnet-workspace-1440-dark.png)
![Narrow light](screenshots/bluebonnet-workspace-390-light.png)
![Narrow dark](screenshots/bluebonnet-workspace-390-dark.png)

## Decisions Still Required

Sheriff and Deputy must review the full composition before expansion. In particular:
does the workspace-first direction provide enough character; is the supporting
context useful; and is on-demand navigation preferable to a persistent rail?
Narrow tables deliberately scroll horizontally, preserving the native column data.
Broader keyboard, zoom, contrast, preference and browser/device acceptance remains
necessary before adopting this as a full theme. No merge, release, publication or
Rodeo adoption is implied by this prototype.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
