<!-- docs/message-preview.md -->

# Development message and document preview

## Demo

This non-production page inspects deterministic synthetic mail in HTML or text form and previews allowlisted image/PDF attachments. Office documents are bounded downloads and are never executed in the browser.

## Ruby

Rails gates registration outside production, sanitizes HTML, allowlists MIME types, enforces a 2 MB preview bound, and generates only Active Storage URLs. Missing, mislabeled, unsupported, and oversized attachments do not become arbitrary filesystem reads.

## JavaScript

React owns accessible message/body tabs and attachment presentation. Sandboxed HTML cannot execute embedded scripts. Direct links and server-rendered metadata remain available without JavaScript.

## Architecture and upstream credit

Development delivery uses [`letter_opener_web`](https://github.com/fgrehm/letter_opener_web) 3.0.0, built on Ryan Bates' influential [`letter_opener`](https://github.com/ryanb/letter_opener), mounted at `/letter_opener` only in development. The ActiveAdmin island complements that upstream mailbox with bounded rich-attachment teaching examples; it does not replace delivery or browse arbitrary mail paths. No upstream compatibility defect was found.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
