// app/frontend/components/PrivacyView.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"

import PrivacyView from "./PrivacyView"

describe("PrivacyView", () => {
  afterEach(() => {
    document.documentElement.removeAttribute("data-privacy-view")
    vi.restoreAllMocks()
  })

  it("publishes global shell state, persists with CSRF and prevents overlapping requests", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="privacy-token">'
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue({ ok: true } as Response)
    render(<PrivacyView endpoint="/admin/privacy-view" initialEnabled={false} />)

    const toggle = screen.getByRole("switch", { name: /Privacy View Off/ })
    expect(document.documentElement).toHaveAttribute("data-privacy-view", "off")
    fireEvent.click(toggle)

    expect(screen.getByRole("switch", { name: /Privacy View On/ })).toHaveAttribute("aria-checked", "true")
    expect(screen.getByRole("switch")).toBeDisabled()
    expect(document.documentElement).toHaveAttribute("data-privacy-view", "on")
    await waitFor(() => expect(screen.getByRole("switch")).not.toBeDisabled())
    expect(fetchMock).toHaveBeenCalledWith("/admin/privacy-view", expect.objectContaining({
      body: '{"enabled":true}',
      headers: expect.objectContaining({ "X-CSRF-Token": "privacy-token" }),
      method: "PATCH"
    }))
  })

  it.each([[false, true], [false, false], ["network", true], ["network", false]] as const)("keeps concealment on after save failure %s from enabled=%s", async (failure, initialEnabled) => {
    document.head.innerHTML = ""
    vi.spyOn(globalThis, "fetch").mockImplementation(() => failure === false ? Promise.resolve({ ok: false } as Response) : Promise.reject(new Error("offline")))
    render(<PrivacyView endpoint="/admin/privacy-view" initialEnabled={initialEnabled} />)
    fireEvent.click(screen.getByRole("switch"))

    expect(await screen.findByRole("alert")).toHaveTextContent("Concealment stays on here")
    expect(screen.getByRole("switch")).toHaveAttribute("aria-checked", "true")
    expect(document.documentElement).toHaveAttribute("data-privacy-view", "on")
  })
})
