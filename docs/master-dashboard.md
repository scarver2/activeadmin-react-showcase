<!-- docs/master-dashboard.md -->

# Master Dashboard

Issue [#87](https://github.com/scarver2/activeadmin-react-showcase/issues/87)
adds a Showcase-owned capability demonstration on the reusable Texas Bluebonnet
theme. It is not a second theme implementation and it is not a canonical Rodeo
dashboard. `activeadmin-themes` owns the installed composition stylesheet;
Showcase owns the synthetic information architecture, Rails data contract, React
disclosure behavior, native destinations, and browser evidence in this document.

## Reference Translation

Three Sheriff-supplied references informed the information hierarchy without
contributing assets, copied markup, business names, or palette values:

- the launcher reference established major, icon-led capability anchors;
- the operational cockpit established a restrained cross-domain signal strip;
- the workflow map is reserved for focused subdashboards where sequence and
  handoffs carry real meaning.

The resulting governing model is **Glance first. Inspect second. Act third.** At
rest, four large semantic icons, synthesized state labels, and compact minor
indicators answer “where should I look?” without explanatory paragraphs. Hover or
keyboard focus reveals contextual evidence. Click/tap pins the same disclosure for
touch users. The disclosure explains why the state matters, records freshness, and
offers only Rails-owned destinations. The client does not derive business health.

## Rails And React Boundary

`Showcase::WorkspaceCatalog` owns the synthetic state conclusion, deterministic
supporting indicators, freshness, explanatory copy, semantic icon names, and
server-generated ActiveAdmin URLs. Each destination continues to own its
authorization and behavior. The ActiveAdmin dashboard supplies the three
cross-domain signals and renders a complete grouped-link fallback when JavaScript
is unavailable.

`MasterDashboard` presents that contract. It does not query records, authorize
destinations, invent health rules, implement Global Search, or implement Privacy
View. Its functional glyphs come from the accepted Heroicons-first semantic
registry. The existing ActiveAdmin drawer remains on demand and retains its native
trigger, Escape handling, and Turbo lifecycle.

## Visual Evidence

The primary captures prove the quiet resting surface in both presentations and
representative viewports.

| Presentation | Desktop — 1440 × 1000 | Narrow — 390 × 1000 |
| --- | --- | --- |
| Light | ![Icon-first dashboard, desktop light](screenshots/master-dashboard-1440-light.png) | ![Icon-first dashboard, narrow light](screenshots/master-dashboard-390-light.png) |
| Dark | ![Icon-first dashboard, desktop dark](screenshots/master-dashboard-1440-dark.png) | ![Icon-first dashboard, narrow dark](screenshots/master-dashboard-390-dark.png) |

Three separate captures prove representative disclosure grammar rather than
substituting a resting screenshot for interaction evidence.

| Hover | Keyboard focus | Touch-equivalent pin |
| --- | --- | --- |
| ![Sales disclosure on hover](screenshots/master-dashboard-disclosure-sales.png) | ![Production disclosure with visible keyboard focus](screenshots/master-dashboard-disclosure-production.png) | ![Operations disclosure pinned](screenshots/master-dashboard-disclosure-operations.png) |

The focused Chromium scenario proves four major anchors, twelve minor indicators,
resting-state terseness, three disclosure mechanisms, native links, narrow layout,
light/dark presentation, no document-level horizontal overflow, and native drawer
open/Escape behavior. Component tests independently cover resting, hover/focus,
pin, and close states. Request specs prove authentication, server data, native
fallback links, installed theme opt-in, and the absence of dashboard-owned Global
Search and Privacy behavior.

## Provenance

Captured from committed application source
`f3840ba7a71bdc2b8220542c7aa25d50a2b4cb05` on 2026-09-28 with Playwright
1.63.0 / Chromium on macOS. Earlier dashboard captures were replaced because
evidence does not transfer across the installed-theme and interaction rewrite.

```text
aaebfaffc423f0102bed4f1b9278d1ebe9dc336d588a4a06c74d1fef16d2c24d  master-dashboard-1440-light.png
273735364729fa71e93185910985a8609997cf9ee4a7e4adce4741f03c0431ff  master-dashboard-1440-dark.png
bdf91da48c8b8000149a1e17f08da700757af8f4d1b0e9285608f045b970c048  master-dashboard-390-light.png
3dcf9088bfbe81ba5157d695664677564f5bbed80ad31f231b9f9d2245bad451  master-dashboard-390-dark.png
a7884d46785d5635361fb6a319c542651efb79d703bf26afea71e569c3d8086b  master-dashboard-disclosure-sales.png
106aaeed6ae14339df8e170234c863e19a581f7445e5f2c6f4e31953841e9e33  master-dashboard-disclosure-production.png
56c6120282b8bd3ce8438d9d80160ab0d99cf0f135ad8e75fed902eaaa7202e3  master-dashboard-disclosure-operations.png
```

This evidence does not claim multi-browser, physical-device, publication,
deployment, release, or Rodeo adoption acceptance.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
