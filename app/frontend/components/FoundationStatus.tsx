// app/frontend/components/FoundationStatus.tsx

import { type ReactNode, useEffect, useState } from "react"

import { privacyEvent } from "./PrivacyMode"
import ThemeIcon from "./ThemeIcon"

type FoundationStatusProps = {
  accountCount: number
  activeUsers: number
  privacyEnabled: boolean
  revenueCents: number
  source: string
}

function formatCurrency(cents: number) {
  return new Intl.NumberFormat("en-US", {
    currency: "USD",
    maximumFractionDigits: 0,
    style: "currency"
  }).format(cents / 100)
}

export default function FoundationStatus({
  accountCount,
  activeUsers,
  privacyEnabled,
  revenueCents,
  source
}: FoundationStatusProps) {
  const [masked, setMasked] = useState(privacyEnabled)

  useEffect(() => {
    const update = (event: Event) => setMasked((event as CustomEvent<boolean>).detail)
    document.addEventListener(privacyEvent, update)
    return () => document.removeEventListener(privacyEvent, update)
  }, [])

  const value = (visible: ReactNode) => masked ? "Hidden" : visible

  return (
    <section
      aria-labelledby="foundation-status-heading"
      className="showcase-icon-metrics rounded-lg border p-6 shadow-sm"
      data-testid="foundation-status"
    >
      <p className="text-sm font-semibold uppercase tracking-wide text-indigo-600">React island mounted</p>
      <h2 className="mt-2 text-2xl font-bold text-gray-900 dark:text-white" id="foundation-status-heading">
        Today&apos;s seeded operating picture
      </h2>
      <dl className="mt-6 grid gap-4 sm:grid-cols-3">
        <div>
          <dt className="text-sm"><ThemeIcon name="records" />Accounts</dt>
          <dd className="foundation-private-value text-3xl font-semibold" data-testid="private-metric">{value(accountCount)}</dd>
        </div>
        <div>
          <dt className="text-sm"><ThemeIcon name="people" />Active users</dt>
          <dd className="foundation-private-value text-3xl font-semibold" data-testid="private-metric">{value(activeUsers.toLocaleString("en-US"))}</dd>
        </div>
        <div>
          <dt className="text-sm"><ThemeIcon name="reports" />Monthly revenue</dt>
          <dd className="foundation-private-value text-3xl font-semibold" data-testid="private-metric">{value(formatCurrency(revenueCents))}</dd>
        </div>
      </dl>
      <p className="mt-3 text-xs" role="status">
        {masked ? "Privacy Mode is on — dashboard totals are hidden." : "Privacy Mode is off — dashboard totals are visible."}
        {" "}<span className="text-gray-500">Presentation only; not access control.</span>
      </p>
      <p className="mt-6 break-all text-xs text-gray-500">Runtime source: {source}</p>
    </section>
  )
}
