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

This foundation deliberately contains no routes, controllers, React, Action
Cable, presence, typing, search, attachments, scheduling or workflow state.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
