<!-- docs/file-image-manager.md -->

# File & Image Manager

The File & Image Manager is an Active Storage demonstration seeded with a
synthetic PNG and text document. It proves useful preview and file-management
behavior while keeping storage ownership and authorization in Rails.

## Safety boundary

- Every upload and delete command requires an authenticated ActiveAdmin user
  and Rails CSRF protection.
- `ShowcaseAsset` accepts only PNG, JPEG, PDF, and plain text, with a 5 MB
  maximum and an 80-character title.
- Active Storage performs content identification; browser-supplied MIME data is
  not the final trust decision.
- The React island receives signed Rails blob paths, filenames, sizes, and
  presentation metadata. It never receives service credentials.
- The page reads persisted assets without creating or replacing records during
  rendering. `db:seed` provisions deterministic synthetic fixtures; the reset
  service remains test and maintenance infrastructure, not a user-facing route.

The fallback renders signed download links plus ordinary multipart upload,
and delete forms. The interactive island adds selected-file details, client-side
early validation, image/download previews, pending states, server error feedback,
and an accessible Cancel / Delete asset confirmation for destructive actions.

## Storage and recovery

Development and the initial single-host production topology use the Rails local
disk service under `/rails/storage`, which is a persistent Kamal volume. Copy
the Active Storage blob key tree to encrypted, versioned off-host backup storage
together with the SQLite snapshots. See [SQLite backups](backups.md).

## Verify

```bash
bin/test
bin/browser-test
```

The Chromium scenario signs into the real ActiveAdmin host, sees the seeded
image preview, uploads and persists a text file, cancels its deletion once, and
then explicitly confirms deletion.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
