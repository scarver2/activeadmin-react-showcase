<!-- docs/conversations.md -->

# Conversation Workspace

Issue #137's second slice established the complete authenticated inbox and
thread workflow. The third slice progressively enhances that exact Rails
surface with a responsive React workspace while keeping Rails authoritative
and the accepted no-JavaScript interface intact.

## React enhancement

- Desktop uses a bounded split inbox/thread workspace; narrow screens use an
  explicit inbox-to-thread navigation flow with the composer always reachable.
- The island fetches canonical membership-authorized JSON from the existing
  inbox and explicit nested message routes. Every mutation retains CSRF and
  reconciles from Rails. Action Cable carries only versioned invalidation
  envelopes; React refetches the authorized Rails snapshot instead of trusting
  event content as durable state.
- Message history loads in 50-record pages, deduplicates by stable public ID,
  preserves chronological order, retains the scroll anchor, and cannot regress
  its earliest loaded cursor after a refresh.
- Unsent text is stored locally per authenticated membership and conversation,
  preventing one administrator from inheriting another administrator's draft
  in a shared browser profile; storage failures remain non-fatal. A successful
  send clears only the exact submitted draft, so typing during a pending
  request or navigating to another thread cannot lose newer text.
- Aborted, out-of-order, and cross-thread responses cannot overwrite a newer
  selection or leak stale errors. Navigation and disappearing history controls
  restore focus deliberately.
- React renders all message bodies as text. Rails continues to own membership,
  authorization, persistence, edit/withdraw rules, read state, route identity,
  and the canonical response.
- The React inbox submits search through the same canonical Rails GET endpoint
  as the no-JavaScript form. It does not depend on or patch Active Search.
- The composer optionally accepts one PNG, JPEG or plain-text attachment up to
  1 MB. React submits multipart form data to the same Rails creator and renders
  only canonical attachment metadata and guarded URLs returned by Rails.

## Realtime reconciliation

- `ConversationChannel` authorizes every subscription through the signed-in
  administrator's durable membership and rejects unknown or foreign public IDs.
- Envelopes contain only conversation identity, a monotonic durable version,
  latest message sequence and server timestamp. They never contain message
  bodies, private read cursors or membership data.
- Each successful create, edit, withdrawal, disposition or read-state mutation
  increments the conversation version in the same database transaction. The
  broadcast runs only after commit and failures are logged without changing the
  already durable result.
- Subscription and reconnect both request a snapshot. Duplicate, stale and
  out-of-order envelopes are ignored; newer versions trigger a bounded
  canonical refetch. Events arriving during that refetch are coalesced and
  reconciled again if Rails reports an older intermediate version.
- Multiple tabs and clients subscribe independently. When Cable is unavailable,
  all Rails forms and JSON mutations continue to work and manual refresh remains
  available.

## Ephemeral presence and typing

- `ConversationPresenceChannel` is separate from the durable invalidation
  channel and repeats the same signed-in membership authorization. Its client
  session token identifies one browser tab; it never grants access.
- A process-local, monitor-protected registry holds only membership identity,
  display name, last heartbeat and typing expiry. It never writes presence,
  typing or browser-session state to a model, the conversation version or
  Solid Cable storage.
- Online sessions expire after 45 seconds and typing expires after 5 seconds.
  The client sends a bounded 15-second heartbeat, clears typing after 3 seconds
  of inactivity, and removes its session on unsubscribe. Server expiry handles
  abrupt disconnects.
- Multiple tabs for one membership collapse into one online participant. A
  member remains online while any tab is live and remains typing while any tab
  has an active typing lease.
- Presence envelopes contain only the conversation public ID, online and typing
  display-name projections, and a server timestamp. They never include message
  bodies, read cursors, email addresses or durable conversation mutations.
- Disconnect or rejection degrades to the calm “Live activity unavailable”
  label. Messaging, drafts, manual refresh and the complete no-JavaScript
  workflow remain independent of presence delivery.

## Rails authority

- ActiveAdmin owns the inbox and thread routes, menu and layout.
- Every thread or mutation begins from the signed-in administrator's
  `ConversationMembership`; missing and unauthorized public IDs are both 404.
- The inbox is capped at 50 recent memberships and projects unread counts with
  one grouped Arel query without preloading message history.
- A thread fetches the newest 50 messages in descending SQL order, reverses
  them for chronological reading, and accepts only positive older cursors.
