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

The migration renames the precursor tables and foreign keys in place, derives
message public IDs from the preserved database IDs, and backfills conversation
activity from persisted message timestamps. Compatibility constants and
associations keep the accepted Operator Chat code operational while later
slices migrate callers to the canonical vocabulary.

This foundation deliberately contains no routes, controllers, React, Action
Cable, presence, typing, search, attachments, scheduling or workflow state.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
