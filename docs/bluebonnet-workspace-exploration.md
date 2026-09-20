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

AccountExplorer and its endpoint are unchanged. Sorting, filters, pagination,
authorization and account URLs remain Rails-owned. The page still renders through
ActiveAdmin, including its menu, user controls, notifications and dark-mode control.
The prototype has a server fallback link to native Account views without JavaScript.
Nothing is promoted to activeadmin-themes.

If approved later, the token block belongs to foundation, shell/workspace rules to
composition, table/control styling to components, this page to surfaces, and narrow,
focus/preference rules to hardening. These are intentionally kept in one scoped
prototype stylesheet until the design itself is accepted.

## Exact Screenshot Provenance

Source: `af4b098e9dcfffdaf11802ed433bd2d79aed496b`, based on #69 source
`7c5ef2387df36f30d37a05cb6cea835aa09e6ed7`. The following documentation/artifact
commit does not alter rendered source. Local macOS Chromium via repository-locked
Playwright; synthetic `bin/browser-server` seed; viewport height 1000, widths 1440
and 390; full-page capture. Light/dark root state is explicitly selected by the
test before capture. No production data or credentials are in these artifacts.

Command:

```sh
CI=1 PLAYWRIGHT_PORT=3119 CAPTURE_SHOWCASE_SCREENSHOTS=1 mise exec -- \
  npx playwright test test/browser/bluebonnet_workspace.spec.ts
```

All four cases pass: render, document overflow check, filter/reset, next page,
native drawer open and Escape dismissal. Full RSpec: 392 examples, zero failures,
92.18% line / 85.21% branch coverage. TypeScript and changed Ruby RuboCop pass.
The browser server builds the assets afresh. This is not a full accessibility,
physical-device, multi-browser, or release acceptance claim.

| Capture | SHA-256 |
| --- | --- |
| 1440 light | `174d010b1d87f068f3b2871b66c284babd6a6eda727d34f3aea9cb10e6dec6c2` |
| 1440 dark | `89f604958a9f521490ebe2534e32082c42fad3efd7aa2818c3923370b3c1bf5c` |
| 390 light | `d244fadcfbc93fd2faabe7b82a4521bdf8e4a7923605efd6db7ddf0c8bcca0a8` |
| 390 dark | `16059cc752c88239351791707bb9dce9360bb5f67f02d53a383400f506b1c3f4` |

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
