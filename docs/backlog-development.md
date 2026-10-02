<!-- docs/backlog-development.md -->

# Backlog Development Inventory

Snapshot: 2026-09-30, master `0dc353d` (Showcase 0.29.0).
The user authorized development of all open issues, not automatic release or deployment.
An issue remains open until its complete acceptance criteria are delivered.

| Issue | Work | Current state / boundary |
| --- | --- | --- |
| #90 | Personal saved views | Implementation and verification in this branch; independent master base |
| #88 | Universal command palette | Existing palette is a starting point; audit commands, recent context, confirmation, and proof gaps |
| #99 | Reversible actions | Rails-authorized bounded undo; new audited command, not client reversal |
| #95 | Bulk action workbench | Reuse durable operation progress; per-record authorization and retry-safe results |
| #102 | Human/agent handoff | Accepted on master through merged #167 (`80f93c6`): durable owner-scoped synthetic work, native human approval/intervention, command receipts and optional Cable hints. See [contract](work-handoff.md). |
| #93 | Cross-domain timeline | Implemented synthetic laboratory; verification and PR acceptance pending. See [contract](activity-timeline.md). |
| #97 | Contextual relationships | Accepted in merged PR #166; native source inspection, bounded Rails projection and Cytoscape/list proof |
| #92 | Calm attention dashboard | Consume accepted attention/work inputs; no invented scoring |
| #83 | Theme Studio | Accepted prototype preserved; 0.38.0 adds dense-data/login previews and actual surface contrast guardrails. Full authoring/schema acceptance remains open. See [remaining boundaries](theme-studio.md#remaining-acceptance-boundaries). |
| #152 | ABBU interoperability | Public `abbu` source has CSV/JSON/vCard exporters but no archive writer; writer belongs upstream, never local format duplication |

Independent capabilities branch from accepted master. Genuine dependency children
may stack explicitly; versions reconcile in landing order. Mark PRs ready only
after implementation and required evidence are complete. Retain existing evidence,
drafts, and unique Theme Studio work. Do not restart the retired Deputy heartbeat.

Source: [open issues](https://github.com/scarver2/activeadmin-react-showcase/issues).

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
