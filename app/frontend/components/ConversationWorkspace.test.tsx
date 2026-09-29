// app/frontend/components/ConversationWorkspace.test.tsx

import { act, fireEvent, render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"

import ConversationWorkspace, {
  type ConversationMessage,
  type ConversationThread,
  type ConversationWorkspaceProps
} from "./ConversationWorkspace"

function message(sequence: number, overrides: Partial<ConversationMessage> = {}): ConversationMessage {
  return {
    authorName: sequence % 2 ? "Release Lead" : "You",
    body: `Message ${sequence}`,
    createdAt: "2026-09-28T12:00:00Z",
    editable: sequence % 2 === 0,
    edited: false,
    editUrl: `/admin/conversations/release-room/messages/message-${sequence}.json`,
    markReadUrl: `/admin/conversations/release-room/read-state/message-${sequence}.json`,
    markUnreadUrl: `/admin/conversations/release-room/read-state/message-${sequence}.json`,
    own: sequence % 2 === 0,
    publicId: `message-${sequence}`,
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
    publicId,
    scheduledMessagesUrl: `/admin/conversations/${publicId}/scheduled_messages`,
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
      { lastActivityAt: "2026-09-28T12:00:00Z", messagesUrl: "/admin/conversations/release-room/messages.json", publicId: "release-room", showUrl: "/admin/conversations/release-room", title: "Release room", topic: "Coordinate the release", unreadCount: 1 },
      { lastActivityAt: "2026-09-28T11:00:00Z", messagesUrl: "/admin/conversations/design-room/messages.json", publicId: "design-room", showUrl: "/admin/conversations/design-room", title: "Design room", topic: "Polish the workspace", unreadCount: 0 }
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
    expect(screen.getByRole("button", { name: "Insert check mark emoji" })).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Scheduled messages" })).toHaveAttribute(
      "href",
      "/admin/conversations/release-room/scheduled_messages"
    )
    expect(screen.getByRole("link", { name: "Saved messages" })).toHaveAttribute("href", "/admin/conversations/saved")
    expect(document.querySelector('use[href="/showcase-icons.svg#heroicons-users"]')).toBeInTheDocument()
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
    expect(screen.getByRole("status")).toHaveTextContent("Message saved.")

    await user.click(remove)
    expect(await screen.findByRole("button", { name: "Save message" })).toHaveAttribute("aria-pressed", "false")
    expect(screen.getByRole("status")).toHaveTextContent("Message removed from saved messages.")
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

  it("keeps a failed-send draft and retries through the original Send action without duplicate-state ambiguity", async () => {
    const user = userEvent.setup()
    const latest = props(thread("release-room", { messages: [message(1), message(2), message(3)] }))
    vi.spyOn(globalThis, "fetch")
      .mockImplementationOnce(() => jsonResponse({ error: "Try again" }, 503))
      .mockImplementationOnce(() => jsonResponse({ message: message(3), ok: true }))
      .mockImplementationOnce(() => jsonResponse(latest))
    render(<ConversationWorkspace {...props()} />)
    const composer = screen.getByLabelText("Message as You")

    await user.type(composer, "Retry safely")
    await user.click(screen.getByRole("button", { name: "Send message" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Try again")
    expect(screen.queryByRole("button", { name: "Retry" })).not.toBeInTheDocument()
    expect(composer).toHaveValue("Retry safely")

    await user.click(screen.getByRole("button", { name: "Send message" }))
    await waitFor(() => expect(composer).toHaveValue(""))
    expect(window.localStorage.getItem("showcase:conversation-draft:release-room-member:release-room")).toBeNull()
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
