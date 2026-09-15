// app/frontend/components/MessagePreviewCenter.test.tsx

import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"
import MessagePreviewCenter from "./MessagePreviewCenter"

const message = { attachments: [{ filename: "chart.png", id: 1, kind: "image" as const, size: 10, url: "/chart" }, { filename: "report.pdf", id: 2, kind: "pdf" as const, size: 20, url: "/pdf" }, { filename: "brief.docx", id: 3, kind: "download" as const, size: 20, url: "/doc" }, { filename: "huge.pdf", id: 4, kind: "oversized" as const, size: 9_000_000 }], htmlBody: "<h1>Safe</h1>", id: 1, recipient: "to@example.test", sender: "from@example.test", subject: "Report", textBody: "Plain report" }

describe("MessagePreviewCenter", () => {
  it("switches accessible body tabs and messages", async () => {
    const user = userEvent.setup(); const second = { ...message, id: 2, subject: "Second" }
    render(<MessagePreviewCenter messages={[message, second]} />)
    expect(screen.getByTitle("Sanitized email HTML")).toHaveAttribute("sandbox")
    await user.click(screen.getByRole("tab", { name: "Text" }))
    expect(screen.getByText("Plain report")).toBeVisible()
    await user.click(screen.getByRole("tab", { name: "HTML" }))
    expect(screen.getByTitle("Sanitized email HTML")).toBeVisible()
    await user.click(screen.getByRole("button", { name: /Second/ }))
    expect(screen.getByRole("heading", { name: "Second" })).toBeVisible()
  })

  it("previews image, PDF, and bounded document downloads", async () => {
    const user = userEvent.setup(); render(<MessagePreviewCenter messages={[message]} />)
    await user.click(screen.getByRole("button", { name: "Preview chart.png" })); expect(screen.getByAltText(/chart.png/)).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Preview report.pdf" })); expect(screen.getByTitle(/PDF preview/)).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Preview brief.docx" })); expect(screen.getByText(/downloaded rather than executed/)).toBeVisible()
    expect(screen.getByRole("button", { name: "Preview huge.pdf" })).toBeDisabled()
  })

  it("shows empty and missing states", async () => {
    const { rerender } = render(<MessagePreviewCenter messages={[]} />); expect(screen.getByText(/No development messages/)).toBeVisible()
    const missing = { ...message, attachments: [{ filename: "gone.pdf", id: 9, kind: "pdf" as const, size: 4 }] }
    rerender(<MessagePreviewCenter key="with-message" messages={[missing]} />)
    await userEvent.click(screen.getByRole("button", { name: "Preview gone.pdf" }))
    expect(screen.getByRole("alert")).toHaveTextContent("missing or unsupported")
  })
})
