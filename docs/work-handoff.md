<!-- docs/work-handoff.md -->

# Human and AI-Agent Work Handoff

Issue [#102](https://github.com/scarver2/activeadmin-react-showcase/issues/102)
demonstrates one work system at `/admin/work_handoff`. An authenticated human
creates an owner-scoped synthetic checklist and assigns it to a deterministic
demo agent. There is no AI provider, credential, external request, private Cora
implementation, or Rodeo adoption.

## Authority and lifecycle

`human → agent → approval → completed` requires explicit human approval.
The demo advances three bounded steps of 25%; at 75% it stops at approval.
The human may reclaim agent/approval work or cancel any nonterminal item.
Reassignment restarts progress but preserves earlier evidence. Completed and
cancelled items cannot be advanced, reopened or approved.

Rails authenticates and scopes both reads and commands to the item's owner.
Each mutation holds a database lock, compares the expected version and writes
state plus an ordered evidence receipt in one transaction. A UUID command
receipt makes retries idempotent; reuse for a different action is rejected.
Stale commands return 409. Cancelled work rejects late agent steps. The
deterministic agent label describes simulated provenance, not an autonomous
principal authorized to approve its own output.

## Transport and host integration

Native CSRF-protected forms work without JavaScript. Cable carries only a
version invalidation hint on an owner-scoped stream. React never derives
approval or work state from live messages: it directs the reader to refresh
the durable Rails page. Disconnects, lost hints and reconnects cannot erase
state. A failed broadcast does not roll back saved evidence. No continuous
worker or production AI orchestration is claimed.

SQLite remains the existing Showcase topology; tables use portable relational
columns, foreign keys, unique command/sequence indexes and state/progress
constraints. Apply the migration before serving this page. Rollback removes
the synthetic work tables; retain required evidence before rollback. Production
snapshot, backup and restore procedures remain those of the host. Live provider
adoption would need a separately reviewed agent identity, policy, queue claim,
provider timeout, retention and retry contract—this laboratory is not that adapter.

## Proof

Service/request/channel tests cover ownership, bounded progress, human gates,
idempotency, stale actions, cancellation and unavailable Cable. Component tests
cover stale hints, reconnect/degradation and disposal. Chromium exercises the
complete workflow with JavaScript enabled and disabled, evidence retention,
reload and narrow dark presentation. Screenshots are synthetic fixtures only.

Reviewed screenshot SHA-256 receipts:

- `work-handoff-approval.png`: `3ad428032bc8fcfe8085200177c8effaee645c3a793eb61b44d2f2588061cd41`
- `work-handoff-narrow-dark.png`: `acc1f875e973d53430578cd5da624c88eeff82eca08835ecb402d144ff1fa52f`

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
