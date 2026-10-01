// app/frontend/components/ActivityTimeline.test.tsx

import { fireEvent, render, screen } from "@testing-library/react"

import ActivityTimeline, { type ActivityTimelineProps } from "./ActivityTimeline"

const props: ActivityTimelineProps = {
  families: { comment: "Comments" }, filters: { group: "day" },
  items: [{ actor: "Avery", details: { Comment: "Synthetic context" }, family: "comment", id: "comment-0000", occurredAt: "2026-10-01T12:00:00Z", sourceUrl: "/admin/activity_timeline?source=comment-0000", state: "available", summary: "Comment added" },
    { actor: "Unavailable", details: {}, family: "comment", id: "comment-0001", occurredAt: "2026-10-01T11:00:00Z", sourceUrl: null, state: "redacted", summary: "Source redacted — details unavailable" }],
  nextUrl: "/admin/activity_timeline?cursor=signed", pageSize: 25, startUrl: "/admin/activity_timeline"
}

describe("ActivityTimeline", () => {
  it("keeps context collapsed until requested and preserves native source/paging links", () => {
    render(<ActivityTimeline {...props} />)
    const context = screen.getByRole("button", { name: "Context for comment-0000" })
    expect(context).toHaveAttribute("aria-expanded", "false")
    expect(screen.getByText("Synthetic context")).not.toBeVisible()
    fireEvent.click(context)
    expect(screen.getByText("Synthetic context")).toBeVisible()
    expect(context).toHaveAttribute("aria-expanded", "true")
    fireEvent.click(context)
    expect(screen.getByText("Synthetic context")).not.toBeVisible()
    expect(screen.getByRole("link", { name: "Older events" })).toHaveAttribute("href", props.nextUrl)
    expect(screen.getByRole("link", { name: "Open source comment-0000" })).toHaveAttribute("href", props.items[0].sourceUrl)
    expect(screen.queryByRole("button", { name: /comment-0001/ })).not.toBeInTheDocument()
    expect(screen.getByRole("heading", { name: "2026-10-01" })).toBeVisible()
  })

  it("groups by family or actor without reordering events inside groups", () => {
    const { rerender } = render(<ActivityTimeline {...props} filters={{ group: "family" }} />)
    expect(screen.getByRole("heading", { name: "Comments" })).toBeVisible()
    rerender(<ActivityTimeline {...props} filters={{ group: "actor" }} />)
    expect(screen.getByRole("heading", { name: "Avery" })).toBeVisible()
    expect(screen.getByRole("heading", { name: "Unavailable" })).toBeVisible()
  })

  it("announces empty results and does not offer a nonexistent next page", () => {
    render(<ActivityTimeline {...props} items={[]} nextUrl={null} />)
    expect(screen.getByRole("status")).toHaveTextContent("No events match")
    expect(screen.queryByRole("link", { name: "Older events" })).not.toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Newest events" })).toBeVisible()
  })
})
