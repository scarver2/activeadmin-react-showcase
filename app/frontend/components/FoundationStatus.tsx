// app/frontend/components/FoundationStatus.tsx

import ThemeIcon from "./ThemeIcon"

type FoundationStatusProps = {
  accountCount: number
  activeUsers: number
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
  revenueCents,
  source
}: FoundationStatusProps) {
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
          <dd className="text-3xl font-semibold">{accountCount}</dd>
        </div>
        <div>
          <dt className="text-sm"><ThemeIcon name="people" />Active users</dt>
          <dd className="text-3xl font-semibold">{activeUsers.toLocaleString("en-US")}</dd>
        </div>
        <div>
          <dt className="text-sm"><ThemeIcon name="reports" />Monthly revenue</dt>
          <dd className="text-3xl font-semibold">{formatCurrency(revenueCents)}</dd>
        </div>
      </dl>
      <p className="mt-6 break-all text-xs text-gray-500">Runtime source: {source}</p>
    </section>
  )
}
