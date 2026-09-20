// app/frontend/components/ThemeIcon.test.tsx
import { render, screen } from "@testing-library/react"

import ThemeIcon from "./ThemeIcon"

describe("ThemeIcon", () => {
  it("keeps functional icons decorative and labels authoritative", () => {
    const { container } = render(<button><ThemeIcon name="records" />Records</button>)
    expect(screen.getByRole("button", { name: "Records" })).toBeTruthy()
    expect(container.querySelector("svg")).toHaveAttribute("aria-hidden", "true")
    expect(container.querySelector("svg")).toHaveAttribute("focusable", "false")
    expect(container.querySelector("use")).toHaveAttribute("href", "/showcase-icons.svg#records")
    expect(container.querySelectorAll("use")).toHaveLength(1)
  })
  it("offers a sparse landmark variant without owning theme state", () => {
    const { container } = render(<ThemeIcon name="dashboard" landmark />)
    expect(container.querySelector(".showcase-icon-default")).toHaveAttribute("href", "/showcase-icons.svg#dashboard")
    expect(container.querySelector(".showcase-icon-landmark")).toHaveAttribute("href", "/showcase-icons.svg#landmark")
  })
})
