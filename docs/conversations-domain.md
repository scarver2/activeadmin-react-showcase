<!-- docs/conversations-domain.md -->

# Conversations Domain Foundation

Issue #137 promotes the earlier synthetic Operator Chat records into neutral,
durable conversation primitives without deleting their history.

## Authority boundary

- `Conversation` owns stable public identity, title/topic, membership and the
  canonical last-activity timestamp used for inbox ordering.
- `ConversationMembership` is the authorization and read-state boundary. New
  authenticated memberships must link to `AdminUser`. Only rows backfilled from
  the synthetic precursor (and its narrow compatibility seed path) carry the
  explicit `legacy_identity` marker and may remain unlinked. A database check
  prevents ambiguous unauthenticated memberships.
- `Message` owns a stable public identity, bounded plain-text body, server
  timestamps and a unique positive sequence within its conversation.
- A membership's read cursor can only advance through messages in the same
  conversation. Replayed older cursors cannot move it backward.
- `Conversations::CreateMessage` locks the conversation and allocates the next
  sequence from durable Rails state. Composite foreign keys enforce that both
  authors and read cursors belong to the same conversation.

## Rolling migration contract

This slice is an expand-only release. The physical `chat_rooms`,
`chat_participants` and `chat_messages` tables, their established columns and
their legacy model constants remain available while rolling application
processes overlap. The canonical models map onto those tables and add nullable
columns that an older process can safely omit. Existing message public IDs are
derived from preserved database IDs, and conversation activity is backfilled
from persisted message timestamps.

During the overlap window, a database default marks an old-process participant
insert as `legacy_identity`. SQLite `AFTER INSERT` triggers supply a missing
message public ID and advance room activity for old-process message writes. New
Rails code always writes UUID message IDs, authenticated membership authority
and activity inside the message transaction. Compatibility constants,
associations and the real `Message.author` reflection keep the accepted
Operator Chat implementation operational.

The later contract release may rename the physical tables/columns and tighten
the transitional nullable/default rules and room-name database constraint only
after the previous application image is retired and no old writer remains. The
canonical `Conversation` validation already applies the 120-character limit to
new-version writes without rejecting historical or overlapping old-version
writes. Before deploying this migration,
take a verified SQLite backup, configure a bounded `busy_timeout`, and schedule
the migration for a low-traffic window: application reads/writes are rolling
compatible, but SQLite still serializes the short schema-change lock.

The second delivery slice adds a useful server-rendered inbox and thread at
`/admin/conversations` while keeping the durable models authoritative. See
[Server-rendered conversations](conversations.md). React, Action Cable,
presence, typing, search, attachments, scheduling and workflow state remain
outside this slice.

## Durable message signals

The next additive domain slice supplies the durable primitives that later
presentation work can consume without becoming authoritative:

- A message may reply to one earlier or later persisted message in the same
  conversation. The reference survives withdrawal, so quoted context resolves
  to the canonical `[withdrawn]` tombstone instead of disappearing.
- A conversation member may select exactly one of `like`, `dislike` or
  `question` for a message. Setting the current value again is a no-op, changing
  it updates the same row, and removing a missing value is a no-op.
- Mentions are structured records linked to the mentioned membership, not text
  parsed from a display name. Rails derives and snapshots the visible Unicode
  mention text from that membership. After commit, an authenticated recipient
  receives a Noticed projection whose event points back to the canonical
  message; the structured mention remains the domain truth.
- `Conversations::MessageSnapshot` is the bounded JSON-ready contract for later
  React work. It derives disposition counts and the viewer's current selection
  from durable rows, includes structured participant keys, and masks withdrawn
  bodies consistently.

Every mutation first proves that the acting membership and every referenced
record belong to the supplied conversation. Composite database foreign keys
repeat that boundary for replies, dispositions and mentions. The migration is
rolling-compatible: its only change to an established table is a nullable
reply reference, so the previous writer may continue creating ordinary
messages while new signal tables remain unused.

The domain objects intentionally own no delivery-provider behavior. The
separate notification integration projects a committed mention after commit,
uses Action Cable only as a best-effort enhancement, and adds no email or push
provider. The server-rendered thread remains useful without JavaScript or live
delivery.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
