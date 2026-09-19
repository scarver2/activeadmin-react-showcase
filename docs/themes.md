<!-- docs/themes.md -->

# ActiveAdmin Themes integration

The showcase composes two independent libraries:

- [`activeadmin-themes`](https://github.com/scarver2/activeadmin-themes) owns the reusable ActiveAdmin presentation recipe.
- [`activeadmin-react`](https://github.com/scarver2/activeadmin-react) owns optional React-island mounting and operation primitives.
- this application owns authentication, authorization, data, theme installation, asset compilation, and showcase-specific component styling.

`activeadmin-themes` has not published a RubyGems release yet. The Gemfile therefore pins the reviewed public source contract at commit
[`1a36089d4876782e94e8850d95e95d4a74b1bc73`](https://github.com/scarver2/activeadmin-themes/commit/1a36089d4876782e94e8850d95e95d4a74b1bc73), whose exact-master [CI run](https://github.com/scarver2/activeadmin-themes/actions/runs/34908421569) is green. Do not float this dependency on `master`.

The host explicitly loads the gem's Rake tasks and installed recipe 1 with:

```bash
bundle exec rake 'activeadmin_themes:install[v3,app/frontend/styles/active_admin.css]'
bundle exec rake 'activeadmin_themes:status[v3,app/frontend/styles/active_admin.css]'
```

The installer created `app/frontend/styles/active_admin_v3.css`; the application entrypoint imports it into the existing Vite/Tailwind build. The generated file is deliberately committed and application-owned. Re-running `status` must report `identical`; a modified destination is a review event, never an invitation to overwrite local work.

The recipe styles native ActiveAdmin chrome, tables, filters, forms, status surfaces, login, responsive behavior, and the framework's existing light/dark state. React islands inherit the same semantic CSS variables where their presentation overlaps. The theme does not own island state, Rails commands, persistence, or server-rendered fallbacks.

Verification includes request coverage, byte-for-byte recipe provenance, real-Chromium navigation through ordinary resources/forms and React islands, keyboard focus inspection, and a JavaScript-disabled fallback. Screenshots are durable visual evidence, not a substitute for those checks.

## Theme switcher and token bridge

The authenticated title bar exposes two deterministic presentations: **V3 Classic** and **Texas Bluebonnet**. The selected recipe variant is stored on the current `AdminUser`; no user id is accepted from the browser. React applies the choice optimistically and rolls back when Rails rejects it, while the fallback form performs the same authenticated update without JavaScript.

Both presentations continue to use the installed V3 structural recipe. The alternate changes only semantic custom properties for surfaces, borders, text, focus, status, chrome, and canvas contrast. Representative React islands opt into the small `showcase-themed-island` token bridge rather than carrying a parallel copy of native ActiveAdmin component rules. ActiveAdmin's existing light/dark preference remains independent and the Texas palette provides both modes.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
