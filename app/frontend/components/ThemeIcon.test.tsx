// app/frontend/components/ThemeIcon.test.tsx
import { render, screen } from "@testing-library/react"

import registry from "../icons/registry.json"
import ThemeIcon, { type ThemeIconName } from "./ThemeIcon"

describe("ThemeIcon", () => {
  it("keeps functional icons decorative and labels authoritative", () => {
    const { container } = render(<button><ThemeIcon name="records" />Records</button>)
    expect(screen.getByRole("button", { name: "Records" })).toBeTruthy()
    expect(container.querySelector("svg")).toHaveAttribute("aria-hidden", "true")
    expect(container.querySelector("svg")).toHaveAttribute("focusable", "false")
    expect(container.querySelector("use")).toHaveAttribute("href", "/showcase-icons.svg#heroicons-document-text")
    expect(container.querySelectorAll("use")).toHaveLength(1)
  })
  it("offers a sparse landmark variant without owning theme state", () => {
    const { container } = render(<ThemeIcon name="dashboard" landmark />)
    expect(container.querySelector(".showcase-icon-default")).toHaveAttribute("href", "/showcase-icons.svg#heroicons-squares-2x2")
    expect(container.querySelector(".showcase-icon-landmark")).toHaveAttribute("href", "/showcase-icons.svg#landmark")
  })
  it.each(Object.keys(registry) as ThemeIconName[])("resolves the shared %s semantic entry", (name) => {
    const { container } = render(<ThemeIcon name={name} />)
    expect(container.querySelector("use")).toHaveAttribute("href", `/showcase-icons.svg#${registry[name].symbol}`)
  })
  it("leaves icon-only naming with the owning control", () => {
    render(<button aria-label="Open navigation"><ThemeIcon name="navigation" /></button>)
    expect(screen.getByRole("button", { name: "Open navigation" })).toBeVisible()
    expect(screen.queryByRole("img")).not.toBeInTheDocument()
  })
})
