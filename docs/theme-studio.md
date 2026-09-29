<!-- docs/theme-studio.md -->

# Theme Studio prototype

Theme Studio is a Showcase-only semantic editor for the pinned
`activeadmin-themes` 0.2.0 contract. It deliberately does not establish a
second theme engine or a generic runtime schema.

## Architecture mapping

The prototype reads `ActiveAdmin::Themes.registry.fetch(:v3)` and projects the
gem's existing value objects without replacing them:

- `Theme` remains the binding between one `Skin` and one `Composition`.
- `Skin` remains the owner of the ordered `foundation/tokens` manifest.
- `Composition` remains the owner of the ordered structural manifest and its
  host-applied semantic slots.
- `Theme#recipe_version` and the ActiveAdmin version requirement remain visible
  provenance rather than editor-owned metadata.

The V3 skin already declares semantic light/dark colors, typography and bounded
geometry tokens, so the editor can safely expose allowlisted values for those
roles. V3 0.2.0 does not declare interchangeable navigation, workspace or
page-header variants. Those composition controls therefore remain read-only;
the prototype does not invent a parallel layout model.

## Interaction boundary

React owns reversible preview state, surface and viewport simulation, automated
contrast feedback, and the deterministic authoring proposal. Edits are not
persisted. Reset reconstructs the exact Rails-projected baseline. Color inputs
can change only declared semantic roles; typography and geometry use bounded
allowlists. There is no arbitrary CSS input or injection path.

The preview covers index/table, show/detail, form/validation and dashboard
surfaces in desktop, tablet and narrow frames. It uses the shared Heroicons
semantic registry for functional icons. Light and dark token values are edited
independently.

Rails renders the installed theme, skin, composition, manifest and recipe
version as a useful no-JavaScript fallback. Authentication remains the native
ActiveAdmin boundary.

## Accessibility guardrails

The editor reports text, muted text, link, focus and status contrast ratios,
light/dark token completeness, and the current coarse-pointer control height.
These are immediate design guardrails, not a claim of WCAG conformance. Manual
keyboard, zoom, forced-colors, reduced-motion and assistive-technology review
remain required before a generated theme could be accepted.

## Export exploration

The deterministic preview mirrors the installed skin and composition manifest
order and emits only allowlisted state. It is explicitly labelled an authoring
proposal, not an importable format. A future upstream composer must define and
validate any real `theme.yml` schema before the Showcase exports runnable
recipes.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
