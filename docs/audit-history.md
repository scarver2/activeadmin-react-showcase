<!-- docs/audit-history.md -->

# Audit history and diffs

## Demo

The page shows deterministic synthetic PaperTrail versions, actors, timestamps, complex values, field filtering, and a non-mutating restoration preview.

## Ruby

PaperTrail 17 records immutable provenance. `paper_trail_diff` 0.12.0 compares a selected historical endpoint with the current record and returns structured immutable values. Actual restoration is deliberately absent until a separately authorized Rails command owns it.

## JavaScript

React presents field filters, chronological comparisons, and the preview. It cannot edit version rows or restore records.

## Architecture

This consumes [PaperTrail](https://github.com/paper-trail-gem/paper_trail) and Alex Heath-Williams' [paper_trail_diff](https://github.com/aheathwilliams/paper_trail_diff) through their public APIs. No application patch or upstream defect was required.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
