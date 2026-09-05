// app/frontend/components/FoundationStatus.test.tsx

import { render, screen } from "@testing-library/react"

import FoundationStatus from "./FoundationStatus"

describe("FoundationStatus", () => {
  it("renders the Rails-owned operating metrics", () => {
    render(
      <FoundationStatus
        accountCount={6}
        activeUsers={1842}
        revenueCents={482_000_00}
        source="/projects/activeadmin-react"
      />
    )

    expect(screen.getByText("React island mounted")).not.toBeNull()
    expect(screen.getByText("6")).not.toBeNull()
    expect(screen.getByText("1,842")).not.toBeNull()
    expect(screen.getByText("$482,000")).not.toBeNull()
    expect(screen.getByText(/activeadmin-react/)).not.toBeNull()
  })
})
