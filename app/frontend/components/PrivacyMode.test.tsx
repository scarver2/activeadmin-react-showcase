// app/frontend/components/PrivacyMode.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"

import PrivacyMode, { privacyEvent } from "./PrivacyMode"

describe("PrivacyMode", () => {
  afterEach(() => vi.restoreAllMocks())

  it("masks immediately, persists with CSRF and prevents overlapping requests", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="privacy-token">'
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue({ ok: true } as Response)
    const listener = vi.fn()
    document.addEventListener(privacyEvent, listener)
    render(<PrivacyMode endpoint="/admin/privacy-mode" initialEnabled={false} />)
    fireEvent.click(screen.getByRole("button"))
    expect(screen.getByRole("button")).toHaveAttribute("aria-pressed", "true")
    expect(screen.getByRole("button")).toBeDisabled()
    expect(listener).toHaveBeenCalledOnce()
    await waitFor(() => expect(screen.getByRole("button")).not.toBeDisabled())
    expect(fetchMock).toHaveBeenCalledWith("/admin/privacy-mode", expect.objectContaining({ method: "PATCH", body: '{"enabled":true}', headers: expect.objectContaining({ "X-CSRF-Token": "privacy-token" }) }))
    document.removeEventListener(privacyEvent, listener)
  })

  it.each([false, "network"])("restores the prior state on failure %s", async (failure) => {
    document.head.innerHTML = ""
    vi.spyOn(globalThis, "fetch").mockImplementation(() => failure === false ? Promise.resolve({ ok: false } as Response) : Promise.reject(new Error("offline")))
    render(<PrivacyMode endpoint="/admin/privacy-mode" initialEnabled={true} />)
    fireEvent.click(screen.getByRole("button"))
    expect(await screen.findByRole("alert")).toHaveTextContent("Masking stays on here")
    expect(screen.getByRole("button")).toHaveAttribute("aria-pressed", "true")
  })
})
