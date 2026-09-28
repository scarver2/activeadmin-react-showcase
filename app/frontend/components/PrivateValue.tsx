// app/frontend/components/PrivateValue.tsx

import type { ReactNode } from "react"

export const privacyPlaceholder = "••••"

export default function PrivateValue({
  category = "financial",
  children,
  className
}: {
  category?: string
  children: ReactNode
  className?: string
}) {
  return (
    <span className={className} data-private={category}>
      <span className="privacy-value-content">{children}</span>
      <span className="privacy-value-placeholder">
        <span aria-hidden="true">{privacyPlaceholder}</span>
        <span className="sr-only">Private value concealed</span>
      </span>
    </span>
  )
}
