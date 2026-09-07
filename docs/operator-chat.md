<!-- docs/operator-chat.md -->

# Operator Chat

The Operator Chat page is a resettable, synthetic support handoff. It proves a
product-shaped collaboration interface without importing real people, customer
data, or a speculative chat API into `activeadmin-react`.

## Boundary

- Rails authenticates every HTTP command and Cable connection.
- `ChatParticipant` persists three safe synthetic identities per room, and
  `ChatMessage` belongs to one of them through a database foreign key.
- `ChatMessage` persists a bounded body and monotonic room sequence; participant
  deletion is restricted while authored messages exist.
- The server always selects `You` for browser-created messages; submitted author
  fields are ignored.
- `OperatorChat::Reset` restores the same two safe fixture messages.
- Solid Cable transports committed envelopes and replays at most 100 messages
  after a validated sequence cursor.
- React renders the conversation, submits CSRF-protected commands, and rejects
  duplicate or stale sequences locally.

Without JavaScript, ActiveAdmin still renders the conversation and ordinary
Rails forms for send and reset. The interactive page adds explicit loading,
error, disconnected, reconnect, and empty states plus Ruby, JavaScript, and
architecture guidance.

## Verify

```bash
bin/test
bin/browser-test
```

The browser scenario signs into the real ActiveAdmin host, sends and persists a
message, reconnects the real Cable consumer without duplication, reloads the
page, and resets the synthetic fixture. SQLite and Solid Cable are sufficient;
PostgreSQL and Redis are not involved.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
