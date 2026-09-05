<!-- docs/backups.md -->

# SQLite Backups

Primary, Solid Queue, Solid Cache, and Solid Cable databases live under
`/rails/storage` on the persistent `activeadmin-react-showcase-storage` volume.
They must never live only in a release container layer.

Solid Queue runs `SqliteBackupJob` daily at 02:00. The job uses SQLite's online
backup API to create consistent copies and a `SHA256SUMS` manifest under
`/rails/backups`. Operators can trigger the same operation with:

```bash
bin/kamal backup
```

`KAMAL_BACKUP_PATH` bind-mounts that directory from the host. Before production
go-live, configure the host's backup service to replicate it to encrypted,
versioned off-host storage with retention and alerting. A same-host snapshot is
useful for operator error but is not disaster recovery.

At least quarterly, restore the latest snapshot into staging, verify every
checksum, run all migrations, boot Rails, and execute `bin/browser-test` against
the restored data. Stop writers before replacing database files. Record the
snapshot timestamp, restore duration, and verification result.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
