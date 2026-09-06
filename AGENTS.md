<!-- AGENTS.md -->

# ActiveAdmin React Showcase Agent Policy

Follow the machine-wide Rails, React, RSpec, Git, database, documentation, and
bin-script standards.

- Default branch: `master`; develop on descriptive `feat/`, `fix/`, `docs/`, or `chore/` branches.
- Initial production topology: one Rails host with SQLite, Solid Queue, Solid Cache, and Solid Cable.
- Do not add PostgreSQL or Redis without measured need and an explicit migration/operations plan.
- Keep schema and Active Record boundaries portable so PostgreSQL remains an easy scale-out option.
- All production SQLite files belong on persistent Kamal storage and require consistent snapshots, encrypted off-host replication, and restore drills.
- Keep rich showcase dependencies out of the `activeadmin-react` gem.
- Never deploy or publish from ordinary PR CI.

Repository documentation begins at [README.md](README.md) and [docs/README.md](docs/README.md).

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
