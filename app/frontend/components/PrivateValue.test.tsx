// app/frontend/components/PrivateValue.test.tsx

import { render, screen } from "@testing-library/react"

import PrivateValue, { privacyPlaceholder } from "./PrivateValue"

describe("PrivateValue", () => {
  it("marks the value semantically and provides one accessible placeholder", () => {
    const { container } = render(<PrivateValue category="financial">$482,000</PrivateValue>)

    expect(container.querySelector('[data-private="financial"]')).toBeTruthy()
    expect(screen.getByText("$482,000")).toHaveClass("privacy-value-content")
    expect(screen.getByText(privacyPlaceholder)).toHaveAttribute("aria-hidden", "true")
    expect(screen.getByText("Private value concealed")).toHaveClass("sr-only")
  })
})
