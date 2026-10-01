// app/frontend/components/ThemeStudio.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"

import ThemeStudio, { type ThemeStudioProps } from "./ThemeStudio"

const props: ThemeStudioProps = {
  architecture: {
    activeAdminRequirement: ">= 4.0.0.beta22, < 5",
    composition: {
      description: "Compact operator-focused hierarchy.",
      key: "v3",
      name: "ActiveAdmin V3",
      parts: ["foundation/base", "components/navigation"],
      slots: {}
    },
    recipeVersion: "2",
    skin: {
      description: "Restrained semantic palette.",
      key: "v3",
      name: "ActiveAdmin V3",
      parts: ["foundation/tokens"]
    },
    theme: { key: "v3", name: "ActiveAdmin V3" }
  },
  colors: [
    { dark: "#171c21", key: "background", label: "Canvas", light: "#f3f4f5" },
    { dark: "#71808d", key: "border", label: "Border", light: "#87929c" },
    { dark: "#10171d", key: "chrome", label: "Chrome", light: "#42494f" },
    { dark: "#ffffff", key: "chrome_text", label: "Chrome text", light: "#ffffff" },
    { dark: "#ffc1b8", key: "danger", label: "Danger", light: "#932419" },
    { dark: "#4a2525", key: "danger_bg", label: "Danger surface", light: "#fff0ee" },
    { dark: "#f3cf79", key: "focus", label: "Focus", light: "#175eac" },
    { dark: "#a7d1f3", key: "link", label: "Link", light: "#38678b" },
    { dark: "#bdc7d0", key: "muted", label: "Muted text", light: "#535d65" },
    { dark: "#354d60", key: "selected", label: "Selection", light: "#d9e4ec" },
    { dark: "#2d3740", key: "subtle", label: "Subtle surface", light: "#eef0f2" },
    { dark: "#b5e5c0", key: "success", label: "Success", light: "#245c34" },
    { dark: "#223e2b", key: "success_bg", label: "Success surface", light: "#edf7ef" },
    { dark: "#222a31", key: "surface", label: "Surface", light: "#ffffff" },
    { dark: "#edf0f2", key: "text", label: "Text", light: "#323537" },
    { dark: "#f6d892", key: "warning", label: "Warning", light: "#754600" },
    { dark: "#44381f", key: "warning_bg", label: "Warning surface", light: "#fff5dc" }
  ],
  geometry: [
    { key: "border_width", label: "Border weight", value: "1px" },
    { key: "control_height", label: "Control height", value: "2.25rem" },
    { key: "page_gutter", label: "Page gutter", value: "1.875rem" },
    { key: "radius", label: "Radius", value: "0.25rem" }
  ],
  typography: [
    { key: "font", label: "Font family", value: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif' },
    { key: "line_height", label: "Line height", value: "1.5" },
    { key: "text_size", label: "Base text size", value: "0.875rem" }
  ]
}

describe("ThemeStudio", () => {
  it("exercises each preview, geometry and typography option without submitting data", () => {
    render(<ThemeStudio {...props} />)
    fireEvent.change(screen.getByLabelText("Surface", { exact: true }), { target: { value: "dashboard" } })
    expect(screen.getByText("Monthly volume")).toBeVisible()
    fireEvent.change(screen.getByLabelText("Surface", { exact: true }), { target: { value: "detail" } })
    expect(screen.getByText("Avery Morgan")).toBeVisible()
    fireEvent.change(screen.getByLabelText("Surface", { exact: true }), { target: { value: "form" } })
    fireEvent.submit(screen.getByRole("button", { name: "Save account" }).closest("form")!)
    fireEvent.click(screen.getByRole("link", { name: "Dashboard" }))
    fireEvent.click(screen.getByRole("link", { name: "Accounts" }))
    fireEvent.click(screen.getByRole("button", { name: "tablet" }))
    fireEvent.click(screen.getByRole("button", { name: "narrow" }))
    fireEvent.change(screen.getByLabelText("Font family"), { target: { value: 'ui-serif, Georgia, "Times New Roman", serif' } })
    fireEvent.change(screen.getByLabelText("Control height"), { target: { value: "3rem" } })
    expect(screen.getByText(/meets 44px studio target/)).toBeVisible()
    fireEvent.change(screen.getByLabelText("Text light"), { target: { value: "#f3f4f5" } })
    expect(screen.getAllByText(/below 4.5:1 target/).length).toBeGreaterThan(0)
    fireEvent.change(screen.getByLabelText("Focus light"), { target: { value: "#f3f4f5" } })
    expect(screen.getByText(/below 3:1 target/)).toBeVisible()
    fireEvent.change(screen.getByLabelText("Canvas light"), { target: { value: "#000000" } })
    expect(screen.getByTestId("recipe-proposal")).toHaveTextContent('background: "#000000"')
  })
  it("makes the theme, skin and immutable composition boundary explicit", () => {
    render(<ThemeStudio {...props} />)

    expect(screen.getByRole("heading", { name: "ActiveAdmin V3 semantic editor" })).toBeVisible()
    expect(screen.getByText(/Theme = the ActiveAdmin V3 composition plus the ActiveAdmin V3 skin/)).toBeVisible()
    expect(screen.getByText(/declares no interchangeable V3 layout candidates/)).toBeVisible()
    expect(screen.getByTestId("recipe-proposal")).toHaveTextContent("foundation/tokens")
    expect(screen.getByTestId("recipe-proposal")).toHaveTextContent("components/navigation")
  })

  it("edits light and dark tokens independently and resets deterministic state", () => {
    render(<ThemeStudio {...props} />)

    fireEvent.change(screen.getByLabelText("Canvas light"), { target: { value: "#ffffff" } })
    expect(screen.getByTestId("recipe-proposal")).toHaveTextContent('background: "#ffffff"')

    fireEvent.click(screen.getByRole("button", { name: "dark" }))
    expect(screen.getByLabelText("Canvas dark")).toHaveValue("#171c21")
    fireEvent.click(screen.getByRole("button", { name: "Reset" }))
    fireEvent.click(screen.getByRole("button", { name: "light" }))
    expect(screen.getByLabelText("Canvas light")).toHaveValue("#f3f4f5")
  })

  it("switches representative surfaces and reports bounded accessibility checks", () => {
    render(<ThemeStudio {...props} />)

    fireEvent.change(screen.getByLabelText("Surface"), { target: { value: "form" } })
    expect(screen.getByRole("heading", { name: "Edit account" })).toBeVisible()
    expect(screen.getByText(/Automated contrast and size checks/)).toBeVisible()
    expect(screen.getByText(/All 17 roles have light and dark values/)).toBeVisible()
    expect(screen.getByText(/consider at least 44px/)).toBeVisible()
  })
})
