// app/frontend/components/ConversationWorkspace.test.tsx

import { act, fireEvent, render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"

import ConversationWorkspace, {
  type ConversationMessage,
  type ConversationThread,
  type ConversationWorkspaceProps
} from "./ConversationWorkspace"

const cable = vi.hoisted(() => {
  const callbacks: Record<string, (...arguments_: unknown[]) => void>[] = []
  const subscriptions: { perform: ReturnType<typeof vi.fn>, unsubscribe: ReturnType<typeof vi.fn> }[] = []
  return {
    callbacks,
    connect: vi.fn(),
    disconnect: vi.fn(),
    subscriptions: {
      create: vi.fn((_identifier: Record<string, unknown>, handlers: Record<string, (...arguments_: unknown[]) => void>) => {
        callbacks.push(handlers)
        const subscription = { perform: vi.fn(() => true), unsubscribe: vi.fn() }
        subscriptions.push(subscription)
        return subscription
      })
    },
    created: subscriptions
  }
})

vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

function message(sequence: number, overrides: Partial<ConversationMessage> = {}): ConversationMessage {
  return {
    attachment: null,
    authorName: sequence % 2 ? "Release Lead" : "You",
    body: `Message ${sequence}`,
    createdAt: "2026-09-28T12:00:00Z",
    deepLinkUrl: `/admin/conversations/release-room#message-message-${sequence}`,
    dispositions: { counts: { dislike: 0, like: 0, question: 0 }, mine: null },
    dispositionUrl: `/admin/conversations/release-room/messages/message-${sequence}/disposition.json`,
    editable: sequence % 2 === 0,
    edited: false,
    editUrl: `/admin/conversations/release-room/messages/message-${sequence}.json`,
    markReadUrl: `/admin/conversations/release-room/read-state/message-${sequence}.json`,
    markUnreadUrl: `/admin/conversations/release-room/read-state/message-${sequence}.json`,
    own: sequence % 2 === 0,
    publicId: `message-${sequence}`,
    mentions: [],
    replyTo: null,
    saved: false,
    savedUrl: `/admin/conversations/release-room/messages/message-${sequence}/saved.json`,
    sequence,
    withdrawUrl: `/admin/conversations/release-room/messages/message-${sequence}.json`,
    withdrawn: false,
    ...overrides
  }
}

function thread(publicId = "release-room", overrides: Partial<ConversationThread> = {}): ConversationThread {
  return {
    createUrl: `/admin/conversations/${publicId}/messages.json`,
    displayName: "You",
    draftNamespace: `${publicId}-member`,
    messages: [message(1), message(2)],
    messagesUrl: `/admin/conversations/${publicId}/messages.json`,
    olderCursor: null,
    participants: [
      { current: false, displayName: "Release Lead", key: "release-lead" },
      { current: true, displayName: "You", key: "current-member" },
      { current: false, displayName: "Riley Chen", key: "riley-chen" }
    ],
    publicId,
    scheduledMessagesUrl: `/admin/conversations/${publicId}/scheduled_messages`,
    realtime: {
      channel: "ConversationChannel",
      latestSequence: 2,
      serverAt: "2026-09-28T12:00:00.000000Z",
      version: 0
    },
    showUrl: `/admin/conversations/${publicId}`,
    title: publicId === "release-room" ? "Release room" : "Design room",
    topic: "Coordinate the release",
    unreadCount: 1,
    ...overrides
  }
}

function props(selected: ConversationThread | null = thread()): ConversationWorkspaceProps {
  return {
    inbox: [
      { lastActivityAt: "2026-09-28T12:00:00Z", memberCount: 3, messagesUrl: "/admin/conversations/release-room/messages.json", publicId: "release-room", showUrl: "/admin/conversations/release-room", title: "Release room", topic: "Coordinate the release", unreadCount: 1 },
      { lastActivityAt: "2026-09-28T11:00:00Z", memberCount: 2, messagesUrl: "/admin/conversations/design-room/messages.json", publicId: "design-room", showUrl: "/admin/conversations/design-room", title: "Design room", topic: "Polish the workspace", unreadCount: 0 }
    ],
    inboxUrl: "/admin/conversations.json",
    savedMessagesUrl: "/admin/conversations/saved",
    searchUrl: "/admin/conversations/search",
    selected
  }
}

function jsonResponse(payload: unknown, status = 200) {
  return Promise.resolve(new Response(JSON.stringify(payload), {
    headers: { "Content-Type": "application/json" },
    status
  }))
}

function deferredResponse() {
  let resolve!: (response: Response) => void
  const promise = new Promise<Response>(done => { resolve = done })
  return { promise, resolve }
}

function deferredFailure() {
  let reject!: (error: Error) => void
  const promise = new Promise<Response>((_resolve, fail) => { reject = fail })
  return { promise, reject }
}

describe("ConversationWorkspace", () => {
  it("submits bounded search to the canonical Rails endpoint", () => {
    render(<ConversationWorkspace {...props()} />)

    const search = screen.getByRole("searchbox", { name: "Search conversations" })
    expect(search).toHaveAttribute("maxlength", "100")
    expect(search.closest("form")).toHaveAttribute("action", "/admin/conversations/search")
    expect(search.closest("form")).toHaveAttribute("method", "get")
  })

  beforeEach(() => {
    window.localStorage.clear()
    window.history.replaceState({}, "", "/admin/conversations/release-room")
    vi.restoreAllMocks()
    cable.callbacks.length = 0
    cable.created.length = 0
    cable.connect.mockClear()
    cable.disconnect.mockClear()
    cable.subscriptions.create.mockClear()
    Object.defineProperty(HTMLElement.prototype, "scrollIntoView", { configurable: true, value: vi.fn() })
  })

  it("scrolls a canonical search deep link to its matching message", async () => {
    window.history.replaceState({}, "", "/admin/conversations/release-room?before=3#message-message-2")

    render(<ConversationWorkspace {...props()} />)

    await waitFor(() => expect(document.getElementById("message-message-2")?.scrollIntoView).toHaveBeenCalledWith({ block: "center" }))
  })

  it("renders semantic messages as escaped text and exposes labelled durable actions", () => {
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [message(2, { body: "<b>plain</b> ✅" })] }))} />)

    expect(screen.getByText("<b>plain</b> ✅")).toBeInTheDocument()
    expect(document.querySelector(".conversation-message-list b")).not.toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Mark read through here" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Save message" })).toHaveAttribute("aria-pressed", "false")
    expect(screen.getByRole("button", { name: "Like message by You, 0 total" })).toHaveAttribute("aria-pressed", "false")
    expect(screen.getByRole("button", { name: "Dislike message by You, 0 total" })).toHaveAttribute("aria-pressed", "false")
    expect(screen.getByRole("button", { name: "Question message by You, 0 total" })).toHaveAttribute("aria-pressed", "false")
    expect(screen.getByRole("button", { name: "Insert check mark emoji" })).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Scheduled messages" })).toHaveAttribute(
      "href",
      "/admin/conversations/release-room/scheduled_messages"
    )
    expect(screen.getByRole("link", { name: "Saved messages" })).toHaveAttribute("href", "/admin/conversations/saved")
    expect(screen.getByText("3 participants")).toBeInTheDocument()
    expect(screen.getAllByRole("time")[2]).toHaveAccessibleName(/Sent .*September 28, 2026/)
    expect(document.querySelector('use[href="/showcase-icons.svg#heroicons-users"]')).toBeInTheDocument()
  })

  it("renders structured mentions and replies, offers reply composition, and copies a canonical deep link", async () => {
    const user = userEvent.setup()
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, "clipboard", { configurable: true, value: { writeText } })
    const source = message(1, { body: "Source message" })
    const reply = message(2, {
      body: "Thanks @Riley Chen and @You",
      mentions: [
        { memberKey: "riley-chen", text: "@Riley Chen" },
        { memberKey: "current-member", text: "@You" }
      ],
      replyTo: { authorName: "Release Lead", body: "Source message", publicId: source.publicId, withdrawn: false }
    })
    const latest = props(thread("release-room", { messages: [source, reply, message(3)] }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ message: message(3), ok: true }))
      .mockImplementationOnce(() => jsonResponse(latest))
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [source, reply] }))} />)

    expect(screen.getByText("@Riley Chen")).toHaveAttribute("data-member-key", "riley-chen")
    expect(screen.getByRole("link", { name: "Replying to Release Lead" })).toHaveAttribute("href", "#message-message-1")

    await user.click(screen.getAllByRole("button", { name: "Reply" })[0])
    expect(screen.getByText("Replying to Release Lead", { selector: "strong" })).toBeInTheDocument()
    await waitFor(() => expect(screen.getByLabelText("Message as You")).toHaveFocus())
    await user.click(screen.getByRole("button", { name: "Cancel reply" }))
    expect(screen.queryByText("Replying to Release Lead", { selector: "strong" })).not.toBeInTheDocument()
    await user.click(screen.getAllByRole("button", { name: "Reply" })[0])

    await user.click(screen.getAllByRole("button", { name: "Copy link" })[0])
    expect(writeText).toHaveBeenCalledWith("http://localhost:3000/admin/conversations/release-room#message-message-1")
    expect(screen.getByText("Message link copied.")).toHaveClass("conversation-notice")

    await user.type(screen.getByLabelText("Message as You"), "Reply from composer")
    await user.click(screen.getByRole("button", { name: "Send message" }))
    const formData = fetchMock.mock.calls[0][1]?.body as FormData
    expect(formData.get("message[reply_to_public_id]")).toBe("message-1")
  })

  it("reports a clipboard failure and quotes a withdrawn reply target as a tombstone", async () => {
    const user = userEvent.setup()
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: vi.fn().mockRejectedValue(new Error("denied")) }
    })
    const withdrawn = message(1, { body: "[withdrawn]", withdrawn: true })
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [withdrawn] }))} />)

    await user.click(screen.getByRole("button", { name: "Copy link" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("could not be copied")
    await user.click(screen.getByRole("button", { name: "Reply" }))
    expect(screen.getByText("[withdrawn]", { selector: ".conversation-composer-reply p" })).toBeInTheDocument()
  })

  it("selects a participant mention by keyboard and sends its durable member key", async () => {
    const user = userEvent.setup()
    const latest = props(thread("release-room", { messages: [message(1), message(2), message(3)] }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ message: message(3), ok: true }))
      .mockImplementationOnce(() => jsonResponse(latest))
    render(<ConversationWorkspace {...props()} />)
    const composer = screen.getByRole("combobox", { name: "Message as You" })

    await user.type(composer, "Thanks @Ril")
    expect(screen.getByRole("listbox", { name: "Mention suggestions" })).toBeInTheDocument()
    expect(screen.getByRole("option", { name: /Riley Chen/ })).toHaveAttribute("aria-selected", "true")
    await user.keyboard("{Enter}")
    expect(composer).toHaveValue("Thanks @Riley Chen ")
    expect(composer).toHaveFocus()

    await user.click(screen.getByRole("button", { name: "Send message" }))
    const formData = fetchMock.mock.calls[0][1]?.body as FormData
    expect(formData.get("message[body]")).toBe("Thanks @Riley Chen ")
    expect(formData.getAll("message[mentioned_member_keys][]")).toEqual([ "riley-chen" ])
    expect(formData.get("message[public_id]")).toMatch(/^[0-9a-f-]{36}$/u)
  })

  it("cycles, dismisses, and pointer-selects mention suggestions", async () => {
    const user = userEvent.setup()
    render(<ConversationWorkspace {...props()} />)
    const composer = screen.getByRole("combobox", { name: "Message as You" })

    await user.type(composer, "@")
    await user.keyboard("{ArrowDown}")
    expect(screen.getByRole("option", { name: "You (you)" })).toHaveAttribute("aria-selected", "true")
    await user.keyboard("{ArrowUp}")
    expect(screen.getByRole("option", { name: "Release Lead" })).toHaveAttribute("aria-selected", "true")
    await user.keyboard("{Escape}")
    expect(screen.queryByRole("listbox", { name: "Mention suggestions" })).not.toBeInTheDocument()

    await user.clear(composer)
    await user.type(composer, "@Ril")
    await user.click(screen.getByRole("button", { name: "Riley Chen" }))
    expect(composer).toHaveValue("@Riley Chen ")
  })

  it("uses singular participant labels for one-person inbox and thread data", () => {
    const input = props(thread("release-room", {
      participants: [ { current: true, displayName: "You", key: "current-member" } ]
    }))
    input.inbox[0].memberCount = 1

    render(<ConversationWorkspace {...input} />)

    expect(screen.getByText("1 participant", { selector: "summary" })).toBeInTheDocument()
    expect(document.querySelector(".conversation-inbox-topic")).toHaveTextContent("1 participant")
  })

  it("sets, changes, and removes the current disposition from canonical Rails responses", async () => {
    const user = userEvent.setup()
    const neutral = message(1)
    const liked = message(1, { dispositions: { counts: { dislike: 0, like: 1, question: 0 }, mine: "like" } })
    const questioned = message(1, { dispositions: { counts: { dislike: 0, like: 0, question: 1 }, mine: "question" } })
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ message: liked, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [liked] }))))
      .mockImplementationOnce(() => jsonResponse({ message: questioned, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [questioned] }))))
      .mockImplementationOnce(() => jsonResponse({ message: neutral, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [neutral] }))))
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [neutral] }))} />)

    await user.click(screen.getByRole("button", { name: "Like message by Release Lead, 0 total" }))
    expect(await screen.findByRole("button", { name: "Like message by Release Lead, 1 total" })).toHaveAttribute("aria-pressed", "true")

    await user.click(screen.getByRole("button", { name: "Question message by Release Lead, 0 total" }))
    const question = await screen.findByRole("button", { name: "Question message by Release Lead, 1 total" })
    expect(question).toHaveAttribute("aria-pressed", "true")
    expect(screen.getByRole("button", { name: "Like message by Release Lead, 0 total" })).toHaveAttribute("aria-pressed", "false")

    await user.click(question)
    expect(await screen.findByRole("button", { name: "Question message by Release Lead, 0 total" })).toHaveAttribute("aria-pressed", "false")

    const calls = vi.mocked(globalThis.fetch).mock.calls
    expect(calls[0][1]).toMatchObject({ method: "POST" })
    expect(calls[2][1]).toMatchObject({ method: "POST" })
    expect(calls[4][1]).toMatchObject({ method: "DELETE" })
  })

  it("retries a failed disposition mutation idempotently", async () => {
    const user = userEvent.setup()
    const neutral = message(1)
    const liked = message(1, { dispositions: { counts: { dislike: 0, like: 1, question: 0 }, mine: "like" } })
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "Disposition unavailable" }, 503))
      .mockImplementationOnce(() => jsonResponse({ message: liked, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [liked] }))))
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [neutral] }))} />)

    await user.click(screen.getByRole("button", { name: "Like message by Release Lead, 0 total" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Disposition unavailable")
    await user.click(screen.getByRole("button", { name: "Retry" }))

    expect(await screen.findByRole("button", { name: "Like message by Release Lead, 1 total" })).toHaveAttribute("aria-pressed", "true")
    expect(fetchMock.mock.calls[0][1]?.method).toBe("POST")
    expect(fetchMock.mock.calls[1][1]?.method).toBe("POST")
  })

  it("saves and removes a message through canonical Rails state", async () => {
    const user = userEvent.setup()
    const unsaved = message(1)
    const saved = { ...unsaved, saved: true }
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ message: saved, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [saved] }))))
      .mockImplementationOnce(() => jsonResponse({ message: unsaved, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [unsaved] }))))
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [unsaved] }))} />)

    await user.click(screen.getByRole("button", { name: "Save message" }))
    const remove = await screen.findByRole("button", { name: "Remove from saved" })
    expect(remove).toHaveAttribute("aria-pressed", "true")
    expect(screen.getByText("Message saved.")).toHaveClass("conversation-notice")

    await user.click(remove)
    expect(await screen.findByRole("button", { name: "Save message" })).toHaveAttribute("aria-pressed", "false")
    expect(screen.getByText("Message removed from saved messages.")).toHaveClass("conversation-notice")
  })

  it("offers an idempotent retry after a save failure", async () => {
    const user = userEvent.setup()
    const saved = message(1, { saved: true })
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "Save failed" }, 503))
      .mockImplementationOnce(() => jsonResponse({ message: saved, ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [saved] }))))
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [message(1)] }))} />)

    await user.click(screen.getByRole("button", { name: "Save message" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Save failed")
    await user.click(screen.getByRole("button", { name: "Retry" }))

    expect(await screen.findByRole("button", { name: "Remove from saved" })).toHaveAttribute("aria-pressed", "true")
    expect(fetchMock.mock.calls[0][1]?.method).toBe("POST")
    expect(fetchMock.mock.calls[1][1]?.method).toBe("POST")
  })

  it("submits a bounded attachment as multipart data and renders canonical metadata", async () => {
    const user = userEvent.setup()
    const upload = new File([ "release notes" ], "release-notes.txt", { type: "text/plain" })
    const canonical = message(3, {
      attachment: {
        byteSize: 13,
        contentType: "text/plain",
        filename: "release-notes.txt",
        inline: false,
        url: "/admin/conversations/release-room/messages/message-3/attachments/attachment-3"
      },
      body: "Attached notes"
    })
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce((_, options) => {
        expect(options?.body).toBeInstanceOf(FormData)
        const body = options?.body as FormData
        expect(body.get("message[body]")).toBe("Attached notes")
        expect(body.get("message[attachment]")).toBe(upload)
        expect(options?.headers).not.toHaveProperty("Content-Type")
        return jsonResponse({ message: canonical, ok: true })
      })
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [message(1), message(2), canonical] }))))
    render(<ConversationWorkspace {...props()} />)

    await user.type(screen.getByLabelText("Message as You"), "Attached notes")
    const attachmentInput = screen.getByLabelText("Attachment (optional)")
    fireEvent.change(attachmentInput, { target: { files: [] } })
    await user.upload(attachmentInput, upload)
    await user.click(screen.getByRole("button", { name: "Send message" }))

    expect(await screen.findByRole("link", { name: "release-notes.txt" })).toHaveAttribute("href", canonical.attachment?.url)
    expect(screen.getByLabelText("Attachment (optional)")).toHaveValue("")
  })

  it("renders authorized inline image previews from the canonical Rails route", () => {
    render(<ConversationWorkspace {...props(thread("release-room", { messages: [message(1, {
      attachment: {
        byteSize: 1024,
        contentType: "image/png",
        filename: "proof.png",
        inline: true,
        url: "/admin/conversations/release-room/messages/message-1/attachments/proof"
      }
    })] }))} />)

    expect(screen.getByRole("img", { name: "Attachment preview: proof.png" })).toHaveAttribute(
      "src",
      "/admin/conversations/release-room/messages/message-1/attachments/proof"
    )
  })

  it("subscribes only to the selected conversation, reconciles on connect, and cleans up its client", () => {
    const mounted = render(<ConversationWorkspace {...props()} />)

    expect(cable.subscriptions.create).toHaveBeenCalledWith(
      { channel: "ConversationChannel", conversation_public_id: "release-room" },
      expect.objectContaining({
        connected: expect.any(Function),
        disconnected: expect.any(Function),
        received: expect.any(Function),
        rejected: expect.any(Function)
      })
    )
    act(() => cable.callbacks[0].connected())
    expect(cable.created[0].perform).toHaveBeenCalledWith("reconcile")

    mounted.unmount()
    expect(cable.created[0].unsubscribe).toHaveBeenCalledOnce()
    expect(cable.disconnect).toHaveBeenCalledOnce()
  })

  it("uses a separate ephemeral presence subscription with bounded typing and graceful disconnect", async () => {
    vi.useFakeTimers()
    const selected = thread("release-room", {
      presence: {
        channel: "ConversationPresenceChannel",
        heartbeatIntervalMs: 15_000,
        typingIdleMs: 3_000
      }
    })
    const mounted = render(<ConversationWorkspace {...props(selected)} />)

    expect(cable.subscriptions.create).toHaveBeenCalledTimes(2)
    expect(cable.subscriptions.create).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        channel: "ConversationPresenceChannel",
        conversation_public_id: "release-room",
        session_id: expect.stringMatching(/^[a-zA-Z0-9_-]{16,80}$/)
      }),
      expect.objectContaining({
        connected: expect.any(Function),
        disconnected: expect.any(Function),
        received: expect.any(Function),
        rejected: expect.any(Function)
      })
    )

    act(() => cable.callbacks[0].connected())
    expect(cable.created[0].perform).toHaveBeenCalledWith("reconcile")
    expect(cable.created[0].perform).toHaveBeenCalledWith("heartbeat")

    act(() => cable.callbacks[0].received({
      conversationPublicId: "release-room",
      kind: "presence",
      online: ["You", "Release Lead"],
      serverAt: "2026-09-28T12:00:00.000000Z",
      typing: ["Release Lead"]
    }))
    expect(screen.getByRole("status")).toHaveTextContent("2 people online")
    expect(screen.getByRole("status")).toHaveTextContent("Release Lead is typing…")

    act(() => cable.callbacks[0].received({
      conversationPublicId: "release-room",
      kind: "presence",
      online: ["You"],
      serverAt: "2026-09-28T12:00:01.000000Z",
      typing: ["Release Lead", "Design Lead"]
    }))
    expect(screen.getByRole("status")).toHaveTextContent("1 person online")
    expect(screen.getByRole("status")).toHaveTextContent("Release Lead, Design Lead are typing…")

    fireEvent.change(screen.getByLabelText("Message as You"), { target: { value: "Presence remains ephemeral" } })
    expect(cable.created[0].perform).toHaveBeenCalledWith("typing", { active: true })
    act(() => vi.advanceTimersByTime(3_000))
    expect(cable.created[0].perform).toHaveBeenCalledWith("typing", { active: false })

    act(() => cable.callbacks[0].disconnected())
    expect(screen.getByRole("status")).toHaveTextContent("Live activity unavailable")
    expect(screen.getByLabelText("Message as You")).toHaveValue("Presence remains ephemeral")

    act(() => cable.callbacks[0].connected())
    act(() => vi.advanceTimersByTime(15_000))
    expect(cable.created[0].perform.mock.calls.filter(([action]) => action === "heartbeat")).toHaveLength(3)

    mounted.unmount()
    expect(cable.created[0].unsubscribe).toHaveBeenCalledOnce()
    expect(cable.created[1].unsubscribe).toHaveBeenCalledOnce()
    vi.useRealTimers()
  })

  it("ignores malformed or foreign presence envelopes and contains a rejected presence subscription", () => {
    const selected = thread("release-room", {
      presence: {
        channel: "ConversationPresenceChannel",
        heartbeatIntervalMs: 15_000,
        typingIdleMs: 3_000
      }
    })
    render(<ConversationWorkspace {...props(selected)} />)

    act(() => cable.callbacks[0].connected())
    act(() => cable.callbacks[0].received({
      conversationPublicId: "design-room",
      kind: "presence",
      online: ["Private member"],
      serverAt: "2026-09-28T12:00:00.000000Z",
      typing: ["Private member"]
    }))
    act(() => cable.callbacks[0].received({
      conversationPublicId: "release-room",
      kind: "presence",
      online: "Private member",
      serverAt: "not-a-time",
      typing: []
    }))
    expect(screen.getByRole("status")).not.toHaveTextContent("Private member")

    act(() => cable.callbacks[0].rejected())
    expect(screen.getByRole("status")).toHaveTextContent("Live activity unavailable")
  })

  it("treats versioned Cable events as invalidations and ignores duplicate, stale, foreign, and malformed events", async () => {
    const canonical = props(thread("release-room", {
      messages: [message(2), message(3)],
      realtime: {
        channel: "ConversationChannel",
        latestSequence: 3,
        serverAt: "2026-09-28T12:01:00.000000Z",
        version: 3
      }
    }))
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(canonical))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].received({
      conversationPublicId: "release-room",
      kind: "message_created",
      latestSequence: 3,
      serverAt: "2026-09-28T12:01:00.000000Z",
      version: 3
    }))
    expect(await screen.findByText("Message 3")).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(1)

    act(() => {
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 3, serverAt: "2026-09-28T12:01:00.000000Z", version: 3 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_edited", latestSequence: 2, serverAt: "2026-09-28T12:00:30.000000Z", version: 2 })
      cable.callbacks[0].received({ conversationPublicId: "design-room", kind: "message_created", latestSequence: 4, serverAt: "2026-09-28T12:02:00.000000Z", version: 4 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: -1, serverAt: "not-a-time", version: 4 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 4, serverAt: "not-a-time", version: 4 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: 7, latestSequence: 4, serverAt: "2026-09-28T12:02:00.000000Z", version: 4 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 4.5, serverAt: "2026-09-28T12:02:00.000000Z", version: 4 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 4, serverAt: "2026-09-28T12:02:00.000000Z", version: -1 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 4, serverAt: "2026-09-28T12:02:00.000000Z", version: 4.5 })
    })
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it("coalesces a newer event during reconciliation and refetches until the Rails version catches up", async () => {
    const first = deferredResponse()
    const versionTwo = props(thread("release-room", {
      realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:01:00.000000Z", version: 2 }
    }))
    const versionThree = props(thread("release-room", {
      realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:02:00.000000Z", version: 3 }
    }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => first.promise)
      .mockImplementationOnce(() => jsonResponse(versionThree))
    render(<ConversationWorkspace {...props()} />)

    act(() => {
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_edited", latestSequence: 2, serverAt: "2026-09-28T12:01:00.000000Z", version: 2 })
      cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_withdrawn", latestSequence: 2, serverAt: "2026-09-28T12:02:00.000000Z", version: 3 })
    })
    await act(async () => first.resolve(await jsonResponse(versionTwo)))

    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
  })

  it("resumes realtime reconciliation after a manual refresh supersedes an in-flight snapshot", async () => {
    const user = userEvent.setup()
    const realtimeSnapshot = deferredResponse()
    const versionOne = props(thread("release-room", {
      realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:01:00.000000Z", version: 1 }
    }))
    const versionTwo = props(thread("release-room", {
      messages: [message(2), message(3)],
      realtime: { channel: "ConversationChannel", latestSequence: 3, serverAt: "2026-09-28T12:02:00.000000Z", version: 2 }
    }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => realtimeSnapshot.promise)
      .mockImplementationOnce(() => jsonResponse(versionOne))
      .mockImplementationOnce(() => jsonResponse(versionTwo))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 3, serverAt: "2026-09-28T12:02:00.000000Z", version: 2 }))
    await user.click(screen.getByRole("button", { name: "Refresh" }))
    await act(async () => realtimeSnapshot.resolve(await jsonResponse(versionOne)))

    expect(await screen.findByText("Message 3")).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(3)
  })

  it("bounds stale snapshot retries and offers manual refresh", async () => {
    const stale = props(thread("release-room", {
      realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:00:00.000000Z", version: 0 }
    }))
    const current = props(thread("release-room", {
      realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:03:00.000000Z", version: 5 }
    }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse(stale))
      .mockImplementationOnce(() => jsonResponse(stale))
      .mockImplementationOnce(() => jsonResponse(stale))
      .mockImplementationOnce(() => jsonResponse(current))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].received({
      conversationPublicId: "release-room",
      kind: "disposition",
      latestSequence: 2,
      serverAt: "2026-09-28T12:03:00.000000Z",
      version: 5
    }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Refresh to reconcile")
    expect(fetchMock).toHaveBeenCalledTimes(3)
    await userEvent.setup().click(screen.getByRole("button", { name: "Retry" }))
    await waitFor(() => expect(screen.queryByRole("alert")).not.toBeInTheDocument())
    expect(fetchMock).toHaveBeenCalledTimes(4)
  })

  it("reports an active reconciliation failure and safely ignores a mismatched Rails snapshot", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => Promise.reject(new Error("Canonical fetch failed")))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", {
        realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:03:00.000000Z", version: 1 }
      }))))
      .mockImplementationOnce(() => jsonResponse(props(thread("design-room"))))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "read_state", latestSequence: 2, serverAt: "2026-09-28T12:03:00.000000Z", version: 1 }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Canonical fetch failed")
    await userEvent.setup().click(screen.getByRole("button", { name: "Retry" }))
    await waitFor(() => expect(screen.queryByRole("alert")).not.toBeInTheDocument())

    act(() => cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "read_state", latestSequence: 2, serverAt: "2026-09-28T12:04:00.000000Z", version: 2 }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(3))
    expect(screen.getByRole("heading", { name: "Release room" })).toBeInTheDocument()
  })

  it("does not leak a realtime reconciliation failure into a newly selected conversation", async () => {
    const user = userEvent.setup()
    const realtimeFailure = deferredFailure()
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => realtimeFailure.promise)
      .mockImplementationOnce(() => jsonResponse(props(thread("design-room"))))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 3, serverAt: "2026-09-28T12:03:00.000000Z", version: 1 }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await act(async () => realtimeFailure.reject(new Error("Old live fetch failed")))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(screen.queryByText("Old live fetch failed")).not.toBeInTheDocument()
  })

  it("reconciles a new conversation while the previous conversation still has an in-flight refresh", async () => {
    const user = userEvent.setup()
    const oldRefresh = deferredResponse()
    const designInitial = props(thread("design-room", {
      realtime: { channel: "ConversationChannel", latestSequence: 2, serverAt: "2026-09-28T12:00:00.000000Z", version: 0 }
    }))
    const designCurrent = props(thread("design-room", {
      messages: [message(2), message(3)],
      realtime: { channel: "ConversationChannel", latestSequence: 3, serverAt: "2026-09-28T12:03:00.000000Z", version: 1 }
    }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => oldRefresh.promise)
      .mockImplementationOnce(() => jsonResponse(designInitial))
      .mockImplementationOnce(() => jsonResponse(designCurrent))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 3, serverAt: "2026-09-28T12:01:00.000000Z", version: 1 }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await waitFor(() => expect(cable.callbacks).toHaveLength(2))
    act(() => cable.callbacks[1].received({ conversationPublicId: "design-room", kind: "message_created", latestSequence: 3, serverAt: "2026-09-28T12:03:00.000000Z", version: 1 }))

    expect(await screen.findByText("Message 3")).toBeInTheDocument()
    await act(async () => oldRefresh.resolve(await jsonResponse(props(thread("release-room")))))
    expect(screen.getByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(3)
  })

  it("ignores a late rejection from a conversation that is no longer selected", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(props(thread("design-room"))))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await screen.findByRole("heading", { name: "Design room" })
    act(() => cable.callbacks[0].rejected())

    expect(screen.queryByText("Live updates were not authorized. Manual refresh remains available.")).not.toBeInTheDocument()
  })

  it("announces a realtime message outside the viewport and reconciles an initially empty thread", async () => {
    const empty = thread("release-room", {
      messages: [],
      realtime: { channel: "ConversationChannel", latestSequence: 0, serverAt: "2026-09-28T12:00:00.000000Z", version: 0 }
    })
    const canonical = props(thread("release-room", {
      messages: [message(1)],
      realtime: { channel: "ConversationChannel", latestSequence: 1, serverAt: "2026-09-28T12:01:00.000000Z", version: 1 }
    }))
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(canonical))
    render(<ConversationWorkspace {...props(empty)} />)
    const list = screen.getByRole("list", { name: "Messages" })
    Object.defineProperties(list, {
      clientHeight: { configurable: true, value: 100 },
      scrollHeight: { configurable: true, value: 1000 },
      scrollTop: { configurable: true, value: 0, writable: true }
    })

    act(() => cable.callbacks[0].received({ conversationPublicId: "release-room", kind: "message_created", latestSequence: 1, serverAt: "2026-09-28T12:01:00.000000Z", version: 1 }))

    expect(await screen.findByRole("button", { name: "1 new message · Jump to newest" })).toBeInTheDocument()
  })

  it.each([
    {
      expected: "Message 5",
      fetched: [message(3), message(4), message(5)],
      kind: "message_created"
    },
    {
      expected: "Message 4 edited live",
      fetched: [message(3), message(4, { body: "Message 4 edited live", edited: true })],
      kind: "message_edited"
    },
    {
      expected: "[withdrawn]",
      fetched: [message(3), message(4, { body: "[withdrawn]", editable: false, withdrawn: true })],
      kind: "message_withdrawn"
    }
  ])("preserves loaded history and scroll context for a realtime $kind invalidation", async ({ expected, fetched, kind }) => {
    const user = userEvent.setup()
    const initial = thread("release-room", { messages: [message(3), message(4)], olderCursor: 3 })
    const older = props(thread("release-room", { messages: [message(1), message(2)], olderCursor: null }))
    const canonical = props(thread("release-room", {
      messages: fetched,
      olderCursor: 3,
      realtime: {
        channel: "ConversationChannel",
        latestSequence: fetched.at(-1)?.sequence || 0,
        serverAt: "2026-09-28T12:03:00.000000Z",
        version: 1
      }
    }))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse(older))
      .mockImplementationOnce(() => jsonResponse(canonical))
    render(<ConversationWorkspace {...props(initial)} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    await act(async () => new Promise<void>(resolve => window.requestAnimationFrame(() => resolve())))
    const list = screen.getByRole("list", { name: "Messages" })
    Object.defineProperties(list, {
      clientHeight: { configurable: true, value: 100 },
      scrollHeight: { configurable: true, value: 1000 },
      scrollTop: { configurable: true, value: 120, writable: true }
    })

    act(() => cable.callbacks[0].received({
      conversationPublicId: "release-room",
      kind,
      latestSequence: fetched.at(-1)?.sequence || 0,
      serverAt: "2026-09-28T12:03:00.000000Z",
      version: 1
    }))

    expect(await screen.findByText(expected)).toBeInTheDocument()
    expect(screen.getByText("Message 1")).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Load 50 older messages" })).not.toBeInTheDocument()
    expect(list.scrollTop).toBe(120)
  })

  it("keeps Rails mutations working while Cable is disconnected", async () => {
    const user = userEvent.setup()
    const canonical = props(thread("release-room", {
      messages: [message(1), message(2), message(3)],
      realtime: {
        channel: "ConversationChannel",
        latestSequence: 3,
        serverAt: "2026-09-28T12:01:00.000000Z",
        version: 1
      }
    }))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ message: message(3), ok: true }, 201))
      .mockImplementationOnce(() => jsonResponse(canonical))
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].disconnected())
    await user.type(screen.getByLabelText("Message as You"), "Works without Cable")
    await user.click(screen.getByRole("button", { name: "Send message" }))

    expect(await screen.findByText("Message 3")).toBeInTheDocument()
    expect(screen.getByText("Message sent.")).toBeInTheDocument()
  })

  it("surfaces a rejected subscription without replacing the server-rendered workspace", () => {
    render(<ConversationWorkspace {...props()} />)

    act(() => cable.callbacks[0].rejected())

    expect(screen.getByRole("alert")).toHaveTextContent("Live updates were not authorized")
    expect(screen.getByRole("heading", { name: "Release room" })).toBeInTheDocument()
  })

  it("navigates without stale responses and restores focus to the selected thread heading", async () => {
    const user = userEvent.setup()
    const designPayload = props(thread("design-room"))
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(designPayload))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("link", { name: /Design room/ }))

    const heading = await screen.findByRole("heading", { name: "Design room" })
    await waitFor(() => expect(heading).toHaveFocus())
    expect(window.location.pathname).toBe("/admin/conversations/design-room")
  })

  it("keeps a manual refresh near the newest canonical message", async () => {
    const user = userEvent.setup()
    const current = props(thread("release-room", {
      messages: [message(1), message(2), message(3)],
      realtime: { channel: "ConversationChannel", latestSequence: 3, serverAt: "2026-09-28T12:01:00.000000Z", version: 1 }
    }))
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(current))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("button", { name: "Refresh" }))

    expect(await screen.findByText("Message 3")).toBeInTheDocument()
    await waitFor(() => expect(HTMLElement.prototype.scrollIntoView).toHaveBeenCalled())
  })

  it("does not let a completed mutation pull the workspace back to an older conversation or clear the next draft", async () => {
    const user = userEvent.setup()
    const pendingMutation = deferredResponse()
    const designPayload = props(thread("design-room"))
    window.localStorage.setItem("showcase:conversation-draft:design-room-member:design-room", "Design follow-up")
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => pendingMutation.promise)
      .mockImplementationOnce(() => jsonResponse(designPayload))
    render(<ConversationWorkspace {...props()} />)

    await user.type(screen.getByLabelText("Message as You"), "Ship A")
    await user.click(screen.getByRole("button", { name: /Send message/ }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    expect(await screen.findByDisplayValue("Design follow-up")).toBeInTheDocument()

    await act(async () => pendingMutation.resolve(await jsonResponse({ message: message(3), ok: true })))

    expect(screen.getByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(screen.getByDisplayValue("Design follow-up")).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it("preserves text typed after submit while clearing only an unchanged successful draft", async () => {
    const user = userEvent.setup()
    const pendingMutation = deferredResponse()
    const latest = props(thread("release-room", { messages: [message(1), message(2), message(3)] }))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => pendingMutation.promise)
      .mockImplementationOnce(() => jsonResponse(latest))
    render(<ConversationWorkspace {...props()} />)
    const composer = screen.getByLabelText("Message as You")

    await user.type(composer, "First thought")
    await user.click(screen.getByRole("button", { name: /Send message/ }))
    await user.type(composer, " plus a newer thought")
    await act(async () => pendingMutation.resolve(await jsonResponse({ message: message(3), ok: true })))

    await waitFor(() => expect(composer).toHaveValue("First thought plus a newer thought"))
    expect(window.localStorage.getItem("showcase:conversation-draft:release-room-member:release-room")).toBe("First thought plus a newer thought")
  })

  it("keeps a failed-send draft and retries with the same client mutation identity", async () => {
    const user = userEvent.setup()
    const upload = new File([ "retry proof" ], "retry-proof.txt", { type: "text/plain" })
    const latest = props(thread("release-room", { messages: [message(1), message(2), message(3)] }))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "Try again" }, 503))
      .mockImplementationOnce(() => jsonResponse({ message: message(3), ok: true }))
      .mockImplementationOnce(() => jsonResponse(latest))
    render(<ConversationWorkspace {...props()} />)
    const composer = screen.getByLabelText("Message as You")

    await user.type(composer, "Retry safely")
    await user.upload(screen.getByLabelText("Attachment (optional)"), upload)
    await user.click(screen.getByRole("button", { name: "Send message" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Try again")
    expect(composer).toHaveValue("Retry safely")

    await user.click(screen.getByRole("button", { name: "Retry" }))
    await waitFor(() => expect(composer).toHaveValue(""))
    expect(window.localStorage.getItem("showcase:conversation-draft:release-room-member:release-room")).toBeNull()
    const requests = vi.mocked(fetch).mock.calls.filter(call => (call[1]?.body as FormData | undefined)?.has("message[public_id]"))
    expect(requests).toHaveLength(2)
    expect((requests[0][1]?.body as FormData).get("message[public_id]")).toBe(
      (requests[1][1]?.body as FormData).get("message[public_id]")
    )
    expect((requests[0][1]?.body as FormData).get("message[attachment]")).toBe(upload)
    expect((requests[1][1]?.body as FormData).get("message[attachment]")).toBe(upload)
  })

  it("does not leak a stale refresh failure into a newly selected conversation", async () => {
    const user = userEvent.setup()
    const failedRefresh = deferredFailure()
    const designPayload = props(thread("design-room"))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => failedRefresh.promise)
      .mockImplementationOnce(() => jsonResponse(designPayload))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("button", { name: "Refresh" }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await act(async () => failedRefresh.reject(new Error("Old room failed")))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(screen.queryByText("Old room failed")).not.toBeInTheDocument()
  })

  it("does not let a stale successful refresh replace a newly selected conversation", async () => {
    const user = userEvent.setup()
    const staleRefresh = deferredResponse()
    const designPayload = props(thread("design-room"))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => staleRefresh.promise)
      .mockImplementationOnce(() => jsonResponse(designPayload))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("button", { name: "Refresh" }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await act(async () => staleRefresh.resolve(await jsonResponse(props(thread()))))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
  })

  it("loads anchored older history, focuses the list when the control disappears, and preserves the earliest cursor after refresh", async () => {
    const user = userEvent.setup()
    const newestMessages = [message(3), message(4)]
    const olderMessages = [message(1), message(2)]
    const initial = thread("release-room", { messages: newestMessages, olderCursor: 3 })
    const olderPayload = props(thread("release-room", { messages: olderMessages, olderCursor: null }))
    const refreshedPayload = props(thread("release-room", { messages: newestMessages, olderCursor: 3 }))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse(olderPayload))
      .mockImplementationOnce(() => jsonResponse(refreshedPayload))
    render(<ConversationWorkspace {...props(initial)} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    const messageList = screen.getByRole("list", { name: "Messages" })
    await waitFor(() => expect(messageList).toHaveFocus())
    expect(screen.queryByRole("button", { name: "Load 50 older messages" })).not.toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Refresh" }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(2))
    expect(screen.getByText("Message 1")).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Load 50 older messages" })).not.toBeInTheDocument()
  })

  it("replaces an edited message outside the newest page with its canonical mutation representation", async () => {
    const user = userEvent.setup()
    const newestMessages = [message(3, { editable: false, own: false }), message(4, { editable: false, own: false })]
    const oldEditable = message(2, { body: "Original older body", editable: true, own: true })
    const initial = thread("release-room", { messages: newestMessages, olderCursor: 3 })
    const olderPayload = props(thread("release-room", { messages: [message(1), oldEditable], olderCursor: null }))
    const canonical = { ...oldEditable, body: "Canonical revised body", edited: true }
    const refreshedPayload = props(thread("release-room", { messages: newestMessages, olderCursor: 3 }))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse(olderPayload))
      .mockImplementationOnce(() => jsonResponse({ message: canonical, ok: true }))
      .mockImplementationOnce(() => jsonResponse(refreshedPayload))
    render(<ConversationWorkspace {...props(initial)} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    const olderArticle = screen.getByText("Original older body").closest("article")!
    await user.click(within(olderArticle).getByRole("button", { name: "Edit" }))
    const editor = within(olderArticle).getByLabelText("Edit message")
    await user.clear(editor)
    await user.type(editor, "Canonical revised body")
    await user.click(within(olderArticle).getByRole("button", { name: "Save" }))

    expect(await screen.findByText("Canonical revised body")).toBeInTheDocument()
    expect(screen.queryByText("Original older body")).not.toBeInTheDocument()
  })

  it("advances through two older-history cursors without repeating a page", async () => {
    const user = userEvent.setup()
    const newest = [message(5), message(6)]
    const middle = [message(3), message(4)]
    const oldest = [message(1), message(2)]
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: middle, olderCursor: 3 }))))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: oldest, olderCursor: null }))))
    render(<ConversationWorkspace {...props(thread("release-room", { messages: newest, olderCursor: 5 }))} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))

    await waitFor(() => expect(screen.getByText("Message 1")).toBeInTheDocument())
    expect(fetchMock.mock.calls[0][0]).toContain("before=5")
    expect(fetchMock.mock.calls[1][0]).toContain("before=3")
  })

  it("restores focus to the inbox heading on narrow-style back navigation", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(props(null)))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("button", { name: /Inbox/ }))

    const heading = await screen.findByRole("heading", { name: "Conversations" })
    await waitFor(() => expect(heading).toHaveFocus())
  })

  it("shows empty, retryable error, and successful retry states", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "Temporary failure" }, 503))
      .mockImplementationOnce(() => jsonResponse(props(thread("design-room", { messages: [] }))))
    render(<ConversationWorkspace {...props(null)} />)

    await user.click(screen.getByRole("link", { name: /Design room/ }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Temporary failure")
    await user.click(screen.getByRole("button", { name: "Retry" }))
    expect(await screen.findByText("No messages yet. Start the conversation below.")).toBeInTheDocument()
  })

  it("handles popstate, empty inbox, null topics, and storage failures without losing the Rails surface", async () => {
    const getItem = vi.spyOn(Storage.prototype, "getItem").mockImplementation(() => { throw new Error("blocked") })
    const setItem = vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => { throw new Error("quota") })
    const mounted = render(<ConversationWorkspace {...props()} />)
    await userEvent.setup().click(screen.getByRole("button", { name: "Insert check mark emoji" }))
    mounted.unmount()
    const empty = { ...props(null), inbox: [] }
    const emptyMounted = render(<ConversationWorkspace {...empty} />)
    expect(screen.getByText("You do not belong to any conversations yet.")).toBeInTheDocument()

    getItem.mockRestore()
    setItem.mockRestore()
    const design = thread("design-room", { topic: null })
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(props(design)))
    emptyMounted.rerender(<ConversationWorkspace {...props(null)} />)
    window.history.replaceState({}, "", "/admin/conversations/design-room")
    window.dispatchEvent(new PopStateEvent("popstate"))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(screen.getByText("Conversation")).toBeInTheDocument()
  })

  it("keeps ordinary link modifiers native and ignores an out-of-order navigation response", async () => {
    const user = userEvent.setup()
    const stale = deferredResponse()
    const designPayload = props(thread("design-room"))
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => stale.promise)
      .mockImplementationOnce(() => jsonResponse(designPayload))
    render(<ConversationWorkspace {...props(null)} />)
    const releaseLink = screen.getByRole("link", { name: /Release room/ })
    const modified = new MouseEvent("click", { bubbles: true, cancelable: true, metaKey: true })
    expect(releaseLink.dispatchEvent(modified)).toBe(true)
    expect(fetchMock).not.toHaveBeenCalled()

    await user.click(releaseLink)
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await act(async () => stale.resolve(await jsonResponse(props(thread()))))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
  })

  it("supports emoji, cancel, read/unread, and confirmed withdrawal actions", async () => {
    const user = userEvent.setup()
    const selected = thread()
    let canonicalThread = selected
    vi.spyOn(globalThis, "fetch").mockImplementation((input, options) => {
      if (options?.method === "DELETE" && String(input).includes("/messages/")) {
        const withdrawn = { ...message(2), body: "[withdrawn]", editable: false, withdrawn: true }
        canonicalThread = { ...selected, messages: [message(1), withdrawn] }
        return jsonResponse({ message: withdrawn, ok: true })
      }
      return options?.method && options.method !== "GET" ? jsonResponse({ ok: true }) : jsonResponse(props(canonicalThread))
    })
    const confirm = vi.spyOn(window, "confirm").mockReturnValueOnce(false).mockReturnValueOnce(true)
    render(<ConversationWorkspace {...props(selected)} />)

    await user.click(screen.getByRole("button", { name: "Insert check mark emoji" }))
    expect(screen.getByLabelText("Message as You")).toHaveValue("✅")
    await user.click(screen.getByRole("button", { name: "Edit" }))
    await user.click(screen.getByRole("button", { name: "Cancel" }))
    await user.click(screen.getAllByRole("button", { name: "Mark read through here" })[0])
    expect(await screen.findByText("Read position updated.")).toBeInTheDocument()
    await user.click(screen.getAllByRole("button", { name: "Mark unread from here" })[0])
    expect(await screen.findByText("Unread position updated.")).toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Withdraw" }))
    expect(confirm).toHaveBeenCalledTimes(1)
    await user.click(screen.getByRole("button", { name: "Withdraw" }))
    expect(await screen.findByText("[withdrawn]")).toBeInTheDocument()
  })

  it("isolates local drafts by authenticated membership namespace", async () => {
    const user = userEvent.setup()
    const memberA = thread("release-room", { draftNamespace: "member-a" })
    const memberB = thread("release-room", { draftNamespace: "member-b" })
    const first = render(<ConversationWorkspace {...props(memberA)} />)
    await user.type(screen.getByLabelText("Message as You"), "Only member A can resume this")
    first.unmount()

    const second = render(<ConversationWorkspace {...props(memberB)} />)
    expect(screen.getByLabelText("Message as You")).toHaveValue("")
    second.unmount()

    render(<ConversationWorkspace {...props(memberA)} />)
    expect(screen.getByLabelText("Message as You")).toHaveValue("Only member A can resume this")
  })

  it("clears success feedback when navigating to another conversation", async () => {
    const user = userEvent.setup()
    const selected = thread()
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ ok: true }))
      .mockImplementationOnce(() => jsonResponse(props(selected)))
      .mockImplementationOnce(() => jsonResponse(props(thread("design-room"))))
    render(<ConversationWorkspace {...props(selected)} />)

    await user.click(screen.getAllByRole("button", { name: "Mark read through here" })[0])
    expect(await screen.findByText("Read position updated.")).toBeInTheDocument()
    await waitFor(() => expect(globalThis.fetch).toHaveBeenCalledTimes(2))
    await user.click(screen.getByRole("link", { name: /Design room/ }))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(screen.queryByText("Read position updated.")).not.toBeInTheDocument()
  })

  it("announces a new message away from the scroll edge and jumps to it", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", {
        messages: [message(1), message(2), message(3)]
      }))))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", {
        messages: [message(1), message(2), message(3), message(4), message(5)]
      }))))
    render(<ConversationWorkspace {...props()} />)
    const list = screen.getByRole("list", { name: "Messages" })
    Object.defineProperties(list, {
      clientHeight: { configurable: true, value: 100 },
      scrollHeight: { configurable: true, value: 1000 },
      scrollTop: { configurable: true, value: 0, writable: true }
    })
    await act(async () => new Promise<void>(resolve => window.requestAnimationFrame(() => resolve())))
    list.scrollTop = 0

    await user.click(screen.getByRole("button", { name: "Refresh" }))
    const firstJump = await screen.findByRole("button", { name: /1 new message · Jump to newest/ })
    await user.click(firstJump)
    list.scrollTop = 0

    await user.click(screen.getByRole("button", { name: "Refresh" }))
    const jump = await screen.findByRole("button", { name: /2 new messages · Jump to newest/ })
    await user.click(jump)
    expect(screen.queryByRole("button", { name: /Jump to newest/ })).not.toBeInTheDocument()
  })

  it("surfaces unreadable server errors with a retryable navigation", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch").mockImplementation(() => Promise.resolve(new Response("not json", { status: 500 })))
    render(<ConversationWorkspace {...props(null)} />)

    await user.click(screen.getByRole("link", { name: /Design room/ }))

    expect(await screen.findByRole("alert")).toHaveTextContent("The server returned an unreadable response.")
    expect(screen.getByRole("button", { name: "Retry" })).toBeInTheDocument()
  })

  it("retries an active refresh failure without leaking stale state", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "Refresh failed" }, 503))
      .mockImplementationOnce(() => jsonResponse(props()))
    render(<ConversationWorkspace {...props()} />)

    await user.click(screen.getByRole("button", { name: "Refresh" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Refresh failed")
    await user.click(screen.getByRole("button", { name: "Retry" }))

    await waitFor(() => expect(screen.queryByRole("alert")).not.toBeInTheDocument())
  })

  it("retries an active older-history failure and preserves its cursor", async () => {
    const user = userEvent.setup()
    const initial = thread("release-room", { olderCursor: 1 })
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "History failed" }, 503))
      .mockImplementationOnce(() => jsonResponse(props(thread("release-room", { messages: [message(0, { publicId: "message-zero", sequence: 1 })], olderCursor: null }))))
    render(<ConversationWorkspace {...props(initial)} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("History failed")
    await user.click(screen.getByRole("button", { name: "Retry" }))

    await waitFor(() => expect(screen.queryByRole("button", { name: "Load 50 older messages" })).not.toBeInTheDocument())
  })

  it("covers bounded defensive request and empty-thread behavior", async () => {
    const user = userEvent.setup()
    const empty = thread("release-room", { messages: [] })
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: null }, 500))
      .mockImplementationOnce(() => jsonResponse(props(empty)))
    render(<ConversationWorkspace {...props(empty)} />)

    fireEvent.submit(screen.getByLabelText("Message as You").closest("form")!)
    expect(globalThis.fetch).not.toHaveBeenCalled()
    await user.click(screen.getByRole("button", { name: "Refresh" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("The conversation request failed.")
    await user.click(screen.getByRole("button", { name: "Retry" }))
    await waitFor(() => expect(screen.queryByRole("alert")).not.toBeInTheDocument())
  })

  it("uses an ampersand for a history URL that already has a query", async () => {
    const user = userEvent.setup()
    const initial = thread("release-room", {
      messagesUrl: "/admin/conversations/release-room/messages.json?scope=all",
      olderCursor: 2
    })
    const fetchMock = vi.spyOn(globalThis, "fetch").mockImplementation(() =>
      jsonResponse(props(thread("release-room", { messages: [message(1)], olderCursor: null }))))
    render(<ConversationWorkspace {...props(initial)} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))

    expect(fetchMock.mock.calls[0][0]).toContain("?scope=all&before=2")
  })

  it("does not leak an older-history response or mutation failure across thread navigation", async () => {
    const user = userEvent.setup()
    const history = deferredResponse()
    const mutation = deferredFailure()
    const designPayload = props(thread("design-room"))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => history.promise)
      .mockImplementationOnce(() => jsonResponse(designPayload))
      .mockImplementationOnce(() => mutation.promise)
      .mockImplementationOnce(() => jsonResponse(props()))
    render(<ConversationWorkspace {...props(thread("release-room", { olderCursor: 2 }))} />)

    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    await act(async () => history.resolve(await jsonResponse(props(thread("release-room", { messages: [message(1)], olderCursor: null })))))
    expect(screen.getByRole("heading", { name: "Design room" })).toBeInTheDocument()

    await user.type(screen.getByLabelText("Message as You"), "Design update")
    await user.click(screen.getByRole("button", { name: "Send message" }))
    await user.click(screen.getByRole("link", { name: /Release room/ }))
    await act(async () => mutation.reject(new Error("Old mutation failed")))
    expect(screen.queryByText("Old mutation failed")).not.toBeInTheDocument()
  })

  it("retains edit mode after a failed save and renders null inbox topics", async () => {
    const user = userEvent.setup()
    const input = props()
    input.inbox[0].topic = null
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse({ error: "Save failed" }, 422))
    render(<ConversationWorkspace {...input} />)

    expect(screen.getByText("No topic")).toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Edit" }))
    await user.click(screen.getByRole("button", { name: "Save" }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Save failed")
    expect(screen.getByLabelText("Edit message")).toBeInTheDocument()
  })

  it("loads the matching thread on browser history navigation", async () => {
    vi.spyOn(globalThis, "fetch").mockImplementation(() => jsonResponse(props(thread("design-room"))))
    render(<ConversationWorkspace {...props(null)} />)
    window.history.replaceState({}, "", "/admin/conversations/design-room")

    window.dispatchEvent(new PopStateEvent("popstate"))

    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
  })

  it("silently ignores an aborted navigation and history request", async () => {
    const user = userEvent.setup()
    const designPayload = props(thread("design-room"))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce((_input, options) => new Promise<Response>((_resolve, reject) => {
        options?.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
      }))
      .mockImplementationOnce(() => jsonResponse(designPayload))
      .mockImplementationOnce(() => Promise.reject(new DOMException("Aborted", "AbortError")))
    const mounted = render(<ConversationWorkspace {...props(thread("release-room", { olderCursor: 2 }))} />)

    await user.click(screen.getByRole("link", { name: /Release room/ }))
    await user.click(screen.getByRole("link", { name: /Design room/ }))
    expect(await screen.findByRole("heading", { name: "Design room" })).toBeInTheDocument()
    expect(screen.queryByRole("alert")).not.toBeInTheDocument()

    mounted.unmount()
    render(<ConversationWorkspace {...props(thread("release-room", { olderCursor: 2 }))} />)
    await user.click(screen.getByRole("button", { name: "Load 50 older messages" }))
    await waitFor(() => expect(screen.queryByRole("alert")).not.toBeInTheDocument())
  })
})
