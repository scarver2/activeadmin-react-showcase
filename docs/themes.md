<!-- docs/themes.md -->

# ActiveAdmin Themes integration

The showcase composes two independent libraries:

- [`activeadmin-themes`](https://github.com/scarver2/activeadmin-themes) owns the reusable ActiveAdmin presentation recipe.
- [`activeadmin-react`](https://github.com/scarver2/activeadmin-react) owns optional React-island mounting and operation primitives.
- this application owns authentication, authorization, data, theme installation, asset compilation, and showcase-specific component styling.

`activeadmin-themes` has not published a RubyGems release yet. The Gemfile
therefore pins the reviewed public source contract at exact commit
[`0266827e7eb74842bfad05cc387339945ee61452`](https://github.com/scarver2/activeadmin-themes/commit/0266827e7eb74842bfad05cc387339945ee61452).
Do not float this dependency on `master`.

The host explicitly loads the gem's Rake tasks and installed recipe 1 with:

```bash
bundle exec rake 'activeadmin_themes:install[v3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[v3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:install[texas_bluebonnet,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[texas_bluebonnet,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:install[workbench_13,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[workbench_13,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:install[workbench_2,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[workbench_2,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:install[workbench_3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[workbench_3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:install[mui,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[mui,app/frontend/styles/active_admin.css]'
```

The installer created `app/frontend/styles/active_admin_v3.css`,
`app/frontend/styles/active_admin_texas_bluebonnet.css`, and
`app/frontend/styles/active_admin_workbench_13.css`, and
`app/frontend/styles/active_admin_workbench_2.css`, and
`app/frontend/styles/active_admin_workbench_3.css`, and
`app/frontend/styles/active_admin_mui.css`; the application entrypoint imports them into the existing Vite/Tailwind build. The generated files are
deliberately committed and application-owned. Re-running `status` must report
`identical`; a modified destination is a review event, never an invitation to
overwrite local work.

The recipe styles native ActiveAdmin chrome, tables, filters, forms, status surfaces, login, responsive behavior, and the framework's existing light/dark state. React islands inherit the same semantic CSS variables where their presentation overlaps. The theme does not own island state, Rails commands, persistence, or server-rendered fallbacks.

Verification includes request coverage, byte-for-byte recipe provenance, real-Chromium navigation through ordinary resources/forms and React islands, keyboard focus inspection, and a JavaScript-disabled fallback. Screenshots are durable visual evidence, not a substitute for those checks.

## Texas Bluebonnet Full Theme

The accepted Texas Bluebonnet composition is consumed through the same recipe
boundary. The host opts its Account Data Explorer study into
`data-activeadmin-theme="texas-bluebonnet"`, then maps the gem's immutable
composition slots onto existing semantic Rails and React markup. The gem owns
the palette, shell, workspace, action, data, support, responsive and preference
presentation. Showcase still owns the route, authentication, authorization,
AccountExplorer behavior, native fallback and semantic HTML.

ActiveAdmin 4.0.0.beta22 has no supported server-side body-attribute hook. The
host therefore carries an exact upstream layout override with one rendered
divergence: the conditional Texas Bluebonnet data attribute. A source-parity
spec pins the upstream layout hash and proves every other byte remains aligned;
an ActiveAdmin upgrade must deliberately refresh that compatibility boundary.
The same bounded override applies `data-activeadmin-theme="workbench-13"` and
`data-activeadmin-theme="workbench-2"`, and
`data-activeadmin-theme="workbench-3"` only to their respective laboratory routes.

The formerly local `bluebonnet_workspace.css` has been removed. No gem CSS is
copied into handwritten host styles, no runtime theme switcher is introduced,
and loading the gem does not mutate ActiveAdmin. The committed application-owned
stylesheet is byte-equal to `ActiveAdmin::Themes::Recipes::TexasBluebonnet.source`.

## Workbench 1.3 Heritage Theme

Workbench 1.3 uses the same recipe and composition boundary. The gem owns its
fixed historical colors, compact system-monospace treatment, labelled CSS drawer
art, window framing, data and form presentation, responsive reflow, visible
focus, reduced-motion and forced-colors rules. It deliberately does not invent
a dark historical variant.

Showcase owns the authenticated page, bounded Account query, allowlisted GET
filter, semantic table/form markup, native resource routes, no-JavaScript path,
provenance ledger and browser evidence. Its committed stylesheet is byte-equal
to `ActiveAdmin::Themes::Recipes::Workbench13.source`; the removed local
`workbench_13.css` is no longer an alternate presentation implementation.

## Workbench 2.x Heritage Theme

Workbench 2.x is a separate fixed historical composition, not a palette switch
on the Workbench 1.3 page. The gem owns its gray, black, white and blue four-pen
roles, pseudo-3D raised/inset geometry, compact navigation, launchers, windows,
data, form/action presentation, responsive reflow and user-preference rules. It
does not invent a dark historical variant or copy historical bitmaps and fonts.

Showcase owns a distinct authenticated route and semantic partial. Both
Workbench laboratories share the host-owned `HeritageAccountsWorkspace` query,
which allowlists account status, orders deterministically and returns at most
eight records without mutation. Each route retains its own GET form, native
resource links, no-JavaScript path, provenance and browser evidence. The
committed Workbench 2.x stylesheet is byte-equal to
`ActiveAdmin::Themes::Recipes::Workbench2.source`; there is no local presentation
override or runtime theme switcher.

## Workbench 3.x Heritage Theme

Workbench 3.x is a third independent composition. It retains the historical
four-pen lineage while adding a dithered late-Commodore work surface, white
screen-information bar, active-blue title hierarchy and denser ruled window
headers. Those structural relationships distinguish it from Workbench 2.x;
the page is not the previous theme with substituted colors. It also excludes
MUI's preference-driven toolkit vocabulary and later Amiga Forever 3.X
enhancements.

Showcase owns another distinct authenticated route and semantic partial while
reusing the unchanged host-owned `HeritageAccountsWorkspace` behavior. The
route keeps its own GET form, native resource links, no-JavaScript path,
provenance and browser evidence. The committed Workbench 3.x stylesheet is
byte-equal to `ActiveAdmin::Themes::Recipes::Workbench3.source`; there is no
host presentation override or runtime theme switcher.

## MUI Heritage Theme

MUI changes the lineage from a desktop shell to a configurable application
toolkit. The gem owns framed groups, registers, recessed fields, raised gadgets,
adaptive layout, the same immutable 24 semantic composition roles, and an
original silver/charcoal/teal baseline. Showcase owns a separate authenticated
route, semantic Rails partial, bounded query, native form and resource links,
no-JavaScript path, provenance, and browser evidence.

The committed stylesheet is byte-equal to
`ActiveAdmin::Themes::Recipes::Mui.source`. To prove the documented MUI
configurability contract without forking the recipe, Showcase overrides only
`--mui-active` under the laboratory's `data-mui-preset="showcase-amethyst"`
marker. The 24-role map, every composition class, and every component selector
remain gem-owned and unchanged. This is a bounded preference proof, not a local
presentation implementation or runtime theme switcher.

## Skin / Color Palette Switcher And Token Bridge

The authenticated title bar exposes three color palettes: **Classic Neutral**,
**Limestone & Ink**, and **Slate & Copper**. They recolor the same V3 composition;
they are not separate themes or layouts. The preference belongs to the current
`AdminUser`; no user id is accepted from the browser. React applies the choice
optimistically and rolls back when Rails rejects it. The HTML fallback uses the
same authenticated update without JavaScript.

All palettes keep the installed V3 structural recipe, routes and interactions.
They change semantic color properties, not layout geometry. Light/dark mode is
independent. Representative React islands use the `showcase-themed-island` bridge.
Slate & Copper is an original local palette: no Solarized or other third-party
palette names/values were imported. Existing semantic status colors remain inherited.

The legacy column/API/component names (`theme_preference`, `ThemeSwitcher`,
`data-showcase-theme-marker`) and `v3_texas` value remain compatibility details,
not user-facing theme names. `v3_texas` now displays **Limestone & Ink** so saved
preferences continue to work without a destructive migration. **Texas Bluebonnet**
is reserved for the separate full-composition prototype, not this switcher.
Older screenshots retain their original labels as historical evidence.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
