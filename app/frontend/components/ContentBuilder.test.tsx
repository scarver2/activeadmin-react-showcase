// app/frontend/components/ContentBuilder.test.tsx

import { act, render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

const dnd = vi.hoisted(() => ({ end: null as Function | null }))
vi.mock("@dnd-kit/core", () => ({ DndContext: ({ children, onDragEnd }: { children: React.ReactNode, onDragEnd: Function }) => { dnd.end = onDragEnd; return children } }))
vi.mock("@dnd-kit/sortable", async () => {
  const actual = await vi.importActual<typeof import("@dnd-kit/sortable")>("@dnd-kit/sortable")
  return { ...actual, SortableContext: ({ children }: { children: React.ReactNode }) => children, useSortable: () => ({ attributes: {}, listeners: {}, setNodeRef: vi.fn(), transform: null, transition: undefined }) }
})

import ContentBuilder from "./ContentBuilder"

const blocks = [{ body: "Welcome", id: "1", type: "heading" as const }, { body: "Details", id: "2", type: "paragraph" as const }, { body: "Notice", id: "3", type: "callout" as const }]
const documentFixture = { blocks, id: "1", lockVersion: 0, title: "Brief", updateUrl: "/documents/1" }
const response = (body: object, ok = true) => Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)

afterEach(() => { globalThis.document.head.innerHTML = ""; vi.restoreAllMocks() })

describe("ContentBuilder", () => {
  it("adds, selects, edits, keyboard-reorders, removes, and previews blocks", async () => {
    vi.spyOn(globalThis.crypto, "randomUUID")
      .mockReturnValueOnce("00000000-0000-4000-8000-000000000001")
      .mockReturnValueOnce("00000000-0000-4000-8000-000000000002")
      .mockReturnValueOnce("00000000-0000-4000-8000-000000000003")
    const user = userEvent.setup()
    render(<ContentBuilder document={documentFixture} />)
    await user.click(screen.getByRole("button", { name: "Add paragraph" }))
    await user.click(screen.getByRole("button", { name: "Add heading" }))
    await user.click(screen.getByRole("button", { name: "Remove New heading" }))
    await user.click(screen.getByRole("button", { name: "Add callout" }))
    await user.click(screen.getByRole("button", { name: "Remove New callout" }))
    await user.click(screen.getByRole("button", { name: "New paragraph" }))
    await user.clear(screen.getByRole("textbox", { name: "Content" }))
    await user.type(screen.getByRole("textbox", { name: "Content" }), "Fresh copy")
    expect(screen.getByRole("region", { name: "Live preview" })).toHaveTextContent("Fresh copy")
    await user.click(screen.getByRole("button", { name: "Move Fresh copy up" }))
    await user.click(screen.getByRole("button", { name: "Remove Fresh copy" }))
    expect(screen.getByText("Select a block to edit it.")).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Details" }))
    await user.click(screen.getByRole("button", { name: "Remove Notice" }))
    await user.click(screen.getByRole("button", { name: "Move Details up" }))
    await user.click(screen.getByRole("button", { name: "Move Welcome down" }))
    expect(screen.getByRole("list", { name: "Content blocks" }).textContent?.indexOf("Details")).toBeLessThan(screen.getByRole("list", { name: "Content blocks" }).textContent!.indexOf("Welcome"))
  })

  it("saves the proposal and accepts canonical blocks", async () => {
    const canonical = { ...documentFixture, blocks: [{ body: "Canonical", id: "9", type: "callout" as const }], lockVersion: 1 }
    const fetchMock = vi.spyOn(globalThis, "fetch").mockReturnValue(response({ document: canonical }))
    globalThis.document.head.innerHTML = '<meta name="csrf-token" content="token">'
    render(<ContentBuilder document={documentFixture} />)
    await userEvent.click(screen.getByRole("button", { name: "Save document" }))
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("/documents/1", expect.objectContaining({ method: "PATCH" })))
    expect((await screen.findAllByText("Canonical"))[0]).toBeVisible()
  })

  it("accepts a canonical empty document", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValue(response({ document: { ...documentFixture, blocks: [], lockVersion: 1 } }))
    render(<ContentBuilder document={documentFixture} />)
    await userEvent.click(screen.getByRole("button", { name: "Save document" }))
    expect(await screen.findByText("Select a block to edit it.")).toBeVisible()
  })

  it("starts with no selection when the canonical document is empty", () => {
    render(<ContentBuilder document={{ ...documentFixture, blocks: [] }} />)
    expect(screen.getByText("Select a block to edit it.")).toBeVisible()
  })

  it("rolls back explicit and default save failures", async () => {
    vi.spyOn(globalThis, "fetch").mockReturnValueOnce(response({ error: "Stale" }, false)).mockReturnValueOnce(response({}, false))
    const { rerender } = render(<ContentBuilder document={documentFixture} />)
    await userEvent.click(screen.getByRole("button", { name: "Remove Welcome" }))
    await userEvent.click(screen.getByRole("button", { name: "Save document" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Stale. Unsaved changes were rolled back")
    expect(screen.getAllByText("Welcome")[0]).toBeVisible()
    rerender(<ContentBuilder document={{ ...documentFixture, id: "2", updateUrl: "/documents/2" }} />)
    await userEvent.click(screen.getByRole("button", { name: "Save document" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Document could not be saved")
  })

  it("handles dnd movement and no-op drops", () => {
    render(<ContentBuilder document={documentFixture} />)
    act(() => dnd.end!({ active: { id: "1" }, over: { id: "2" } }))
    expect(screen.getByRole("list", { name: "Content blocks" }).textContent?.indexOf("Details")).toBeLessThan(screen.getByRole("list", { name: "Content blocks" }).textContent!.indexOf("Welcome"))
    act(() => dnd.end!({ active: { id: "1" }, over: null }))
    act(() => dnd.end!({ active: { id: "1" }, over: { id: "1" } }))
  })
})
