// app/frontend/components/MasterDashboard.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"

import MasterDashboard from "./MasterDashboard"

const props = {
  groups: [{
    label: "Operations",
    icon: "settings" as const,
    state: "Stable",
    stateTone: "stable" as const,
    summary: "Scheduled work is inside its operating envelope.",
    whyItMatters: "Stable execution protects downstream promises.",
    updatedAt: "just now",
    indicators: [{ label: "Calendar", value: "7d", icon: "calendar" as const }],
    tools: [
      { label: "Calendar Scheduler", description: "Coordinate work", icon: "calendar" as const, url: "/admin/calendar_scheduler" },
      { label: "Live Jobs", description: "Inspect progress", icon: "settings" as const, url: "/admin/live_jobs" }
    ]
  }],
  metrics: [{ label: "Revenue pulse", value: "$123,456", detail: "synthetic month to date", icon: "reports" as const }]
}

describe("MasterDashboard", () => {
  it("keeps the resting surface terse and icon-first", () => {
    render(<MasterDashboard {...props} />)

    expect(screen.getByRole("button", { name: /Operations: Stable/ })).toHaveAttribute("aria-expanded", "false")
    expect(screen.getByText("$123,456")).toBeInTheDocument()
    expect(screen.getByText(/Focus, hover, or tap a domain/)).toBeInTheDocument()
    expect(screen.queryByText("Stable execution protects downstream promises.")).not.toBeInTheDocument()
    expect(document.querySelector('use[href="/showcase-icons.svg#heroicons-cog-6-tooth"]')).toBeInTheDocument()
    expect(document.querySelector('use[href="/showcase-icons.svg#heroicons-calendar-days"]')).toBeInTheDocument()
  })

  it("reveals explanation and Rails-owned actions on hover or keyboard focus", () => {
    render(<MasterDashboard {...props} />)
    const trigger = screen.getByRole("button", { name: /Operations: Stable/ })

    fireEvent.mouseEnter(trigger)
    expect(trigger).toHaveAttribute("aria-expanded", "true")
    expect(screen.getByText("Stable execution protects downstream promises.")).toBeInTheDocument()
    expect(screen.getByRole("link", { name: /Calendar Scheduler/ })).toHaveAttribute("href", "/admin/calendar_scheduler")

    fireEvent.mouseLeave(trigger)
    expect(screen.queryByText("Stable execution protects downstream promises.")).not.toBeInTheDocument()
    fireEvent.focus(trigger)
    expect(screen.getByText("Stable execution protects downstream promises.")).toBeInTheDocument()
  })

  it("supports touch-equivalent pin and close behavior", () => {
    render(<MasterDashboard {...props} />)
    const trigger = screen.getByRole("button", { name: /Operations: Stable/ })

    fireEvent.click(trigger)
    fireEvent.mouseLeave(trigger)
    expect(screen.getByRole("button", { name: /Operations: Stable.*pinned/ })).toHaveAttribute("aria-expanded", "true")
    fireEvent.click(screen.getByRole("button", { name: /Operations: Stable.*pinned/ }))
    expect(screen.queryByText("Stable execution protects downstream promises.")).not.toBeInTheDocument()
    fireEvent.click(screen.getByRole("button", { name: /Operations: Stable/ }))
    fireEvent.click(screen.getByRole("button", { name: "Close domain details" }))
    expect(screen.queryByText("Stable execution protects downstream promises.")).not.toBeInTheDocument()
  })

  it("clears a keyboard preview only when focus leaves the dashboard", () => {
    render(<MasterDashboard {...props} />)
    const dashboard = screen.getByRole("main")
    const trigger = screen.getByRole("button", { name: /Operations: Stable/ })

    fireEvent.focus(trigger)
    fireEvent.blur(dashboard, { relatedTarget: trigger })
    expect(screen.getByText("Stable execution protects downstream promises.")).toBeInTheDocument()
    fireEvent.blur(dashboard, { relatedTarget: document.body })
    expect(screen.queryByText("Stable execution protects downstream promises.")).not.toBeInTheDocument()
  })
})
