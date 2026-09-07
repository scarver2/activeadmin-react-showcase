<!-- docs/kanban-workflow.md -->

# Kanban Workflow

The Kanban showcase models work as persisted `WorkflowItem` records. Its five
columns—backlog, ready, in progress, review, and done—are fixed workflow
vocabulary, not configurable records. No project, sprint, swimlane, role, or
assignee model is introduced.

## Authority boundary

React proposes an item identifier, target state, and bounded position. It may
render the proposal optimistically, but Rails authenticates the operator,
validates the fixed state and position bounds, transactionally resequences the
source and destination columns, and returns the canonical board. A rejected
request visibly restores the browser snapshot.

The page only reads persisted workflow state. `db:seed` provisions deterministic
demonstration items; there is no user-facing global reset control.

Without JavaScript, each persisted card remains readable and includes an
ordinary Rails form for moving it to a selected state and position.

## Verify

```bash
bin/test
bin/browser-test
```

The Chromium scenario signs into ActiveAdmin, drags a persisted card, observes
the canonical move, reloads the page, and proves the Rails-owned state survived.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
