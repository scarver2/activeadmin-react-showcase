<!-- docs/csv-import.md -->

# CSV Import and Column Mapping

## Demo

Upload a synthetic UTF-8 CSV no larger than 100 KB or 100 data rows. Rails returns at most five preview rows. Map each source header to the four allowlisted contact fields, review the sample, and explicitly confirm before background work begins.

## Ruby

`CsvImports::Reader` checks attachment presence, bytes, encoding, CSV shape, unique headers, and row count. `CsvImports::Mapping` rejects unknown or duplicate destinations. `ProcessCsvImportJob` applies a documented partial-import policy: valid rows commit while invalid rows retain bounded durable errors.

Each source row has a unique `(csv_import_id, row_number)` marker. Redelivering the same Solid Queue job cannot duplicate already imported contacts, and email uniqueness provides a second domain-level idempotency boundary.

## JavaScript

React owns preview presentation, mapping controls, confirmation UX, and live progress. It never decides whether bytes, mappings, or rows are valid. Reloading the tokenized page recovers canonical progress from Rails.

## Architecture

Active Storage retains the bounded source. SQLite owns workflow, mappings, row markers, progress, and errors. Solid Queue performs work after confirmation. Solid Cable delivers persisted progress snapshots; it is not a job runner or source of truth. The ordinary multipart Rails form supports canonical headers without JavaScript.

This demonstration contains only synthetic contacts. Real customer imports require an explicit PII classification, retention, export, and deletion policy.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
