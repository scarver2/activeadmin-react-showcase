// app/frontend/components/FoundationStatus.test.tsx

import { act, render, screen } from "@testing-library/react"

import FoundationStatus from "./FoundationStatus"
import { privacyEvent } from "./PrivacyMode"

describe("FoundationStatus", () => {
  it("renders the Rails-owned operating metrics", () => {
    render(
      <FoundationStatus
        accountCount={6}
        activeUsers={1842}
        privacyEnabled={false}
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

  it("masks only the designated home-dashboard totals and responds to the global presentation state", () => {
    render(<FoundationStatus accountCount={6} activeUsers={1842} privacyEnabled revenueCents={482_000_00} source="test" />)

    expect(screen.getAllByTestId("private-metric").map(node => node.textContent)).toEqual(["Hidden", "Hidden", "Hidden"])
    act(() => document.dispatchEvent(new CustomEvent(privacyEvent, { detail: false })))
    expect(screen.getAllByTestId("private-metric").map(node => node.textContent)).toEqual(["6", "1,842", "$482,000"])
  })
})
