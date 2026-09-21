// app/frontend/components/MasterDashboard.test.tsx

import { render, screen } from "@testing-library/react"

import MasterDashboard from "./MasterDashboard"

const props = {
  groups: [{ label: "Operations", icon: "settings" as const, tools: [{ label: "Calendar Scheduler", description: "Coordinate work", url: "/admin/calendar_scheduler" }] }],
  metrics: [{ label: "Revenue", value: "$123,456" }]
}

describe("MasterDashboard", () => {
  it("renders grouped native navigation and the operating picture", () => {
    render(<MasterDashboard {...props} />)
    expect(screen.getByRole("link", { name: /Calendar Scheduler/ })).toHaveAttribute("href", "/admin/calendar_scheduler")
    expect(screen.getByText("$123,456")).toBeInTheDocument()
    expect(document.querySelector('use[href="/showcase-icons.svg#heroicons-cog-6-tooth"]')).toBeInTheDocument()
  })
})
