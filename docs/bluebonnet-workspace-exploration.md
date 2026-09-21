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
- The shared semantic `dashboard` icon supplies the geometric explorer landmark;
  native functional navigation/user controls remain unchanged. Heroicons provenance
  and license are recorded in the landed semantic icon foundation.

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

Source: `13a2557f7f92bc7d9513e96b74bb363e88e7b775`, refreshed onto
`master` at `cedad515622940ed5200a408dd98bff7e6f9a462` after the semantic
icon foundation landed. The following documentation/artifact commit does not
alter rendered source. Local macOS Chromium via repository-locked
Playwright; synthetic `bin/browser-server` seed; viewport height 1000, widths 1440
and 390; full-page capture. Light/dark root state is explicitly selected by the
test before capture. No production data or credentials are in these artifacts.

Command:

```sh
CI=1 PLAYWRIGHT_PORT=3173 CAPTURE_SHOWCASE_SCREENSHOTS=1 mise exec -- \
  npx playwright test test/browser/bluebonnet_workspace.spec.ts
```

All four cases pass: render, document overflow check, filter/reset, next page,
native drawer open and Escape dismissal. Assertions cover the accessible Rows
name/native tooltip, visually hidden label, matching header/table background,
compact desktop header/footer heights and retained 44px narrow Rows control.
The shared registry owns the explorer glyph and the request spec proves the
Heroicons symbol reference. All 402 RSpec examples pass at 92.24% line and 85.17%
branch coverage; TypeScript, all 172 Vitest tests at 100% coverage, the production
build, RuboCop and RBS validation pass. The browser server builds the assets
afresh. This is not a full accessibility, physical-device, multi-browser, or
release acceptance claim.

| Capture | SHA-256 |
| --- | --- |
| 1440 light | `ad942a1953c1e07353bea551d07828332ad12ee4848e401dc94573b6b51fed97` |
| 1440 dark | `d85a522df6a4546c28d8fbd3427b5a5ecde29966021ca473e311ce96a69bcf05` |
| 390 light | `44f1e625d1004f97ed244d8ffd7405266455ed4abc34de085d9da32e487a8dc4` |
| 390 dark | `e494a6708ac48f81eaee1c2e46bdf5e69f93ba85beff910f919c138b0e18ee53` |

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
