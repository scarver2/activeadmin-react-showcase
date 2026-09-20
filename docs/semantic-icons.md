<!-- docs/semantic-icons.md -->

# Semantic Icons

Showcase-only follow-up to [PR #72](https://github.com/scarver2/activeadmin-react-showcase/pull/72),
implementing [#104](https://github.com/scarver2/activeadmin-react-showcase/issues/104).
The architecture proof remains intact; commodity glyphs now use Heroicons rather
than bespoke drawings. No upstream gem API or broad navigation rollout is implied.

## Shared Meaning, Separate Presentation

`app/frontend/icons/registry.json` is the single semantic mapping consumed by the
Rails `showcase_icon` helper and React `ThemeIcon`. Callers request meaning, not
library names. Both render the same local SVG sprite without JavaScript geometry
bundles, runtime downloads, or a second React-specific vocabulary.

| Semantic name | Heroicons 24 outline glyph |
| --- | --- |
| dashboard | squares-2x2 |
| records | document-text |
| people, customers | users |
| reports | chart-bar |
| calendar | calendar-days |
| settings | cog-6-tooth |
| filters | adjustments-horizontal |
| navigation | bars-3 |

Settings means gear; view/filter tuning means sliders; collapsed navigation means
hamburger. Existing adoption stays limited to Showcase Home navigation, two
dashboard shortcuts and the FoundationStatus React island. Additional semantic
entries establish conventions, not new controls or changed native behavior.

Heroicons is primary. If a future meaning is missing, evaluate Lucide, then Tabler;
record the exact version, asset, license and reason before adding an exception.
There is no silent runtime fallback or mixed-library substitution. Neither fallback
library is bundled today because Heroicons supplies every requested functional icon.
Commercial assets require an independently verified license before adoption.

## Source And License

Eight unmodified SVGs are vendored from
[Heroicons v2.2.0](https://github.com/tailwindlabs/heroicons/tree/ca7b62ead85d617ef4deacc56a82a5f3482184ef/optimized/24/outline),
commit `ca7b62ead85d617ef4deacc56a82a5f3482184ef`, paths
`optimized/24/outline/<glyph>.svg` using the exact names above.
Their [MIT license](../vendor/icons/heroicons/LICENSE) and Tailwind Labs copyright
are retained. Vendored files intentionally retain upstream bytes rather than adding
project prologs. The public sprite changes only the SVG wrapper into a named symbol;
RSpec compares every child element/attribute against its vendored source.

Only this small explicit subset ships, rather than a whole icon package. Native
SVG caching is shared across Rails and React; package tree-shaking is unnecessary.
To upgrade, replace the pinned originals and corresponding symbol children, update
this provenance record, run asset/renderer/browser checks, and review screenshots.

The five-point `landmark` remains original project artwork under the repository MIT
license (Stan Carver II). It is not a functional fallback. A composition may opt in
with `data-showcase-icon-family="bluebonnet"` on an ancestor plus `landmark: true`
or the React `landmark` prop. Color palettes never activate this signature: skin
changes color, while composition owns icon presentation. No composition rollout is
part of this PR.

## Accessibility And Verification

Icons inherit semantic foreground colors through `currentColor`, with Heroicons'
1.5-unit round outline. They remain decorative (`aria-hidden`, `focusable=false`).
Visible labels remain authoritative; an icon-only control must supply its own
accessible name. Selected/status meaning must not depend on icon color alone.

Regression coverage checks shared semantic mapping, frozen Ruby data, exact sprite
geometry, unique symbols, license presence, prohibited executable/remote content,
label ownership, keyboard navigation, no-JavaScript links and palette-independent
signature behavior. Browser images are evidence for these adoption sites, not
multi-browser, physical-device or whole-application accessibility acceptance.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
