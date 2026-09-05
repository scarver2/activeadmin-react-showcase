<!-- docs/testing.md -->

# Testing

`bin/test` runs RSpec, TypeScript validation, Vitest with coverage, and the Vite
production build. `bin/browser-test` starts an isolated test server and proves
the ActiveAdmin login plus `activeadmin-react` mount in Chromium. `bin/ci` adds
RuboCop, RBS, Brakeman, and dependency auditing.

The configured floors are 90% line / 80% branch coverage for Ruby and 100% for
the first React component. Browser coverage is deliberately separate so failures
remain attributable.

Future CI should expose independent Ruby, JavaScript, Chromium, Docker, security,
and deployment-configuration jobs. Ordinary PR CI must never deploy.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
