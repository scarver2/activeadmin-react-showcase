// app/frontend/components/AuditHistory.test.tsx

import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"
import AuditHistory from "./AuditHistory"

const history = [{ actor: "Avery", at: "2026-09-12T12:00:00Z", changes: { name: { from: "Old", to: "New" }, preferences: { from: { alerts: [] }, to: { alerts: ["sms"] } } }, event: "update", id: 1 }]
afterEach(() => vi.restoreAllMocks())

describe("AuditHistory", () => {
  it("renders immutable complex field diffs and filters", async () => {
    const user = userEvent.setup(); render(<AuditHistory history={history} name="Profile" previewUrl="/preview" />)
    expect(screen.getByText("Old")).toBeVisible()
    expect(screen.getByText(/sms/)).toBeVisible()
    await user.selectOptions(screen.getByLabelText("Changed field"), "name")
    expect(screen.getByText("Old")).toBeVisible()
  })

  it("loads a paper_trail_diff restoration preview", async () => {
    const user = userEvent.setup(); vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ preview: { attributes: { name: { from: "Old", to: "New" } } } }), { status: 200 }))
    render(<AuditHistory history={history} name="Profile" previewUrl="/preview" />)
    await user.click(screen.getByRole("button", { name: /Preview restoration/ }))
    expect(await screen.findByText(/no changes applied/)).toBeVisible()
  })

  it("shows empty and error states", async () => {
    const user = userEvent.setup(); const { rerender } = render(<AuditHistory history={[]} name="Empty" previewUrl="/preview" />)
    expect(screen.getByText("No matching history.")).toBeVisible()
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ error: "History unavailable" }), { status: 422 }))
    rerender(<AuditHistory history={history} name="Profile" previewUrl="/preview" />)
    await user.click(screen.getByRole("button", { name: /Preview restoration/ }))
    expect(await screen.findByRole("alert")).toHaveTextContent("History unavailable")
  })

  it("uses a stable fallback for malformed error responses", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({}), { status: 500 }))
    render(<AuditHistory history={history} name="Profile" previewUrl="/preview" />)
    await userEvent.click(screen.getByRole("button", { name: /Preview restoration/ }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Preview could not be loaded")
  })
})
