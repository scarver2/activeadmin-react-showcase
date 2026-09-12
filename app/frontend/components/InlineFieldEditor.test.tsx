// app/frontend/components/InlineFieldEditor.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import InlineFieldEditor from "./InlineFieldEditor"

const props = { endpoint: "/admin/inline-edit/accounts/1", field: "status" as const, label: "Status for Bluebonnet", lockVersion: 0, options: ["active", "trial"], value: "active" }

describe("InlineFieldEditor", () => {
  beforeEach(() => { vi.clearAllMocks(); vi.stubGlobal("fetch", vi.fn()) })

  it("activates by keyboard, focuses the editor, and cancels with Escape", async () => {
    render(<InlineFieldEditor {...props} />)
    screen.getByRole("button", { name: "Edit Status for Bluebonnet" }).focus()
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    const select = screen.getByLabelText("Status for Bluebonnet")
    await waitFor(() => expect(document.activeElement).toBe(select))
    fireEvent.change(select, { target: { value: "trial" } })
    fireEvent.keyDown(select, { key: "Escape" })
    await waitFor(() => expect(document.activeElement).toBe(screen.getByRole("button", { name: "Edit Status for Bluebonnet" })))
    expect(screen.getByText("active")).not.toBeNull()
  })

  it("optimistically saves with Enter and accepts canonical Rails state", async () => {
    let resolve!: (response: Response) => void
    vi.mocked(fetch).mockReturnValue(new Promise((done) => { resolve = done }))
    render(<InlineFieldEditor {...props} />)
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    const select = screen.getByLabelText("Status for Bluebonnet")
    fireEvent.change(select, { target: { value: "trial" } })
    fireEvent.keyDown(select, { key: "Enter" })
    expect(screen.getByText("Saving…")).not.toBeNull()
    fireEvent.blur(select)
    expect(screen.getByLabelText("Status for Bluebonnet")).not.toBeNull()
    resolve(new Response(JSON.stringify({ id: 1, lockVersion: 1, region: "Central", status: "trial" }), { status: 200 }))
    expect(await screen.findByRole("button", { name: "Edit Status for Bluebonnet" })).toHaveTextContent("trial")
    expect(fetch).toHaveBeenCalledWith(props.endpoint, expect.objectContaining({ body: JSON.stringify({ field: "status", lock_version: 0, value: "trial" }), method: "PATCH" }))
  })

  it("saves by button and cancels by button or blur", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ id: 1, lockVersion: 1, region: "Central", status: "trial" }), { status: 200 }))
    render(<InlineFieldEditor {...props} />)
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    fireEvent.change(screen.getByLabelText("Status for Bluebonnet"), { target: { value: "trial" } })
    fireEvent.mouseDown(screen.getByRole("button", { name: "Save" }))
    fireEvent.click(screen.getByRole("button", { name: "Save" }))
    expect(await screen.findByRole("button", { name: "Edit Status for Bluebonnet" })).toHaveTextContent("trial")
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    fireEvent.mouseDown(screen.getByRole("button", { name: "Cancel" }))
    fireEvent.click(screen.getByRole("button", { name: "Cancel" }))
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    fireEvent.blur(screen.getByLabelText("Status for Bluebonnet"))
    expect(screen.getByRole("button", { name: "Edit Status for Bluebonnet" })).not.toBeNull()
  })

  it("rolls back server rejection and network failure", async () => {
    vi.mocked(fetch).mockResolvedValueOnce(new Response(JSON.stringify({ error: "Denied" }), { status: 403 }))
      .mockRejectedValueOnce(new Error("Offline"))
    render(<InlineFieldEditor {...props} />)
    for (const message of ["Denied", "Offline"]) {
      fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
      fireEvent.change(screen.getByLabelText("Status for Bluebonnet"), { target: { value: "trial" } })
      fireEvent.keyDown(screen.getByLabelText("Status for Bluebonnet"), { key: "Enter" })
      expect(await screen.findByRole("alert")).toHaveTextContent(message)
      expect(screen.getByRole("button", { name: "Edit Status for Bluebonnet" })).toHaveTextContent("active")
    }
  })

  it("restores canonical state and lock after a stale response", async () => {
    vi.mocked(fetch).mockResolvedValueOnce(new Response(JSON.stringify({ error: "This account changed elsewhere; the canonical value was restored", account: { id: 1, lockVersion: 3, region: "Central", status: "trial" } }), { status: 409 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ id: 1, lockVersion: 4, region: "Central", status: "active" }), { status: 200 }))
    render(<InlineFieldEditor {...props} />)
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    fireEvent.change(screen.getByLabelText("Status for Bluebonnet"), { target: { value: "trial" } })
    fireEvent.keyDown(screen.getByLabelText("Status for Bluebonnet"), { key: "Enter" })
    expect(await screen.findByRole("alert")).toHaveTextContent("changed elsewhere")
    expect(screen.getByRole("button", { name: "Edit Status for Bluebonnet" })).toHaveTextContent("trial")
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    fireEvent.change(screen.getByLabelText("Status for Bluebonnet"), { target: { value: "active" } })
    fireEvent.keyDown(screen.getByLabelText("Status for Bluebonnet"), { key: "Enter" })
    await waitFor(() => expect(fetch).toHaveBeenLastCalledWith(props.endpoint, expect.objectContaining({ body: expect.stringContaining('"lock_version":3') })))
  })

  it("uses a generic rejection message", async () => {
    vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({}), { status: 500 }))
    render(<InlineFieldEditor {...props} />)
    fireEvent.click(screen.getByRole("button", { name: "Edit Status for Bluebonnet" }))
    fireEvent.keyDown(screen.getByLabelText("Status for Bluebonnet"), { key: "Enter" })
    expect(await screen.findByRole("alert")).toHaveTextContent("Inline update failed")
  })
})
