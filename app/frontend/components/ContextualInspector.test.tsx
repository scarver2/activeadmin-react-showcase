// app/frontend/components/ContextualInspector.test.tsx

import { createRef } from "react"
import { fireEvent, render, screen, waitFor } from "@testing-library/react"

import ContextualInspector from "./ContextualInspector"

const details = <nav aria-label="Account actions"><a href="/admin/accounts/1">View full account</a><a href="/admin/accounts/1/edit">Edit account</a></nav>

describe("ContextualInspector", () => {
  it("renders caller-owned content inside the reusable inspector shell", () => {
    render(<ContextualInspector error={null} errorActionHref="/admin/accounts/1" errorActionLabel="Open account" eyebrow="Account context" loading={false} onClose={vi.fn()} returnFocus={createRef()} title="Bluebonnet">{details}</ContextualInspector>)

    expect(screen.getByRole("dialog", { name: "Bluebonnet" })).toBeVisible()
    expect(screen.getByRole("navigation", { name: "Account actions" })).toBeVisible()
    expect(screen.getByText("Account context")).toBeVisible()
  })

  it("traps focus, invokes close on Escape, and restores the originating control", async () => {
    const trigger = document.createElement("button")
    document.body.append(trigger)
    const returnFocus = { current: trigger }
    const onClose = vi.fn()
    const { unmount } = render(<ContextualInspector error={null} errorActionHref="/admin/accounts/1" errorActionLabel="Open account" eyebrow="Account context" loading={false} onClose={onClose} returnFocus={returnFocus} title="Bluebonnet">{details}</ContextualInspector>)
    const dialog = screen.getByRole("dialog")
    const close = screen.getByRole("button", { name: "Close account inspector" })
    const lastAction = screen.getByRole("link", { name: "Edit account" })

    expect(close).toHaveFocus()
    fireEvent.keyDown(dialog, { key: "Enter" })
    expect(close).toHaveFocus()
    screen.getByRole("link", { name: "View full account" }).focus()
    fireEvent.keyDown(dialog, { key: "Tab" })
    expect(screen.getByRole("link", { name: "View full account" })).toHaveFocus()
    lastAction.focus()
    fireEvent.keyDown(dialog, { key: "Tab" })
    expect(close).toHaveFocus()
    fireEvent.keyDown(dialog, { key: "Tab", shiftKey: true })
    expect(lastAction).toHaveFocus()
    fireEvent.keyDown(dialog, { key: "Escape" })
    expect(onClose).toHaveBeenCalledOnce()

    unmount()
    await waitFor(() => expect(trigger).toHaveFocus())
    trigger.remove()
  })

  it("renders loading, error, empty-observation, and empty-payload states", () => {
    const { rerender } = render(<ContextualInspector error={null} errorActionHref="/admin/accounts/1" errorActionLabel="Open account" eyebrow="Account context" loading onClose={vi.fn()} returnFocus={createRef()} title="Bluebonnet">{details}</ContextualInspector>)
    expect(screen.getByRole("status")).toHaveTextContent("Loading account context")

    rerender(<ContextualInspector error="Account context failed" errorActionHref="/admin/accounts" errorActionLabel="Return to accounts" eyebrow="Account context" loading={false} onClose={vi.fn()} returnFocus={createRef()} title="Bluebonnet">{details}</ContextualInspector>)
    expect(screen.getByRole("alert")).toHaveTextContent("Account context failed")
    expect(screen.getByRole("link", { name: "Return to accounts" })).toHaveAttribute("href", "/admin/accounts")

    rerender(<ContextualInspector error={null} errorActionHref="/admin/accounts/1" errorActionLabel="Open account" eyebrow="Account context" loading={false} onClose={vi.fn()} returnFocus={createRef()} title="Bluebonnet">{null}</ContextualInspector>)
    expect(screen.queryByRole("status")).not.toBeInTheDocument()
  })
})
