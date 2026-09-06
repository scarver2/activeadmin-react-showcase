<!-- DEVELOPMENT.md -->

# Development

## Toolchain

The repository pins Ruby 4.0.6 and Node 24.20.0 through mise. All project
commands resolve those runtimes without relying on an interactive shell.

```bash
bin/setup --skip-server
bin/doctor
bin/dev
```

`bin/dev` runs Rails, Vite, and the Solid Queue supervisor through `Procfile.dev`.
SQLite requires no separate service container.

## Local gem dogfooding

When `../activeadmin-react/lib` exists, project commands export that directory as
`ACTIVEADMIN_REACT_PATH`. Both the Ruby initializer and Vite alias then load the
sibling checkout. Set the variable explicitly for another checkout, or unset it
to verify the locked `0.1.0.alpha1` release.

Keep the sibling checkout on an intentionally reviewed revision. The showcase
never rewrites or checks out that repository automatically.

## Data

```bash
bin/rails db:prepare
bin/rails db:seed
```

Development uses separate SQLite databases for primary data, Solid Cache,
Solid Queue, and Solid Cable. Models use portable Active Record types,
constraints, and indexes so PostgreSQL remains a straightforward future adapter
change rather than an architectural rewrite.

## Workflow

Develop each showcase on a focused `feat/<name>` branch. Analytics Dashboard,
Live Jobs / Operations Center, and the Lexical Editor are the first priorities;
do not combine them into one PR.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
