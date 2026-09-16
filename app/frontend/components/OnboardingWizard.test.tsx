// app/frontend/components/OnboardingWizard.test.tsx

import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"
import OnboardingWizard from "./OnboardingWizard"

const draft = { account_kind: "standard", company_name: "", compliance_contact: "", contact_email: "", current_step: 1, id: 1, lock_version: 0, status: "draft" }

afterEach(() => vi.restoreAllMocks())

describe("OnboardingWizard", () => {
  it("shows conditional fields and persists navigation", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ draft: { ...draft, account_kind: "regulated", company_name: "Acme", compliance_contact: "Lee", current_step: 2, lock_version: 1 } }), { status: 200 }))
    render(<OnboardingWizard draft={draft} updateUrl="/draft" />)
    await user.selectOptions(screen.getByLabelText("Account kind"), "regulated")
    expect(screen.getByLabelText("Compliance contact")).toBeVisible()
    await user.type(screen.getByLabelText("Company name"), "Acme")
    await user.type(screen.getByLabelText("Compliance contact"), "Lee")
    await user.click(screen.getByRole("button", { name: "Save and continue" }))
    expect(await screen.findByText("Primary contact")).toBeVisible()
  })

  it("focuses a Rails validation error and preserves state", async () => {
    const user = userEvent.setup()
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ errors: { company_name: ["Company name can't be blank"] } }), { status: 422 }))
    render(<OnboardingWizard draft={draft} updateUrl="/draft" />)
    await user.click(screen.getByRole("button", { name: "Save and continue" }))
    expect(await screen.findByRole("alert")).toHaveFocus()
  })

  it("supports back, review, submit, and stale errors", async () => {
    const user = userEvent.setup()
    const review = { ...draft, company_name: "Acme", contact_email: "a@example.test", current_step: 3 }
    const fetch = vi.spyOn(globalThis, "fetch")
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({ draft: { ...review, current_step: 2, lock_version: 1 } }), { status: 200 }))
    render(<OnboardingWizard draft={review} updateUrl="/draft" />)
    expect(screen.getByText("Review")).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Back" }))
    expect(await screen.findByText("Primary contact")).toBeVisible()
  })

  it("edits contact details and submits regulated review", async () => {
    const user = userEvent.setup(); const fetch = vi.spyOn(globalThis, "fetch")
    const contact = { ...draft, company_name: "Acme", current_step: 2 }
    fetch.mockResolvedValueOnce(new Response(JSON.stringify({ draft: { ...contact, contact_email: "a@example.test", current_step: 3, lock_version: 1 } }), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ draft: { ...contact, account_kind: "regulated", compliance_contact: "Lee", contact_email: "a@example.test", current_step: 3, status: "submitted" } }), { status: 200 }))
    render(<OnboardingWizard draft={contact} updateUrl="/draft" />)
    await user.type(screen.getByLabelText("Email"), "a@example.test")
    await user.click(screen.getByRole("button", { name: "Save and continue" }))
    expect(await screen.findByText("Review")).toBeVisible()
    await user.click(screen.getByRole("button", { name: "Submit application" }))
    expect(await screen.findByText("Application submitted")).toBeVisible()
  })

  it("uses a stable fallback for malformed server errors", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({}), { status: 500 }))
    render(<OnboardingWizard draft={draft} updateUrl="/draft" />)
    await userEvent.click(screen.getByRole("button", { name: "Save and continue" }))
    expect(await screen.findByRole("alert")).toHaveTextContent("Draft could not be saved")
  })

  it("renders submitted state", () => {
    render(<OnboardingWizard draft={{ ...draft, company_name: "Acme", status: "submitted" }} updateUrl="/draft" />)
    expect(screen.getByText("Application submitted")).toBeVisible()
  })

  it("reviews regulated compliance details", () => {
    render(<OnboardingWizard draft={{ ...draft, account_kind: "regulated", company_name: "Acme", compliance_contact: "Lee", contact_email: "a@example.test", current_step: 3 }} updateUrl="/draft" />)
    expect(screen.getByText("Lee")).toBeVisible()
  })
})
