<!-- docs/activity-center.md -->

# Activity Center

## Demo

The authenticated activity center presents deterministic account, operation, and schedule notifications. Operators can group and filter the bounded history, change unread state, follow local deep links, create a live event, and deliberately reconnect.

## Ruby

`ActivityCenter::Create` obtains the next owner-scoped sequence, persists the notification, and only then broadcasts its serialized envelope. Reads and mutations begin from `current_admin_user`; history and replay are capped at 100 rows.

## JavaScript

The React island owns transient filters and optimistic read feedback. Failed writes restore the prior canonical state. Sequence-keyed delivery deduplicates the HTTP response, broadcast, and replay after reconnect.

## Architecture

SQLite owns records and unread state. Solid Cable is a delivery accelerator, never the source of truth. Reconnect supplies the last applied sequence so persisted gaps replay in order. Deep links are restricted to local `/admin/` paths.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
