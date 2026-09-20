<!-- docs/heritage-workbench-13.md -->

# Workbench 1.3 Heritage Laboratory

First bounded study for [Heritage Themes #103](https://github.com/scarver2/activeadmin-react-showcase/issues/103).
Visit `/admin/workbench_laboratory` after signing in, or choose **Overview →
Workbench 1.3 Laboratory**. This is one authenticated AA4 page, not a selectable
application-wide theme, an emulator, or a generalized heritage-theme framework.

Deputy cleared this independent research lane on September 20, 2026: current
master → one Workbench 1.3 surface → screenshot review. It does not depend on or
modify the #72 → #108 → #73 → #105 production composition stack. Generalization,
a second surface and subsequent heritage implementations remain review-gated.

## Reference And Provenance

Primary visual reference, inspected September 20, 2026:

- [Cloanto / Amiga Forever: Workbench 1.3 environment](https://www.amigaforever.com/screenshots/workbench-1-3/).
- [Its linked still image](https://www.amigaforever.com/gfx/screens/screen-afwb-13.png).

The reference shows a preinstalled 1.3 environment, not a guarantee that every
detail is a factory-default setting. We studied its blue desktop, white frame
lines, white title strips with blue lettering/rules, compact monospaced labels,
drawer metaphor, and orange accents. We did not blend in Workbench 2/3 bevels,
MUI, or AmigaOS 4 conventions.

No reference screenshot, ROM, font, logo, Boing Ball, floppy image or other
historical artwork is redistributed. All shipped geometry is original CSS under
the repository license, copyright Stan Carver II. The small drawer illustrations
are specific to this heritage composition, not additions to the ordinary
functional icon vocabulary. This prototype does not import #108's registry.
Workbench is a trademark of Cloanto Corporation; this is an independent study,
not an official product or endorsement.

## Historical Reference → Constraint → Adaptation

| Historical grammar | AA4 / modern constraint | Prototype adaptation |
| --- | --- | --- |
| Blue screen with white framed windows | Existing AA4 administration remains available | One clearly bounded desktop inside the native page; no global chrome replacement |
| White/blue title strips and ruled borders | Meaningful headings, no fake window controls | Semantic section headings with decorative rules; no nonfunctional close/resize buttons |
| Compact monospaced lettering | Readability and font redistribution rights | System monospace at 16px desktop / 14px narrow; no copied Topaz font or bitmap text |
| Small blue/white/orange color vocabulary | Text and focus contrast | Original approximations `#244b9b`, `#fffdf4`, `#10234e`, `#ffae38`; not claimed exact historical values |
| Drawers and desktop navigation | Native links, keyboard, single activation | Original CSS drawer illustrations accompanying visible labels and ordinary links |
| Overlapping windows | Predictable reading order and access to every control | Offset non-overlapping desktop windows; one-column narrow reflow |
| Orange accent / inversion | Selection cannot be color-only | Hover/focus accent accompanies underlined links, focus outline and textual status; no invented selected-record state |
| Requester-style preferences | Server authority; useful without JS | Native labelled GET form filters existing account statuses; Use/Reset controls change no data |
| Fixed desktop-era viewport | Narrow screens, zoom and touch | Flexible window grid, 44px form/menu controls, locally scrollable table with keyboard focus |
| Historical palette rather than light/dark variants | Host dark preference must not corrupt the study | One deliberate historical treatment under either host preference; no invented “dark Workbench” |
| Pixel-era decoration | User preferences remain authoritative | No motion; explicit reduced-motion and forced-colors treatment; no forced-color opt-out |

## Behavior And Boundaries

ActiveAdmin still owns authentication, navigation, resource routes and actions.
The page displays at most eight existing accounts, ordered by name/id; the filter
accepts only `Account::STATUSES`. Unknown values fall back to all statuses and are
not echoed. Record text is Rails-escaped. Account links lead to existing native
views. The page adds no write action, database field, preference persistence,
JavaScript state machine or network dependency. Existing synthetic seed data is
used for evidence; this is not production or Rodeo data.

The outer AA4 shell intentionally remains visible as the laboratory boundary.
The skin selector still controls that shell, not this fixed historical study.
All prototype CSS is rooted at `.wb13`; no theme token values are changed globally.

## Schema Pressure, Not A New API

- **Foundation:** local four-color vocabulary and system monospace.
- **Composition:** screen title, menu, drawer row and reflowing windows.
- **Components:** plain links, native form controls, table, textual status and window framing.
- **Surface:** one read-only account workspace, not new index/show/edit implementations.
- **Hardening:** focus, horizontal table scrolling, narrow reflow and user preferences.

The experiment suggests that frame geometry and heading treatment need to be
separate from palettes, and that icon vocabulary may vary for heritage signature
illustration while functional labels remain stable. These are observations for
#83, not reasons to extract global abstractions before review.

## Verification

Request tests cover authentication, filtering without mutation, unsupported input,
escaping, the eight-record limit, empty recovery and isolation from other pages.
Chromium checks desktop/narrow layouts, GET filtering/reset, keyboard activation,
native resource links, no-JavaScript use and forced-colors focus. Screenshots and
exact capture provenance are added after visual inspection. No pixel-perfect,
physical-device or multi-browser claim is made.

## Collection Remains Open

This PR does not complete #103. Workbench 2.x, Workbench 3.x, MUI, AmigaOS 4,
AROS/Wanderer/Zune, Haiku beta6, Video Toaster 4000/period LightWave, and Mercury
Flight remain separately scoped studies. Mercury Flight requires a local asset
inventory and explicit public-redistribution disposition. The MUI study must carry:

> In memory of Ron Dillard of On Video Dallas, a friend of the Amiga and an enthusiastic MUI fan.

No upstream promotion, publication, deployment or Rodeo adoption is authorized.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
