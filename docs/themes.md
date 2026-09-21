<!-- docs/themes.md -->

# ActiveAdmin Themes integration

The showcase composes two independent libraries:

- [`activeadmin-themes`](https://github.com/scarver2/activeadmin-themes) owns the reusable ActiveAdmin presentation recipe.
- [`activeadmin-react`](https://github.com/scarver2/activeadmin-react) owns optional React-island mounting and operation primitives.
- this application owns authentication, authorization, data, theme installation, asset compilation, and showcase-specific component styling.

`activeadmin-themes` has not published a RubyGems release yet. The Gemfile
therefore pins the reviewed public source contract at exact commit
[`c29216395c358acac3ae1c8863a31a0113334cec`](https://github.com/scarver2/activeadmin-themes/commit/c29216395c358acac3ae1c8863a31a0113334cec).
Do not float this dependency on `master`.

The host explicitly loads the gem's Rake tasks and installed recipe 1 with:

```bash
bundle exec rake 'activeadmin_themes:install[v3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[v3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:install[texas_bluebonnet,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[texas_bluebonnet,app/frontend/styles/active_admin.css]'
```

The installer created `app/frontend/styles/active_admin_v3.css` and
`app/frontend/styles/active_admin_texas_bluebonnet.css`; the application
entrypoint imports both into the existing Vite/Tailwind build. The generated
files are deliberately committed and application-owned. Re-running `status`
must report `identical`; a modified destination is a review event, never an
invitation to overwrite local work.

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

The formerly local `bluebonnet_workspace.css` has been removed. No gem CSS is
copied into handwritten host styles, no runtime theme switcher is introduced,
and loading the gem does not mutate ActiveAdmin. The committed application-owned
stylesheet is byte-equal to `ActiveAdmin::Themes::Recipes::TexasBluebonnet.source`.

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
