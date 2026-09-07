<!-- README.md -->

# ActiveAdmin React Showcase

The canonical living demonstration and integration application for
[`activeadmin-react`](https://github.com/scarver2/activeadmin-react). It keeps
authentication, authorization, navigation, persistence, background work, and
server fallbacks in Rails while mounting focused React 19 islands where richer
interaction is valuable.

This foundation is under active development and is not deployed publicly yet.

## Repository relationships

- `activeadmin-react` — small, generic OSS integration primitives.
- `activeadmin-react-showcase` — rich examples, experimentation, and executable reference implementation.
- Rodeo — enterprise consumer and dogfood environment.

Showcase-only libraries stay here unless repeated use proves that a generic
primitive belongs in the gem.

## Foundation stack

- Ruby 4.0.6, Rails 8.1.3.1, and ActiveAdmin 4.0.0.beta22
- `activeadmin-react 0.1.0.alpha1`, with optional local sibling source override
- SQLite with Solid Queue, Solid Cache, and Solid Cable
- React 19, TypeScript, Vite, Tailwind CSS, Vitest, and Playwright Chromium
- Recharts analytics with a Rails-authenticated, bounded JSON data contract
- RSpec, SimpleCov, RuboCop, RBS, Brakeman, and Bundler Audit
- Docker and Kamal 2, designed for one inexpensive host

PostgreSQL and Redis are intentionally absent. Normalized Active Record models,
portable migrations, and adapter boundaries preserve an uncomplicated future
PostgreSQL migration if measured load justifies it.

## Setup

Place this repository beside an `activeadmin-react` checkout, then run:

```bash
bin/setup --skip-server
bin/dev
```

The local commands automatically set `ACTIVEADMIN_REACT_PATH` to
`../activeadmin-react` when that sibling exists. Unset it to exercise the
released gem exactly.

Local credentials are `admin@example.test` / `showcase-password`. Production
credentials must be supplied as secrets.

`bin/rails db:prepare db:seed` creates six believable SaaS accounts and 30 days
of deterministic operating metrics per account.

## Verification

```bash
bin/test
bin/browser-test
bin/ci
bin/doctor
```

`bin/browser-test` signs into ActiveAdmin in real Chromium and proves the seeded
Rails data reaches mounted React islands, including date-filtered analytics. The
Lexical Editor example additionally proves create, validation-error state
preservation, and edit flows through an ordinary ActiveAdmin form.

## Documentation

- [Development](DEVELOPMENT.md)
- [Architecture](ARCHITECTURE.md)
- [Documentation index](docs/README.md)
- [Deployment](docs/deployment.md)
- [SQLite backups](docs/backups.md)
- [Testing](docs/testing.md)
- [Showcase roadmap](docs/roadmap.md)
- [Security](docs/security.md)

## License

MIT. See [LICENSE](LICENSE).

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
