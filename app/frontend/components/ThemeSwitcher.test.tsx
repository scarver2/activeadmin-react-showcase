// app/frontend/components/ThemeSwitcher.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ThemeSwitcher from "./ThemeSwitcher"

const themes = [
  { label: "Classic Neutral", value: "v3" },
  { label: "Limestone & Ink", value: "v3_texas" },
  { label: "Slate & Copper", value: "v3_slate" }
]

describe("ThemeSwitcher", () => {
  beforeEach(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="theme-token">'
    vi.restoreAllMocks()
  })

  function renderSwitcher() {
    return render(<div data-showcase-theme-marker="v3"><ThemeSwitcher currentTheme="v3" themes={themes} updateUrl="/admin/theme-preference" /></div>)
  }

  it.each(["v3_texas", "v3_slate"])("optimistically applies and persists palette %s", async (palette) => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ theme: palette }), { status: 200 }))
    const { container } = renderSwitcher()

    fireEvent.change(screen.getByLabelText("Color palette"), { target: { value: palette } })

    expect(container.firstElementChild).toHaveAttribute("data-showcase-theme-marker", palette)
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("/admin/theme-preference", expect.objectContaining({
      body: JSON.stringify({ theme_preference: palette }),
      headers: expect.objectContaining({ "X-CSRF-Token": "theme-token" }),
      method: "PATCH"
    })))
  })

  it("rolls back the visual state when Rails rejects the preference", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ error: "Theme is not allowed" }), { status: 422 }))
    const { container } = renderSwitcher()

    fireEvent.change(screen.getByLabelText("Color palette"), { target: { value: "v3_texas" } })

    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Theme is not allowed"))
    expect(screen.getByLabelText("Color palette")).toHaveValue("v3")
    expect(container.firstElementChild).toHaveAttribute("data-showcase-theme-marker", "v3")
  })

  it("fails safely when optional page context and an error message are unavailable", async () => {
    document.head.innerHTML = ""
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response("{}", { status: 500 }))
    render(<ThemeSwitcher currentTheme="v3" themes={themes} updateUrl="/admin/theme-preference" />)

    fireEvent.change(screen.getByLabelText("Color palette"), { target: { value: "v3_texas" } })

    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Palette preference could not be saved"))
    expect(fetchMock).toHaveBeenCalledWith("/admin/theme-preference", expect.objectContaining({
      headers: expect.objectContaining({ "X-CSRF-Token": "" })
    }))
    expect(screen.getByLabelText("Color palette")).toHaveValue("v3")
  })
})
