// app/frontend/components/MasterDashboard.test.tsx

import { act, render, screen } from "@testing-library/react"

import MasterDashboard from "./MasterDashboard"
import { privacyEvent } from "./PrivacyMode"

const props = {
  groups: [{ label: "Operations", icon: "operations" as const, tools: [{ label: "Calendar Scheduler", description: "Coordinate work", url: "/admin/calendar_scheduler" }] }],
  metrics: [{ label: "Revenue", value: "$123,456" }],
  privacyEnabled: true
}

describe("MasterDashboard", () => {
  it("renders grouped native navigation and masks designated totals", () => {
    const { unmount } = render(<MasterDashboard {...props} />)
    expect(screen.getByRole("link", { name: /Calendar Scheduler/ })).toHaveAttribute("href", "/admin/calendar_scheduler")
    expect(screen.queryByText("$123,456")).not.toBeInTheDocument()
    expect(screen.getByTestId("private-metric")).toHaveTextContent("Hidden")
    act(() => document.dispatchEvent(new CustomEvent(privacyEvent, { detail: false })))
    expect(screen.getByTestId("private-metric")).toHaveTextContent("$123,456")
    expect(screen.getByRole("status")).toHaveTextContent("off")
    act(() => document.dispatchEvent(new CustomEvent(privacyEvent, { detail: true })))
    expect(screen.getByRole("status")).toHaveTextContent("on")
    unmount()
  })
})