- Sending persists a plain-text message and advances the sender read cursor in
  one transaction with lock order conversation then membership.
- Authors may edit for 15 minutes. An unchanged normalized edit is a true
  no-op. Withdrawal replaces the persisted body with the fixed `[withdrawn]`
  tombstone and is idempotent for its author.
- Explicit POST/DELETE read-state forms move a same-conversation cursor;
  marking unread never advances it.
- Saved messages are private to the authenticated administrator's individual
membership. Save and remove are idempotent, recheck the membership/message
boundary on every mutation, and never notify participants or alter shared
message state. SQLite lock contention is retried within a small bound; the
membership/message uniqueness constraint collapses concurrent duplicate saves,
and either desired state can be safely replayed after an opposing concurrent
request.

## Saved-message policy

The no-JavaScript **Saved messages** view provides conversation context,
author, timestamp, a bounded excerpt and a canonical deep link back to the
message. It is rooted in the signed-in administrator's memberships, so another
member's saved state is never visible.

The list uses stable `(created_at, id)` cursor pagination rather than silently
truncating private state. Server-rendered Older/Newer links preserve the
newest-first order even when multiple saves share a timestamp, and all
membership, conversation, message and author context is preloaded.

The React workspace receives the same canonical per-message saved state and
Rails mutation URL. Its accessible Save/Remove control applies the canonical
JSON response and refreshes the selected thread, while the server-rendered
forms remain the complete no-JavaScript path. Failed mutations are retryable;
navigation guards prevent a late response from changing another thread.

Saved rows contain only relational identity and timestamps; they never copy
message bodies. A withdrawal therefore renders only the durable `[withdrawn]`
tombstone. If a message or membership is physically deleted in a future
retention workflow, its database-backed saved row is deleted with it, leaving
no private content copy behind. Saving is presentation state, not a delivery,
notification or shared-message mutation.

| Desktop light, 1440px | Narrow dark, 390px |
|---|---|
| ![Private saved-message list with conversation, author, timestamp, excerpt and deep-link context](screenshots/saved-messages-1440-light.png) | ![Private saved-message list with withdrawn-content tombstone at narrow dark presentation](screenshots/saved-messages-390-dark.png) |
- Bounded search normalizes at most 100 characters and returns at most 50
  deterministic results across authorized conversation titles, topics, and
  visible message bodies. Every query starts from the signed-in
  administrator's memberships. Withdrawn message bodies never participate.
- Message matches link through a bounded history cursor to a stable public-ID
  anchor, including messages older than the newest thread page. The endpoint
  offers equivalent HTML and canonical JSON representations behind a
  replaceable Rails service boundary.

All mutations use conventional forms, CSRF protection and POST-redirect-GET.
Message bodies are escaped plain text, including multiline and emoji content.
The seeded browser proof runs with JavaScript disabled.

## Attachment boundary

- Rails detects file content with Marcel, derives a safe filename and canonical
  extension, and rejects oversized or unapproved content before persistence.
- Message, attachment metadata, blob metadata and the sender read cursor commit
  as one workflow. A rejected upload or later transaction failure leaves no
  phantom message, attachment row, blob row or uploaded object.
- Downloads and image previews use a conversation-membership-authorized route.
  The serializer never exposes a generic Active Storage signed URL. Active
  Storage's permanent blob, proxy and representation resolvers also exclude
  every blob attached through `MessageAttachment`, so a leaked or constructed
  signed capability fails closed while unrelated Showcase assets retain their
  established behavior.
- Responses set `nosniff` and a restrictive sandbox policy. PNG and JPEG may be
  displayed inline; plain text is always downloaded. Withdrawn tombstones hide
  their attachment from both JSON/HTML presentation and the guarded route.

## Browser evidence

The committed Chromium captures cover both layers: the authenticated React
workspace in desktop light and narrow dark presentation, plus the unchanged
server-rendered workflow with JavaScript disabled.

| Desktop light, 1440px | Narrow dark, 390px |
|---|---|
| ![Server-rendered Conversations thread without JavaScript at desktop width in light mode](screenshots/conversations-no-js-1440-light.png) | ![Server-rendered Conversations thread without JavaScript at narrow width in dark mode](screenshots/conversations-no-js-390-dark.png) |

| React workspace · desktop light, 1440px | React workspace · narrow dark, 390px |
|---|---|
| ![React Conversation Workspace at desktop width in light mode](screenshots/conversation-workspace-1440-light.png) | ![React Conversation Workspace at narrow width in dark mode](screenshots/conversation-workspace-390-dark.png) |

