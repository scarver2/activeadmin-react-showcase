// app/frontend/components/KanbanWorkflow.test.tsx

import { fireEvent, render, screen, waitFor, within } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import KanbanWorkflow from "./KanbanWorkflow"
import type { WorkflowItem } from "./KanbanWorkflow"

const backlog: WorkflowItem = { id: 1, title: "Backlog card", context: "Context", state: "backlog", position: 0, moveUrl: "/admin/workflow-items/1/move" }
const ready: WorkflowItem = { id: 2, title: "Ready card", context: null, state: "ready", position: 0, moveUrl: "/admin/workflow-items/2/move" }
const canonical = { ...backlog, state: "ready" as const, position: 1 }

describe("KanbanWorkflow", () => {
  beforeEach(() => vi.stubGlobal("fetch", vi.fn()))

  it("renders persisted columns, cards, guidance, and accessible move controls", () => {
    render(<KanbanWorkflow items={[backlog, ready]} />)

    expect(screen.getByRole("region", { name: "Backlog workflow column" })).toHaveTextContent("Backlog card")
    expect(screen.getByRole("region", { name: "Ready workflow column" })).toHaveTextContent("Ready card")
    expect(screen.getByText("Ruby")).not.toBeNull()
    expect(screen.getByText("JavaScript")).not.toBeNull()
    expect(screen.getByText("Architecture")).not.toBeNull()
  })

  it("optimistically moves forward and reconciles canonical server state", async () => {
    const fetchMock = vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ items: [ready, canonical] }), { status: 200 }))
    render(<KanbanWorkflow items={[backlog, ready]} />)

    fireEvent.click(screen.getByRole("button", { name: "Move Backlog card to Ready" }))
    expect(screen.getByRole("region", { name: "Ready workflow column" })).toHaveTextContent("Backlog card")
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(backlog.moveUrl, expect.objectContaining({
      body: JSON.stringify({ state: "ready", position: 1 }), method: "PATCH"
    })))
  })

  it("moves backward and restores the board with an explicit server error", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ error: "Transition denied" }), { status: 422 }))
    render(<KanbanWorkflow items={[backlog, ready]} />)

    fireEvent.click(screen.getByRole("button", { name: "Move Ready card to Backlog" }))

    expect(await screen.findByRole("alert")).toHaveTextContent("Transition denied. The board was restored.")
    expect(screen.getByRole("region", { name: "Ready workflow column" })).toHaveTextContent("Ready card")
  })

  it("uses a generic rollback error and ignores a drop without a known item", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({}), { status: 500 }))
    render(<KanbanWorkflow items={[backlog, ready]} />)

    fireEvent.click(screen.getByRole("button", { name: "Move Backlog card to Ready" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Workflow move failed. The board was restored.")

    const readyColumn = screen.getByRole("region", { name: "Ready workflow column" })
    fireEvent.dragOver(readyColumn)
    fireEvent.drop(readyColumn, { dataTransfer: { getData: () => "999" } })
    expect(fetch).toHaveBeenCalledTimes(1)
  })

  it("proposes a drag-and-drop move using the item identifier", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ items: [ready, canonical] }), { status: 200 }))
    render(<KanbanWorkflow items={[backlog, ready]} />)
    const card = screen.getByText("Backlog card").closest("li")!
    const transfer = { value: "", setData(_type: string, value: string) { this.value = value }, getData() { return this.value } }

    fireEvent.dragStart(card, { dataTransfer: transfer })
    fireEvent.drop(screen.getByRole("region", { name: "Ready workflow column" }), { dataTransfer: transfer })

    await waitFor(() => expect(within(screen.getByRole("region", { name: "Ready workflow column" })).getByText("Backlog card")).not.toBeNull())
  })
})
