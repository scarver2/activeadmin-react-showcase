// app/frontend/components/ThemeStudioExtraPreviews.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"

import ThemeStudioExtraPreviews from "./ThemeStudioExtraPreviews"

describe("ThemeStudioExtraPreviews", () => {
  it("filters fictional data and preserves local selection across filtering", () => {
    render(<ThemeStudioExtraPreviews surface="dense" />)
    expect(screen.getByRole("status")).toHaveTextContent("4 accounts shown · 0 selected")
    const select = screen.getByLabelText("Select Bluebonnet Logistics")
    fireEvent.click(select)
    expect(select.closest("tr")).toHaveStyle({ backgroundColor: "var(--aat-selected)" })
    fireEvent.change(screen.getByLabelText("Filter preview accounts"), { target: { value: "  juniper " } })
    expect(screen.getByRole("status")).toHaveTextContent("1 account shown · 1 selected")
    fireEvent.change(screen.getByLabelText("Filter preview accounts"), { target: { value: "missing" } })
    expect(screen.getByText(/No preview accounts match/)).toBeVisible()
    fireEvent.change(screen.getByLabelText("Filter preview accounts"), { target: { value: "" } })
    expect(screen.getByLabelText("Select Bluebonnet Logistics")).toBeChecked()
    fireEvent.click(screen.getByLabelText("Select Bluebonnet Logistics"))
    expect(screen.getByRole("status")).toHaveTextContent("4 accounts shown · 0 selected")
  })

  it("offers a login feedback fixture without editable credentials or requests", () => {
    render(<ThemeStudioExtraPreviews surface="login" />)
    expect(screen.getByLabelText("Preview email")).toHaveAttribute("readonly")
    expect(screen.getByLabelText("Preview password")).toHaveAttribute("readonly")
    expect(screen.getByRole("status")).toHaveTextContent("Example error state")
    fireEvent.submit(screen.getByRole("form", { name: "Login preview" }))
    expect(screen.getByRole("status")).toHaveTextContent("no request sent and no session created")
  })
})