| No-JavaScript search · desktop light, 1440px | No-JavaScript search · narrow dark, 390px |
|---|---|
| ![Authorized conversation search results at desktop width in light mode](screenshots/conversation-search-1440-light.png) | ![Authorized conversation search results at narrow width in dark mode](screenshots/conversation-search-390-dark.png) |

| Attachment workflow · desktop light, 1440px | Attachment workflow · narrow dark, 390px |
|---|---|
| ![Conversation attachment metadata at desktop width in light mode](screenshots/conversation-attachments-1440-light.png) | ![Conversation attachment metadata at narrow width in dark mode](screenshots/conversation-attachments-390-dark.png) |

| Ephemeral presence · desktop light, 1440px | Ephemeral presence · narrow dark, 390px |
|---|---|
| ![Conversation presence status at desktop width in light mode](screenshots/conversation-presence-1440-light.png) | ![Conversation presence status at narrow width in dark mode](screenshots/conversation-presence-390-dark.png) |

Regenerate these captures with
`SHOWCASE_CONVERSATIONS_ENABLED=true CAPTURE_SHOWCASE_SCREENSHOTS=1 CI=1 PLAYWRIGHT_PORT=3247 mise exec -- npx playwright test test/browser/conversations_no_js.spec.ts test/browser/conversation_workspace.spec.ts test/browser/conversation_search.spec.ts test/browser/conversation_presence.spec.ts`.

## Legacy isolation

The earlier Operator Chat remains available at its original route and retains
its React/Cable behavior. Its controller, channel, post and reset services are
hard-pinned to `support-operations`; they reject every general conversation ID
so the compatibility surface cannot inject, stream or delete durable inbox
history.

Production defaults this capability off unless
`SHOWCASE_CONVERSATIONS_ENABLED=true`. Rollout is deliberately two-phase:

1. deploy the legacy hard-pin and nullable columns while the flag remains off;
2. retire every previous application process;
3. set the flag to the exact lowercase value `true`, restart every new
   application process so the boot-time routes and ActiveAdmin resource are
   registered, and only then run the conversation seed after no unrestricted
   old controller or channel can reach the shared tables.

Kamal passes this non-secret flag through `config/deploy.yml` and defaults it
to `false`. The second-phase deployment must export the exact lowercase value
`true`; a typo, `1`, or `yes` remains disabled.

This gate is not optional during the compatibility release. Development and
test default on so the full server-rendered contract remains executable.
It is a rollout and UI activation gate, not authorization or a global domain
kill switch: it guards the seed, menu, routes and HTTP entrypoints. Foundational
services remain callable because the legacy Operator Chat uses the shared
message creator; trusted console and service calls remain an operator
responsibility. Membership authorization still governs every enabled HTTP
request.

## Deferred capabilities

External notifications and interactive reply/mention/disposition controls
remain deliberately deferred to later stacked #137 slices.

## Scheduled delivery

The additive scheduling slice keeps “Send later” under Rails authority on a
dedicated scheduled-message management page linked from both the canonical
React thread header and its substantive no-JavaScript fallback. A
signed-in member may save a bounded plain-text message for a future instant,
then privately view, edit, reschedule or cancel their own pending work. Failed
work remains private and diagnosable, and may be edited to enqueue a fresh
attempt. Delivered and cancelled records are immutable.

The browser accepts a local `datetime-local` value in the configured Rails
time zone; Active Record persists one canonical UTC instant. A delayed Active
Job re-resolves the author's authenticated membership at execution time. If
membership was removed, delivery fails closed without creating a message.
Delivery locks the schedule, assigns a durable unique message identity and
commits the ordinary `Message` plus delivered state together, so duplicate or
retried jobs create at most one ordinary message. Cancellation and a future
reschedule make stale queued jobs harmless.

The seed includes one future pending item and one recently delivered example.
Scheduling does not add Action Cable, external notifications or workflow
semantics; those remain separate acceptance slices.

| Desktop light, 1440px | Narrow dark, 390px |
|---|---|
| ![No-JavaScript scheduled messages at desktop width in light mode](screenshots/conversations-scheduled-1440-light.png) | ![No-JavaScript scheduled messages at narrow width in dark mode](screenshots/conversations-scheduled-390-dark.png) |

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
