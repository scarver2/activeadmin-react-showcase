// app/frontend/components/ThemeSwitcher.test.tsx

import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ThemeSwitcher from "./ThemeSwitcher"

const themes = [
  { label: "V3 Classic", value: "v3" },
  { label: "Texas Bluebonnet", value: "v3_texas" }
]

describe("ThemeSwitcher", () => {
  beforeEach(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="theme-token">'
    vi.restoreAllMocks()
  })

  function renderSwitcher() {
    return render(<div data-showcase-theme-marker="v3"><ThemeSwitcher currentTheme="v3" themes={themes} updateUrl="/admin/theme-preference" /></div>)
  }

  it("optimistically applies and persists a selected theme", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ theme: "v3_texas" }), { status: 200 }))
    const { container } = renderSwitcher()

    fireEvent.change(screen.getByLabelText("Visual theme"), { target: { value: "v3_texas" } })

    expect(container.firstElementChild).toHaveAttribute("data-showcase-theme-marker", "v3_texas")
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith("/admin/theme-preference", expect.objectContaining({
      body: JSON.stringify({ theme_preference: "v3_texas" }),
      headers: expect.objectContaining({ "X-CSRF-Token": "theme-token" }),
      method: "PATCH"
    })))
  })

  it("rolls back the visual state when Rails rejects the preference", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify({ error: "Theme is not allowed" }), { status: 422 }))
    const { container } = renderSwitcher()

    fireEvent.change(screen.getByLabelText("Visual theme"), { target: { value: "v3_texas" } })

    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Theme is not allowed"))
    expect(screen.getByLabelText("Visual theme")).toHaveValue("v3")
    expect(container.firstElementChild).toHaveAttribute("data-showcase-theme-marker", "v3")
  })

  it("fails safely when optional page context and an error message are unavailable", async () => {
    document.head.innerHTML = ""
    const fetchMock = vi.spyOn(globalThis, "fetch").mockResolvedValue(new Response("{}", { status: 500 }))
    render(<ThemeSwitcher currentTheme="v3" themes={themes} updateUrl="/admin/theme-preference" />)

    fireEvent.change(screen.getByLabelText("Visual theme"), { target: { value: "v3_texas" } })

    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Theme preference could not be saved"))
    expect(fetchMock).toHaveBeenCalledWith("/admin/theme-preference", expect.objectContaining({
      headers: expect.objectContaining({ "X-CSRF-Token": "" })
    }))
    expect(screen.getByLabelText("Visual theme")).toHaveValue("v3")
  })
})
