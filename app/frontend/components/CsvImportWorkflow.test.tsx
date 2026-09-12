// app/frontend/components/CsvImportWorkflow.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import CsvImportWorkflow from "./CsvImportWorkflow"
import type { CsvImportState } from "./CsvImportWorkflow"

const cable = vi.hoisted(() => {
  let handlers: Record<string, (...args: unknown[]) => void> = {}
  const unsubscribe = vi.fn()
  return { connect: vi.fn(), disconnect: vi.fn(), handlers: () => handlers, unsubscribe,
    subscriptions: { create: vi.fn((_id, callbacks) => { handlers = callbacks; queueMicrotask(() => callbacks.connected()); return { unsubscribe } }) } }
})
vi.mock("@rails/actioncable", () => ({ createConsumer: () => cable }))

const draft: CsvImportState = {
  errors: [], failedRows: 0, importedRows: 0, mappings: {}, processedRows: 0, rowCount: 2, status: "draft", token: "token-1",
  preview: { headers: ["given", "family", "mail", "company"], rowCount: 2, rows: [{ given: "Ada", family: "Lovelace", mail: "ada@example.test", company: "Bluebonnet Logistics" }] }
}
const props = { createUrl: "/admin/csv-imports", initialImport: null }

describe("CsvImportWorkflow", () => {
  beforeEach(() => { vi.clearAllMocks(); vi.stubGlobal("fetch", vi.fn()); vi.spyOn(window, "confirm").mockReturnValue(true) })

  it("uploads a file and displays bounded preview and mappings", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(draft), { status: 201 }))
    render(<CsvImportWorkflow {...props} />)
    const file = new File(["given,family,mail,company\nAda,Lovelace,ada@example.test,Bluebonnet Logistics"], "contacts.csv", { type: "text/csv" })
    fireEvent.change(screen.getByLabelText("Synthetic CSV file"), { target: { files: [file] } })
    fireEvent.submit(screen.getByRole("button", { name: "Upload and preview" }).closest("form")!)
    expect(await screen.findByText("Preview 2 rows")).not.toBeNull()
    expect(screen.getByText("Ada")).not.toBeNull()
    expect(fetch).toHaveBeenCalledWith(props.createUrl, expect.objectContaining({ body: expect.any(FormData), method: "POST" }))
  })

  it("maps and explicitly confirms before subscribing to progress", async () => {
    const queued = { ...draft, preview: undefined, status: "queued" }
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify(queued), { status: 200 }))
    const { rerender } = render(<CsvImportWorkflow {...props} initialImport={draft} />)
    const values = ["first_name", "last_name", "email", "account"]
    draft.preview!.headers.forEach((header, index) => fireEvent.change(screen.getByLabelText(`Map ${header}`), { target: { value: values[index] } }))
    fireEvent.click(screen.getByRole("button", { name: "Confirm import" }))
    expect(await screen.findByText("Import queued")).not.toBeNull()
    expect(window.confirm).toHaveBeenCalledWith("Import 2 synthetic rows?")
    rerender(<CsvImportWorkflow {...props} initialImport={queued} />)
    await waitFor(() => expect(cable.subscriptions.create).toHaveBeenCalled())
  })

  it("cancels confirmation without a request", () => {
    vi.mocked(window.confirm).mockReturnValue(false)
    render(<CsvImportWorkflow {...props} initialImport={draft} />)
    fireEvent.click(screen.getByRole("button", { name: "Confirm import" }))
    expect(fetch).not.toHaveBeenCalled()
  })

  it("applies progress, row errors, disconnect, rejection, and cleanup", async () => {
    const queued = { ...draft, preview: undefined, rowCount: 0, status: "queued" }
    const { unmount } = render(<CsvImportWorkflow {...props} initialImport={queued} />)
    await waitFor(() => expect(screen.getByTestId("csv-cable-status")).toHaveTextContent("connected"))
    act(() => cable.handlers().received({ type: "progress", import: { ...queued, errors: ["Row 2 invalid"], failedRows: 1, processedRows: 2, status: "completed" } }))
    expect(screen.getByText("Row 2 invalid")).not.toBeNull()
    act(() => cable.handlers().disconnected())
    expect(screen.getByTestId("csv-cable-status")).toHaveTextContent("disconnected")
    act(() => cable.handlers().rejected())
    expect(screen.getByRole("alert")).toHaveTextContent("Progress stream was not authorized")
    unmount()
    expect(cable.unsubscribe).toHaveBeenCalled()
  })

  it("reports server and network upload failures", async () => {
    vi.mocked(fetch).mockResolvedValueOnce(new Response(JSON.stringify({ error: "Malformed CSV" }), { status: 422 }))
      .mockRejectedValueOnce(new Error("Offline"))
    render(<CsvImportWorkflow {...props} />)
    const form = screen.getByRole("button", { name: "Upload and preview" }).closest("form")!
    fireEvent.submit(form)
    expect(await screen.findByRole("alert")).toHaveTextContent("Malformed CSV")
    fireEvent.submit(form)
    expect(await screen.findByRole("alert")).toHaveTextContent("Offline")
  })

  it("reports generic upload and confirmation failures", async () => {
    vi.mocked(fetch).mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({}), { status: 500 }))
      .mockRejectedValueOnce(new Error("Confirmation offline"))
    const { unmount } = render(<CsvImportWorkflow {...props} />)
    fireEvent.submit(screen.getByRole("button", { name: "Upload and preview" }).closest("form")!)
    expect(await screen.findByRole("alert")).toHaveTextContent("CSV upload failed")
    unmount()
    render(<CsvImportWorkflow {...props} initialImport={draft} />)
    fireEvent.click(screen.getByRole("button", { name: "Confirm import" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Import confirmation failed")
    fireEvent.click(screen.getByRole("button", { name: "Confirm import" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Confirmation offline")
  })
})
