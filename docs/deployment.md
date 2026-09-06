<!-- docs/deployment.md -->

# Deployment

The initial Kamal topology is one inexpensive Rails host. Puma and Solid Queue
share the application container; SQLite, Solid Cache, Solid Queue, and Solid
Cable require no accessories.

## Required decisions and variables

- `KAMAL_HOST` — server IP or SSH-resolvable host.
- `KAMAL_APP_HOST` — public DNS name served by kamal-proxy HTTPS.
- `KAMAL_IMAGE` — registry image name; defaults to `scarver2/activeadmin-react-showcase`.
- `KAMAL_REGISTRY_SERVER` and `KAMAL_REGISTRY_USERNAME` — default to GitHub Container Registry and `scarver2`.
- `KAMAL_BACKUP_PATH` — absolute host directory on storage covered by encrypted off-host backups.
- `KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`, `SHOWCASE_ADMIN_EMAIL`, and `SHOWCASE_ADMIN_PASSWORD` — deploy secrets.

Staging additionally requires `KAMAL_STAGING_HOST`,
`KAMAL_STAGING_APP_HOST`, and `KAMAL_STAGING_BACKUP_PATH`.

## Commands

```bash
bin/kamal config
bin/kamal setup
bin/kamal deploy
bin/kamal app logs
bin/kamal app details
bin/kamal proxy logs
bin/kamal deploy -d staging
```

Do not deploy until DNS, HTTPS, registry access, persistent-volume placement,
off-host backup replication, restore testing, and public-demo abuse controls are
reviewed. Roll back application code with Kamal; never roll back a database by
overwriting live SQLite files while the app is running.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
