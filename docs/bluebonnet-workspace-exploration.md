<!-- docs/bluebonnet-workspace-exploration.md -->

# Texas Bluebonnet Workspace Exploration

This began as a screenshot-review prototype and is now the executable consumer
proof for the approved reusable theme composition.
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

Presentation is now owned by exact pinned `activeadmin-themes` source. Its
installer produces one deterministic application-owned
`active_admin_texas_bluebonnet.css`; the host explicitly imports that file, opts
the page into the theme on `body`, and maps documented composition slots onto
existing semantic markup. The local monolithic prototype stylesheet has been
deleted. No route, authorization rule, React behavior, server fallback or native
ActiveAdmin interaction moved into the gem.

## Exact Screenshot Provenance

The historical design source was
`13a2557f7f92bc7d9513e96b74bb363e88e7b775`, refreshed onto `master` at
`cedad515622940ed5200a408dd98bff7e6f9a462` after the semantic icon foundation
landed. The final rendering source is exact commit
`6659983e286dbd9762a6727c6a73b12bc8e7be31`, which reconciles the accepted
Bluebonnet composition with the Privacy View and Global Search work merged on
`master`. These images are fresh consumer-path evidence generated from that
committed source, with
`activeadmin-themes` pinned to merged
exact-master commit `96db6599a0668cfa2338769b35b38262ba9f49d1`. Local macOS Chromium via repository-locked
Playwright; synthetic `bin/browser-server` seed; viewport height 1000, widths 1440
and 390; full-page capture. Light/dark root state is explicitly selected by the
test before capture. No production data or credentials are in these artifacts.

Command:

```sh
CI=1 PLAYWRIGHT_PORT=3177 CAPTURE_SHOWCASE_SCREENSHOTS=1 mise exec -- \
  npx playwright test test/browser/bluebonnet_workspace.spec.ts
```

All four cases pass: render, document overflow check, filter/reset, next page,
native drawer open and Escape dismissal. Assertions cover the accessible Rows
name/native tooltip, visually hidden label, matching header/table background,
compact desktop header/footer heights and retained 44px narrow Rows control.
The shared registry owns the explorer glyph and the request spec proves the
Heroicons symbol reference. All 414 RSpec examples pass at 92.30% line and 85.10%
branch coverage; TypeScript, all 185 Vitest tests at 100% coverage, the production
build, all 46 Chromium cases, RuboCop, RBS validation, Brakeman, Bundler Audit and
npm audit pass. The browser server builds the assets afresh. This is not a full
accessibility, physical-device, multi-browser, or release acceptance claim.

| Capture | SHA-256 |
| --- | --- |
| 1440 light | `0065315f7546d06d4829e5f1c1a068ee74df6e6cff2ed019e41f7b5f7ee04d54` |
| 1440 dark | `df6d5c14780f718306d287c48911fef1d9596f9977c26f08ddeb229f89fdbec1` |
| 390 light | `08721a2132b2a52c90767b4aa5937398a3e8ca7a07975893af4370d84218fb53` |
| 390 dark | `b44fb4b24f325ef89169c4db554d97021572244ee812753fa3aa0c69e849cb6b` |

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

## Remaining Acceptance Boundary

Narrow tables deliberately scroll horizontally, preserving the native column data.
Broader keyboard, zoom, contrast, preference and browser/device acceptance remains
necessary before adopting this as a full theme. No merge, release, publication or
Rodeo adoption is implied by this prototype.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
