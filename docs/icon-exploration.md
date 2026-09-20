<!-- docs/icon-exploration.md -->

# Texas Bluebonnet Icon Exploration

This is a Showcase-only review candidate, not an upstream icon API or a broad
rollout. The existing Classic and Texas Bluebonnet palette values are unchanged.

## Design Boundary

- Functional geometry first: dashboard, records, people, reports.
- A single outlined five-point star marks Showcase Home under Texas Bluebonnet.
  Classic uses the dashboard grid. No hats, boots, rope, cartoons or mascots.
- Original 24-unit SVG geometry, 1.65-unit square-ended strokes, no fills.
- Navigation, two server-rendered dashboard shortcuts, and the existing
  FoundationStatus React island are the only adoption sites.
- The metric card now consumes existing semantic surface/text/border tokens;
  no token values, business data, permissions or persistence rules change.

`public/showcase-icons.svg` owns the shared geometry. `showcase_icon` and
`ThemeIcon` render decorative references with `aria-hidden` and `focusable=false`.
Visible text remains the accessible name. CSS uses currentColor and the existing
theme marker; neither renderer stores preference state or replaces native actions.
The existing user, notification and theme-toggle icons are deliberately untouched.

## Review Images

Captured from source commit `929d21d5bc587587a2bb32f5d4118fd95252607d`, based on
the refreshed #69 head `1b5890ddb573f364407549b81c29b1f98b328911`.
Playwright 1.63.0 / real Chromium 153.0.8010.12, macOS 26.7, September 19, 2026
(America/Chicago), viewport 1440×1000 at default zoom. Test-host reset/seed data,
authenticated `/admin`, native theme selector and native light/dark toggle.
All three adoption sites are visible together on the same dashboard.

Command: `CAPTURE_SHOWCASE_SCREENSHOTS=1 CI=true PLAYWRIGHT_PORT=3197 mise exec -- npx playwright test test/browser/theme_icons.spec.ts`.
Both browser scenarios passed, including server-rendered navigation/shortcuts
without JavaScript. Images were visually inspected; labels, thin icon silhouettes,
selected navigation and light/dark surfaces remain readable at this viewport.

| Classic | Texas Bluebonnet |
| --- | --- |
| ![Classic light](screenshots/icons-v3-light.png) | ![Bluebonnet light](screenshots/icons-v3_texas-light.png) |
| ![Classic dark](screenshots/icons-v3-dark.png) | ![Bluebonnet dark](screenshots/icons-v3_texas-dark.png) |

SHA256 artifact hashes:

```text
icons-v3-light.png        3cd1942fb4fd22413c3e6756f6ab904220c33a7e91beaf75955f83ba133ca9a0
icons-v3-dark.png         21d0a47847ce4695aca1da026e6ac3d5ad05318d9b8da514ea1fabb52fc08f4b
icons-v3_texas-light.png  623c02614a5cc888518761dab41de607e9032015e9e0bf37a4d7d05d2fcc6e6c
icons-v3_texas-dark.png   667f7e39a45ad232751211a8e24cab7d0cceaa91cb6a62e7d5eb66edd9d2399a
```

This is not multi-browser, physical-device, full accessibility or responsive
acceptance. Human visual approval is required before expanding the vocabulary.
No upstream promotion to `activeadmin-themes` or `activeadmin-react` is proposed.
A future novelty/cartoon theme, if requested, must remain a separate design system.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
