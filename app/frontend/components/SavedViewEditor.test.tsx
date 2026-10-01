// app/frontend/components/SavedViewEditor.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import SavedViewEditor from "./SavedViewEditor"

describe("SavedViewEditor", () => {
  it("edits canonical named form fields and announces the proposed definition", () => {
    const { container } = render(<SavedViewEditor columns={["name", "plan", "region"]} definition={{ schema: 1, query: "", plan: "", status: "", sort: "name", direction: "asc", per_page: 5, columns: ["name", "plan"], group: "none", density: "comfortable" }} plans={["growth"]} statuses={["active"]} />)
    fireEvent.change(screen.getByLabelText("Search name"), { target: { value: "Acme" } })
    expect(screen.getByLabelText("Search name")).toHaveValue("Acme")
    fireEvent.change(screen.getByLabelText("density"), { target: { value: "compact" } })
    fireEvent.click(screen.getByLabelText("region"))
    expect(screen.getByText(/3 columns · compact/)).toBeVisible()
    fireEvent.click(screen.getByLabelText("plan", { selector: "input" }))
    expect(screen.getByText(/2 columns · compact/)).toBeVisible()
    expect(container.querySelector('input[name="saved_view[definition][schema]"]')).toHaveValue("1")
    expect(container.querySelector('input[value="name"]')).toHaveAttribute("type", "hidden")
  })
})
