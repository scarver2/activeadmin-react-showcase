// app/frontend/components/ConversationWorkspace.tsx

import { createConsumer } from "@rails/actioncable"
import { FormEvent, Fragment, KeyboardEvent, ReactNode, useEffect, useRef, useState } from "react"

import ThemeIcon from "./ThemeIcon"
import useConversationPresence, { type ConversationPresenceConfig } from "./useConversationPresence"

export type ConversationSummary = {
  lastActivityAt: string
  memberCount: number
  messagesUrl: string
  publicId: string
  showUrl: string
  title: string
  topic: string | null
  unreadCount: number
}

export type ConversationMessage = {
  attachment: {
    byteSize: number
    contentType: string
    filename: string
    inline: boolean
    url: string
  } | null
  authorName: string
  body: string
  createdAt: string
  deepLinkUrl: string
  dispositions: {
    counts: Record<DispositionKind, number>
    mine: DispositionKind | null
  }
  dispositionUrl: string
  editable: boolean
  edited: boolean
  editUrl: string
  markReadUrl: string
  markUnreadUrl: string
  own: boolean
  publicId: string
  mentions: ConversationMention[]
  replyTo: ConversationReply | null
  saved: boolean
  savedUrl: string
  sequence: number
  withdrawUrl: string
  withdrawn: boolean
}

export type ConversationMention = {
  memberKey: string
  text: string
}

export type ConversationParticipant = {
  current: boolean
  displayName: string
  key: string
}

export type ConversationReply = {
  authorName: string
  body: string
  publicId: string
  withdrawn: boolean
}

export type ConversationThread = {
  createUrl: string
  displayName: string
  draftNamespace: string
  messages: ConversationMessage[]
  messagesUrl: string
  olderCursor: number | null
  participants: ConversationParticipant[]
  publicId: string
  presence?: ConversationPresenceConfig
  scheduledMessagesUrl: string
  realtime: ConversationRealtime
  showUrl: string
  title: string
  topic: string | null
  unreadCount: number
}

export type ConversationRealtime = {
  channel: string
  latestSequence: number
  serverAt: string
  version: number
}

type ConversationRealtimeEnvelope = Omit<ConversationRealtime, "channel"> & {
  conversationPublicId: string
  kind: string
}

export type ConversationWorkspaceProps = {
  inbox: ConversationSummary[]
  inboxUrl: string
  savedMessagesUrl: string
  searchUrl: string
  selected: ConversationThread | null
}

type WorkspacePayload = ConversationWorkspaceProps
type RequestOptions = { body?: BodyInit; method?: string }
type MutationResult = { active: boolean; succeeded: boolean }
type MutationPayload = { message?: ConversationMessage; ok: boolean }
type NewMessages = { count: number; startId: string } | null
type SendSubmission = {
  attachment: File | null
  body: string
  conversationId: string
  mentionKeys: string[]
  namespace: string
  publicId: string
  replyToPublicId: string | null
}
type DispositionKind = "dislike" | "like" | "question"

const dispositionOptions: { emoji: string, kind: DispositionKind, label: string }[] = [
  { emoji: "👍", kind: "like", label: "Like" },
  { emoji: "👎", kind: "dislike", label: "Dislike" },
  { emoji: "❓", kind: "question", label: "Question" }
]

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

function draftKey(namespace: string, publicId: string) {
  return `showcase:conversation-draft:${namespace}:${publicId}`
}

function readDraft(namespace: string, publicId: string) {
  try {
    const value = window.localStorage.getItem(draftKey(namespace, publicId))
    return typeof value === "string" ? value : ""
  } catch {
    return ""
  }
}

function storeDraft(namespace: string, publicId: string, value: string) {
  try {
    if (value) window.localStorage.setItem(draftKey(namespace, publicId), value)
    else window.localStorage.removeItem(draftKey(namespace, publicId))
  } catch {
    // A disabled or full storage area must never block durable messaging.
  }
}

function chronologicalUnique(messages: ConversationMessage[]) {
  return [...new Map(messages.map(message => [message.publicId, message])).values()]
    .sort((left, right) => left.sequence - right.sequence)
}

function exactTime(value: string) {
  return new Intl.DateTimeFormat(undefined, { dateStyle: "full", timeStyle: "long" }).format(new Date(value))
}

function renderMessageBody(message: ConversationMessage): ReactNode[] | string {
  if (message.mentions.length === 0) return message.body

  const mentionByText = new Map(message.mentions.map(mention => [mention.text, mention]))
  const escaped = [...mentionByText.keys()]
    .sort((left, right) => right.length - left.length)
    .map(text => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
  const parts = message.body.split(new RegExp(`(${escaped.join("|")})`, "gu"))
  return parts.map((part, index) => {
    const mention = mentionByText.get(part)
    return mention ? <mark className="conversation-mention" data-member-key={mention.memberKey} key={`${mention.memberKey}-${index}`}>{part}</mark> : part
  })
}

async function requestJson(url: string, options: RequestOptions = {}, signal?: AbortSignal) {
  const response = await fetch(url, {
    body: options.body,
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
      ...(typeof options.body === "string" ? { "Content-Type": "application/json" } : {}),
      ...(options.method && options.method !== "GET" ? { "X-CSRF-Token": csrfToken() } : {})
    },
    method: options.method || "GET",
    signal
  })
  const payload = await response.json().catch(() => ({ error: "The server returned an unreadable response." }))
  if (!response.ok) throw new Error(payload.error || "The conversation request failed.")
  return payload
}

export default function ConversationWorkspace({ inbox: initialInbox, inboxUrl, savedMessagesUrl, searchUrl, selected: initialSelected }: ConversationWorkspaceProps) {
  const [inbox, setInbox] = useState(initialInbox)
  const [selected, setSelected] = useState(initialSelected)
  const [draft, setDraft] = useState(() => initialSelected ? readDraft(initialSelected.draftNamespace, initialSelected.publicId) : "")
  const [attachment, setAttachment] = useState<File | null>(null)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editingBody, setEditingBody] = useState("")
  const [mentionIndex, setMentionIndex] = useState(0)
  const [mentionQuery, setMentionQuery] = useState<string | null>(null)
  const [replyingTo, setReplyingTo] = useState<ConversationMessage | null>(null)
  const [busy, setBusy] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const [newMessages, setNewMessages] = useState<NewMessages>(null)
  const [realtimeStatus, setRealtimeStatus] = useState<"connecting" | "live" | "unavailable">("connecting")
  const cableConsumer = useRef<ReturnType<typeof createConsumer> | null>(null)
  if (!cableConsumer.current) cableConsumer.current = createConsumer()
  const cableSubscription = useRef<{ perform(action: string, data?: object): boolean, unsubscribe(): void } | null>(null)
  const draftRef = useRef(draft)
  const attachmentInput = useRef<HTMLInputElement | null>(null)
  const composerInput = useRef<HTMLTextAreaElement | null>(null)
  const inboxHeading = useRef<HTMLHeadingElement | null>(null)
  const navigationController = useRef<AbortController | null>(null)
  const navigationVersion = useRef(0)
  const pendingFocus = useRef<"inbox" | "thread" | null>(null)
  const selectedRef = useRef(initialSelected)
  const retry = useRef<(() => void) | null>(null)
  const messageViewport = useRef<HTMLOListElement | null>(null)
  const newestMessage = useRef<HTMLLIElement | null>(null)
  const pendingRealtimeVersion = useRef(initialSelected?.realtime.version || 0)
  const realtimeReconciliation = useRef<string | null>(null)
  const realtimeRevision = useRef(initialSelected?.realtime.version || 0)
  const threadHeading = useRef<HTMLHeadingElement | null>(null)
  const presence = useConversationPresence(
    cableConsumer.current!,
    selected?.publicId,
    selected?.presence
  )

  useEffect(() => {
    function onPopState() {
      const entry = inbox.find(item => item.showUrl === window.location.pathname)
      void loadWorkspace(entry?.messagesUrl || inboxUrl, false)
    }
    window.addEventListener("popstate", onPopState)
    return () => window.removeEventListener("popstate", onPopState)
  }, [inbox, inboxUrl])

  useEffect(() => {
    selectedRef.current = selected
  }, [selected])

  useEffect(() => {
    if (realtimeStatus !== "connecting") return

    const timeout = window.setTimeout(() => setRealtimeStatus("unavailable"), 5_000)
    return () => window.clearTimeout(timeout)
  }, [realtimeStatus, selected?.publicId])

  useEffect(() => {
    const current = selectedRef.current
    if (!current) return

    const expectedId = current.publicId
    const subscription = cableConsumer.current!.subscriptions.create(
      { channel: current.realtime.channel, conversation_public_id: expectedId },
      {
        connected() {
          if (selectedRef.current?.publicId === expectedId) setRealtimeStatus("live")
          subscription.perform("reconcile")
        },
        disconnected() {
          if (selectedRef.current?.publicId === expectedId) setRealtimeStatus("unavailable")
        },
        received(envelope: ConversationRealtimeEnvelope) { receiveRealtime(envelope, expectedId) },
        rejected() {
          if (selectedRef.current?.publicId === expectedId) {
            setRealtimeStatus("unavailable")
            setError("Live updates were not authorized. Manual refresh remains available.")
          }
        }
      }
    )
    cableSubscription.current = subscription
    return () => {
      subscription.unsubscribe()
      /* v8 ignore next -- only the currently owned subscription can execute this cleanup. */
      if (cableSubscription.current === subscription) cableSubscription.current = null
    }
  }, [selected?.publicId])

  useEffect(() => () => cableConsumer.current?.disconnect(), [])

  useEffect(() => {
    const storedDraft = selected ? readDraft(selected.draftNamespace, selected.publicId) : ""
    draftRef.current = storedDraft
    setDraft(storedDraft)
    setAttachment(null)
    if (attachmentInput.current) attachmentInput.current.value = ""
    setEditingId(null)
    setMentionIndex(0)
    setMentionQuery(null)
    setReplyingTo(null)
    setNewMessages(null)
    setRealtimeStatus("connecting")
    realtimeRevision.current = selected?.realtime.version || 0
    pendingRealtimeVersion.current = selected?.realtime.version || 0
    window.requestAnimationFrame(() => {
      if (messageViewport.current) messageViewport.current.scrollTop = messageViewport.current.scrollHeight
      if (pendingFocus.current === "thread") threadHeading.current?.focus()
      if (pendingFocus.current === "inbox") inboxHeading.current?.focus()
      pendingFocus.current = null
    })
  }, [selected?.draftNamespace, selected?.publicId])

  const mentionSuggestions = selected && mentionQuery !== null ? selected.participants.filter(participant =>
    participant.displayName.toLocaleLowerCase().includes(mentionQuery.toLocaleLowerCase())
  ) : []

  useEffect(() => {
    const targetId = window.location.hash.slice(1)
    if (!targetId.startsWith("message-")) return

    window.requestAnimationFrame(() => document.getElementById(targetId)?.scrollIntoView?.({ block: "center" }))
  }, [selected?.messages.length, selected?.publicId])

  function validRealtimeEnvelope(envelope: ConversationRealtimeEnvelope, expectedId: string) {
    return envelope?.conversationPublicId === expectedId &&
      Number.isInteger(envelope.version) && envelope.version >= 0 &&
      Number.isInteger(envelope.latestSequence) && envelope.latestSequence >= 0 &&
      typeof envelope.kind === "string" &&
      typeof envelope.serverAt === "string" && !Number.isNaN(Date.parse(envelope.serverAt))
  }

  function receiveRealtime(envelope: ConversationRealtimeEnvelope, expectedId: string) {
    if (!validRealtimeEnvelope(envelope, expectedId) || envelope.version <= realtimeRevision.current) return

    pendingRealtimeVersion.current = Math.max(pendingRealtimeVersion.current, envelope.version)
    void reconcileRealtime(expectedId)
  }

  async function reconcileRealtime(expectedId: string) {
    if (realtimeReconciliation.current === expectedId) return

    realtimeReconciliation.current = expectedId
    setError(null)
    retry.current = null
    const expectedNavigation = navigationVersion.current
    let failed = false
    try {
      for (let attempt = 0; attempt < 3; attempt += 1) {
        const current = selectedRef.current
        if (!current || current.publicId !== expectedId || navigationVersion.current !== expectedNavigation ||
            pendingRealtimeVersion.current <= realtimeRevision.current) return

        const payload = await requestJson(current.messagesUrl) as WorkspacePayload
        const fetched = payload.selected
        if (!fetched || fetched.publicId !== expectedId || selectedRef.current?.publicId !== expectedId ||
            navigationVersion.current !== expectedNavigation) return

        const viewport = messageViewport.current
        const wasNearNewest = !viewport || viewport.scrollHeight - viewport.scrollTop - viewport.clientHeight < 96
        const currentSelected = selectedRef.current
        const previousNewest = currentSelected.messages.at(-1)?.sequence || 0
        const receivedMessages = fetched.messages.filter(message => message.sequence > previousNewest)
        const received = receivedMessages.length
        const canonical = {
          ...fetched,
          messages: chronologicalUnique([...currentSelected.messages, ...fetched.messages]),
          olderCursor: currentSelected.olderCursor
        }
        realtimeRevision.current = Math.max(realtimeRevision.current, fetched.realtime.version)
        selectedRef.current = canonical
        setInbox(payload.inbox)
        setSelected(canonical)
        if (received > 0 && !wasNearNewest) {
          setNewMessages(current => current ? { ...current, count: current.count + received } : {
            count: received,
            startId: receivedMessages[0].publicId
          })
        }
        else if (received > 0) window.requestAnimationFrame(jumpToNewest)
      }
    } catch (requestError) {
      failed = true
      if (selectedRef.current?.publicId === expectedId && navigationVersion.current === expectedNavigation) {
        setError((requestError as Error).message)
        retry.current = () => void reconcileRealtime(expectedId)
      }
    } finally {
      if (realtimeReconciliation.current === expectedId) realtimeReconciliation.current = null
      if (!failed && selectedRef.current?.publicId === expectedId && pendingRealtimeVersion.current > realtimeRevision.current) {
        if (navigationVersion.current !== expectedNavigation) {
          void reconcileRealtime(expectedId)
        } else {
          setError("Live updates changed again before Rails returned the canonical snapshot. Refresh to reconcile.")
          retry.current = () => void refreshSelected(true)
        }
      }
    }
  }

  async function loadWorkspace(url: string, pushHistory: boolean, showUrl?: string) {
    navigationController.current?.abort()
    const controller = new AbortController()
    navigationController.current = controller
    const version = ++navigationVersion.current
    setLoading(true)
    setError(null)
    setNotice(null)
    retry.current = () => void loadWorkspace(url, pushHistory, showUrl)
    try {
      const payload = await requestJson(url, {}, controller.signal) as WorkspacePayload
      if (version !== navigationVersion.current) return
      setInbox(payload.inbox)
      selectedRef.current = payload.selected
      pendingFocus.current = payload.selected ? "thread" : "inbox"
      setSelected(payload.selected)
      if (pushHistory && showUrl) window.history.pushState({}, "", showUrl)
    } catch (requestError) {
      if ((requestError as Error).name !== "AbortError" && version === navigationVersion.current) {
        setError((requestError as Error).message)
      }
    } finally {
      if (version === navigationVersion.current) setLoading(false)
    }
  }

  async function refreshSelected(announceNew = false) {
    const selectedSnapshot = selectedRef.current
    /* v8 ignore next -- refresh controls and retries exist only while a thread is selected. */
    if (!selectedSnapshot) return
    const expectedId = selectedSnapshot.publicId
    const previousNewest = selectedSnapshot.messages.at(-1)?.sequence || 0
    const version = ++navigationVersion.current
    setError(null)
    retry.current = () => void refreshSelected(announceNew)
    try {
      const payload = await requestJson(selectedSnapshot.messagesUrl) as WorkspacePayload
      if (version !== navigationVersion.current || payload.selected?.publicId !== expectedId) return
      const fetched = payload.selected
      const receivedMessages = fetched.messages.filter(message => message.sequence > previousNewest)
      const received = receivedMessages.length
      const viewport = messageViewport.current
      const wasNearNewest = !viewport || viewport.scrollHeight - viewport.scrollTop - viewport.clientHeight < 96
      const canonical = {
        ...fetched,
        messages: chronologicalUnique([...selectedSnapshot.messages, ...fetched.messages]),
        olderCursor: selectedSnapshot.olderCursor
      }
      realtimeRevision.current = Math.max(realtimeRevision.current, fetched.realtime.version)
      setInbox(payload.inbox)
      selectedRef.current = canonical
      setSelected(canonical)
      if (announceNew && received > 0 && !wasNearNewest) {
        setNewMessages(current => current ? { ...current, count: current.count + received } : {
          count: received,
          startId: receivedMessages[0].publicId
        })
      }
      else if (received > 0) window.requestAnimationFrame(jumpToNewest)
      if (pendingRealtimeVersion.current > realtimeRevision.current) void reconcileRealtime(expectedId)
    } catch (requestError) {
      if ((requestError as Error).name !== "AbortError" && version === navigationVersion.current &&
          selectedRef.current?.publicId === expectedId) {
        setError((requestError as Error).message)
      }
    }
  }

  async function loadOlder() {
    const selectedSnapshot = selectedRef.current
    /* v8 ignore next -- the history control and its retry exist only with a non-null cursor. */
    if (!selectedSnapshot?.olderCursor) return
    const expectedId = selectedSnapshot.publicId
    const expectedNavigation = navigationVersion.current
    const viewport = messageViewport.current
    const previousHeight = viewport?.scrollHeight || 0
    setBusy(true)
    setError(null)
    retry.current = () => void loadOlder()
    try {
      const separator = selectedSnapshot.messagesUrl.includes("?") ? "&" : "?"
      const payload = await requestJson(`${selectedSnapshot.messagesUrl}${separator}before=${selectedSnapshot.olderCursor}`) as WorkspacePayload
      if (payload.selected?.publicId !== expectedId || navigationVersion.current !== expectedNavigation) return
      /* v8 ignore next -- the response guard above excludes a mismatched concurrent updater. */
      setSelected(current => current && current.publicId === expectedId ? {
        ...current,
        messages: chronologicalUnique([...payload.selected!.messages, ...current.messages]),
        olderCursor: payload.selected!.olderCursor
      } : current)
      window.requestAnimationFrame(() => {
        /* v8 ignore next -- the mounted history control always has its message viewport ref. */
        if (viewport) {
          viewport.scrollTop += viewport.scrollHeight - previousHeight
          if (!payload.selected?.olderCursor) viewport.focus({ preventScroll: true })
        }
      })
    } catch (requestError) {
      if ((requestError as Error).name !== "AbortError" && navigationVersion.current === expectedNavigation &&
          selectedRef.current?.publicId === expectedId) {
        setError((requestError as Error).message)
      }
    } finally {
      setBusy(false)
    }
  }

  async function mutate(url: string, options: RequestOptions, success: string, retryAction?: () => void): Promise<MutationResult> {
    const expectedId = selectedRef.current?.publicId
    const expectedNavigation = navigationVersion.current
    setBusy(true)
    setError(null)
    setNotice(null)
    retry.current = retryAction || null
    try {
      const payload = await requestJson(url, options) as MutationPayload
      const active = Boolean(expectedId) && selectedRef.current?.publicId === expectedId &&
        navigationVersion.current === expectedNavigation
      if (!active) return { active: false, succeeded: true }
      if (payload.message) {
        const canonicalMessage = payload.message
        const current = selectedRef.current
        /* v8 ignore next -- active navigation/id checks exclude a mismatched concurrent updater. */
        if (!current || current.publicId !== expectedId) return { active: false, succeeded: true }
        const canonical = {
          ...current,
          messages: chronologicalUnique([
            ...current.messages.filter(message => message.publicId !== canonicalMessage.publicId),
            canonicalMessage
          ])
        }
        selectedRef.current = canonical
        setSelected(canonical)
      }
      setNotice(success)
      await refreshSelected()
      return { active: true, succeeded: true }
    } catch (requestError) {
      const active = selectedRef.current?.publicId === expectedId && navigationVersion.current === expectedNavigation
      if (active) setError((requestError as Error).message)
      return { active, succeeded: false }
    } finally {
      setBusy(false)
    }
  }

  async function sendMessage(event: FormEvent) {
    event.preventDefault()
    if (!selected || !draft.trim()) return
    const submission: SendSubmission = {
      attachment,
      body: draft,
      conversationId: selected.publicId,
      mentionKeys: selected.participants
        .filter(participant => draft.includes(`@${participant.displayName}`))
        .map(participant => participant.key),
      namespace: selected.draftNamespace,
      publicId: crypto.randomUUID(),
      replyToPublicId: replyingTo?.publicId || null
    }
    await submitMessage(submission)
  }

  async function submitMessage(submission: SendSubmission) {
    const formData = new FormData()
    formData.append("message[body]", submission.body)
    formData.append("message[public_id]", submission.publicId)
    if (submission.replyToPublicId) formData.append("message[reply_to_public_id]", submission.replyToPublicId)
    submission.mentionKeys.forEach(key => formData.append("message[mentioned_member_keys][]", key))
    if (submission.attachment) formData.append("message[attachment]", submission.attachment)
    /* v8 ignore next -- retry controls are replaced whenever the selected conversation changes. */
    const createUrl = selectedRef.current?.publicId === submission.conversationId ? selectedRef.current.createUrl : ""
    /* v8 ignore next -- a mounted retry/send control always owns its matching conversation URL. */
    if (!createUrl) return

    presence.setTyping(false)
    const result = await mutate(createUrl, {
      body: formData,
      method: "POST"
    }, "Message sent.", () => void submitMessage(submission))
    if (result.succeeded) {
      const unchanged = readDraft(submission.namespace, submission.conversationId) === submission.body
      if (unchanged) storeDraft(submission.namespace, submission.conversationId, "")
      if (unchanged && result.active && selectedRef.current?.publicId === submission.conversationId && draftRef.current === submission.body) {
        setDraft("")
        draftRef.current = ""
        setAttachment(null)
        setReplyingTo(null)
        setMentionQuery(null)
        attachmentInput.current!.value = ""
        window.requestAnimationFrame(jumpToNewest)
      }
    }
  }

  async function saveEdit(message: ConversationMessage) {
    const result = await mutate(message.editUrl, {
      body: JSON.stringify({ message: { body: editingBody } }),
      method: "PATCH"
    }, "Message updated.")
    if (result.active && result.succeeded) setEditingId(null)
  }

  async function toggleSaved(message: ConversationMessage) {
    await mutate(
      message.savedUrl,
      { method: message.saved ? "DELETE" : "POST" },
      message.saved ? "Message removed from saved messages." : "Message saved.",
      () => void toggleSaved(message)
    )
  }

  async function toggleDisposition(message: ConversationMessage, kind: DispositionKind, label: string) {
    const selected = message.dispositions.mine === kind
    await mutate(
      message.dispositionUrl,
      selected ? { method: "DELETE" } : {
        body: JSON.stringify({ disposition: { kind } }),
        method: "POST"
      },
      selected ? "Disposition removed." : `${label} disposition selected.`,
      () => void toggleDisposition(message, kind, label)
    )
  }

  function jumpToNewest() {
    newestMessage.current?.scrollIntoView({ behavior: "smooth", block: "nearest" })
    setNewMessages(null)
  }

  function updateDraft(value: string) {
    setDraft(value)
    draftRef.current = value
    /* v8 ignore next -- the composer is rendered only while a thread is selected. */
    if (selected) storeDraft(selected.draftNamespace, selected.publicId, value)
    presence.setTyping(Boolean(value.trim()))
  }

  function updateMentionQuery(value: string, caret: number | null) {
    /* v8 ignore next -- textarea selectionStart is numeric in supported browsers. */
    const beforeCaret = value.slice(0, caret ?? value.length)
    const match = beforeCaret.match(/(?:^|\s)@([^@\n]*)$/u)
    let query: string | null = null
    if (match) query = match[1]
    setMentionQuery(query)
    setMentionIndex(0)
  }

  function chooseMention(participant: ConversationParticipant) {
    const input = composerInput.current
    /* v8 ignore next -- suggestions are rendered only beside the mounted composer input. */
    if (!input) return

    /* v8 ignore next -- textarea selectionStart is numeric in supported browsers. */
    const caret = input.selectionStart ?? draft.length
    const beforeCaret = draft.slice(0, caret)
    const mentionStart = beforeCaret.lastIndexOf("@")
    /* v8 ignore next -- a suggestion exists only while updateMentionQuery found an @ token. */
    if (mentionStart < 0) return

    const value = `${draft.slice(0, mentionStart)}@${participant.displayName} ${draft.slice(caret)}`
    updateDraft(value)
    setMentionQuery(null)
    window.requestAnimationFrame(() => {
      const nextCaret = mentionStart + participant.displayName.length + 2
      input.focus()
      input.setSelectionRange(nextCaret, nextCaret)
    })
  }

  function handleComposerKeyDown(event: KeyboardEvent<HTMLTextAreaElement>) {
    if (mentionQuery === null || mentionSuggestions.length === 0) return

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const direction = event.key === "ArrowDown" ? 1 : -1
      setMentionIndex(current => (current + direction + mentionSuggestions.length) % mentionSuggestions.length)
    } else if (event.key === "Enter") {
      event.preventDefault()
      chooseMention(mentionSuggestions[mentionIndex])
    } else if (event.key === "Escape") {
      event.preventDefault()
      setMentionQuery(null)
    }
  }

  async function copyMessageLink(message: ConversationMessage) {
    try {
      await navigator.clipboard.writeText(new URL(message.deepLinkUrl, window.location.origin).toString())
      setError(null)
      setNotice("Message link copied.")
    } catch {
      setNotice(null)
      setError("The message link could not be copied. Open the message link and copy it from the address bar.")
    }
  }

  const otherTyping = presence.typing.filter(name => name !== selected?.displayName)

  return <section className={`conversation-workspace${selected ? " has-selection" : ""}`} aria-label="Conversation workspace">
    <aside className="conversation-inbox" aria-label="Conversation inbox">
      <header>
        <span className="conversation-icon"><ThemeIcon name="people" /></span>
        <div><p>Collaboration</p><h2 ref={inboxHeading} tabIndex={-1}>Conversations</h2></div>
      </header>
      <a className="conversation-saved-link" href={savedMessagesUrl}>Saved messages</a>
      <form action={searchUrl} className="conversation-search" method="get">
        <label htmlFor="conversation-search-query">Search conversations</label>
        <div>
          <input id="conversation-search-query" maxLength={100} name="q" required type="search" />
          <button type="submit">Search</button>
        </div>
      </form>
      {inbox.length === 0 ? <p className="conversation-empty" role="status">You do not belong to any conversations yet.</p> :
        <ol>{inbox.map(item => <li key={item.publicId}>
          <a
            aria-current={selected?.publicId === item.publicId ? "page" : undefined}
            href={item.showUrl}
            onClick={event => {
              if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
              event.preventDefault()
              void loadWorkspace(item.messagesUrl, true, item.showUrl)
            }}
          >
            <span className="conversation-inbox-title">{item.title}</span>
            {item.unreadCount > 0 && <span className="conversation-unread">{item.unreadCount}<span className="sr-only"> unread</span></span>}
            <span className="conversation-inbox-topic"><span>{item.topic || "No topic"}</span> · {item.memberCount} {item.memberCount === 1 ? "participant" : "participants"}</span>
            <time dateTime={item.lastActivityAt}>{new Date(item.lastActivityAt).toLocaleDateString()}</time>
          </a>
        </li>)}</ol>}
    </aside>

    <main className="conversation-thread" aria-busy={loading}>
      {loading && <p className="conversation-loading" role="status">Loading conversation…</p>}
      {!loading && !selected && <div className="conversation-thread-empty">
        <ThemeIcon name="people" />
        <h2>Choose a conversation</h2>
        <p>The workspace keeps durable Rails-owned messages close to their operating context.</p>
      </div>}
      {!loading && selected && <>
        <header className="conversation-thread-header">
          <button className="conversation-back" onClick={() => {
            void loadWorkspace(inboxUrl, true, inboxUrl.replace(/\.json$/, ""))
          }} type="button">← <span>Inbox</span></button>
          <div><p>{selected.topic || "Conversation"}</p><h2 ref={threadHeading} tabIndex={-1}>{selected.title}</h2>
            <details className="conversation-participants">
              <summary>{selected.participants.length} {selected.participants.length === 1 ? "participant" : "participants"}</summary>
              <ul aria-label="Conversation participants">{selected.participants.map(participant =>
                <li key={participant.key}>{participant.displayName}{participant.current ? " (you)" : ""}</li>
              )}</ul>
            </details>
          </div>
          <a className="conversation-scheduled-link" href={selected.scheduledMessagesUrl}>Scheduled messages</a>
          <button className="conversation-refresh" disabled={busy} onClick={() => void refreshSelected(true)} type="button">
            Refresh
          </button>
        </header>
        <div className="conversation-presence" aria-live="polite" role="status">
          <span data-testid="conversation-cable-status">
            {realtimeStatus === "live" ? "Messages live" : realtimeStatus === "connecting" ? "Connecting live messages…" : "Live messages unavailable · Rails messaging remains available"}
          </span>
          {presence.available ? <>
            <span>{presence.online.length} {presence.online.length === 1 ? "person" : "people"} online</span>
            {otherTyping.length > 0 && <span>{otherTyping.join(", ")} {otherTyping.length === 1 ? "is" : "are"} typing…</span>}
          </> : <span>Live activity unavailable</span>}
        </div>

        {selected.olderCursor && <button className="conversation-load-older" disabled={busy} onClick={() => void loadOlder()} type="button">
          Load 50 older messages
        </button>}
        <ol aria-label="Messages" className="conversation-message-list" ref={messageViewport} tabIndex={-1}>
          {selected.messages.length === 0 && <li className="conversation-empty" role="status">No messages yet. Start the conversation below.</li>}
          {selected.messages.map((message, index) => <Fragment key={message.publicId}>
            {newMessages?.startId === message.publicId && <li
              aria-label={`${newMessages.count} new ${newMessages.count === 1 ? "message" : "messages"}`}
              className="conversation-new-messages-divider"
              role="separator"
            >
              <span aria-hidden="true" />
              <button onClick={jumpToNewest} type="button">
                {newMessages.count} new {newMessages.count === 1 ? "message" : "messages"} · Jump to newest
              </button>
              <span aria-hidden="true" />
            </li>}
            <li
              className={message.own ? "is-own" : undefined}
              id={`message-${message.publicId}`}
              ref={index === selected.messages.length - 1 ? newestMessage : undefined}
            >
            <article>
              <header><strong>{message.authorName}</strong><time aria-label={`Sent ${exactTime(message.createdAt)}`} dateTime={message.createdAt} title={exactTime(message.createdAt)}>{new Date(message.createdAt).toLocaleString()}</time></header>
              {message.replyTo && <blockquote className="conversation-reply-quote">
                <a href={`#message-${message.replyTo.publicId}`}>Replying to {message.replyTo.authorName}</a>
                <p>{message.replyTo.body}</p>
              </blockquote>}
              {editingId === message.publicId ? <div className="conversation-inline-edit">
                <label htmlFor={`edit-${message.publicId}`}>Edit message</label>
                <textarea id={`edit-${message.publicId}`} maxLength={500} onChange={event => setEditingBody(event.target.value)} rows={4} value={editingBody} />
                <div><button disabled={busy || !editingBody.trim()} onClick={() => void saveEdit(message)} type="button">Save</button>
                  <button onClick={() => setEditingId(null)} type="button">Cancel</button></div>
              </div> : <p>{renderMessageBody(message)}</p>}
              {message.attachment && <div className="conversation-attachment">
                {message.attachment.inline && <a href={message.attachment.url}>
                  <img alt={`Attachment preview: ${message.attachment.filename}`} src={message.attachment.url} />
                </a>}
                <a href={message.attachment.url}>{message.attachment.filename}</a>
                <span>{Math.ceil(message.attachment.byteSize / 1024)} KB · {message.attachment.contentType}</span>
              </div>}
              <div className="conversation-dispositions" role="group" aria-label={`Dispositions for message by ${message.authorName}`}>
                {dispositionOptions.map(({ emoji, kind, label }) => {
                  const count = message.dispositions.counts[kind]
                  return <button
                    aria-label={`${label} message by ${message.authorName}, ${count} total`}
                    aria-pressed={message.dispositions.mine === kind}
                    className="conversation-disposition"
                    disabled={busy}
                    key={kind}
                    onClick={() => void toggleDisposition(message, kind, label)}
                    type="button"
                  >
                    <span aria-hidden="true">{emoji}</span>
                    <span>{label}</span>
                    <span aria-hidden="true">{count}</span>
                  </button>
                })}
              </div>
              <footer>
                {message.edited && <span>Edited</span>}
                <button disabled={busy} onClick={() => void mutate(message.markReadUrl, { method: "POST" }, "Read position updated.")} type="button">Mark read through here</button>
                <button disabled={busy} onClick={() => void mutate(message.markUnreadUrl, { method: "DELETE" }, "Unread position updated.")} type="button">Mark unread from here</button>
                <button
                  aria-pressed={message.saved}
                  disabled={busy}
                  onClick={() => void toggleSaved(message)}
                  type="button"
                >{message.saved ? "Remove from saved" : "Save message"}</button>
                <button disabled={busy} onClick={() => {
                  setReplyingTo(message)
                  window.requestAnimationFrame(() => composerInput.current?.focus())
                }} type="button">Reply</button>
                <button disabled={busy} onClick={() => void copyMessageLink(message)} type="button">Copy link</button>
                {message.editable && !message.withdrawn && <>
                  <button onClick={() => { setEditingId(message.publicId); setEditingBody(message.body) }} type="button">Edit</button>
                  <button className="conversation-danger" disabled={busy} onClick={() => {
                    if (window.confirm("Withdraw this message?")) void mutate(message.withdrawUrl, { method: "DELETE" }, "Message withdrawn.")
                  }} type="button">Withdraw</button>
                </>}
              </footer>
            </article>
          </li></Fragment>)}
        </ol>

        <form className="conversation-composer" onSubmit={event => void sendMessage(event)}>
          {replyingTo && <blockquote className="conversation-reply-quote conversation-composer-reply">
            <strong>Replying to {replyingTo.authorName}</strong>
            <p>{replyingTo.withdrawn ? "[withdrawn]" : replyingTo.body}</p>
            <button onClick={() => setReplyingTo(null)} type="button">Cancel reply</button>
          </blockquote>}
          <label htmlFor={`conversation-body-${selected.publicId}`}>Message as {selected.displayName}</label>
          <textarea
            aria-autocomplete="list"
            aria-controls={mentionSuggestions.length > 0 ? `conversation-mentions-${selected.publicId}` : undefined}
            aria-expanded={mentionSuggestions.length > 0}
            aria-activedescendant={mentionSuggestions.length > 0 ? `conversation-mention-${mentionSuggestions[mentionIndex].key}` : undefined}
            role="combobox"
            id={`conversation-body-${selected.publicId}`}
            maxLength={500}
            onChange={event => {
              updateDraft(event.target.value)
              updateMentionQuery(event.target.value, event.target.selectionStart)
            }}
            onKeyDown={handleComposerKeyDown}
            placeholder="Write a durable message…"
            ref={composerInput}
            required
            rows={4}
            value={draft}
          />
          {mentionSuggestions.length > 0 && <ul aria-label="Mention suggestions" className="conversation-mention-suggestions" id={`conversation-mentions-${selected.publicId}`} role="listbox">
            {mentionSuggestions.map((participant, index) => <li
              aria-selected={index === mentionIndex}
              id={`conversation-mention-${participant.key}`}
              key={participant.key}
              role="option"
            ><button onMouseDown={event => event.preventDefault()} onClick={() => chooseMention(participant)} type="button">{participant.displayName}{participant.current ? " (you)" : ""}</button></li>)}
          </ul>}
          <label htmlFor={`conversation-attachment-${selected.publicId}`}>Attachment (optional)</label>
          <input
            accept="image/jpeg,image/png,text/plain"
            id={`conversation-attachment-${selected.publicId}`}
            onChange={event => setAttachment(event.target.files?.[0] || null)}
            ref={attachmentInput}
            type="file"
          />
          <small>PNG, JPEG, or plain text; 1 MB maximum.</small>
          <div><span>{draft.length}/500 · Draft saved on this device</span>
            <button aria-label="Insert check mark emoji" onClick={() => updateDraft(`${draft}✅`)} type="button">✅</button>
            <button disabled={busy || !draft.trim()} type="submit">Send message</button></div>
        </form>
      </>}
      {notice && <p className="conversation-notice" role="status">{notice}</p>}
      {error && <div className="conversation-error" role="alert"><p>{error}</p>{retry.current && <button onClick={() => retry.current?.()} type="button">Retry</button>}</div>}
    </main>
  </section>
}
