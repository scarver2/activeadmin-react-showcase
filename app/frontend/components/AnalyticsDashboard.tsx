// app/frontend/components/AnalyticsDashboard.tsx

import { FormEvent, ReactElement, useCallback, useEffect, useRef, useState } from "react"
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  LineChart,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from "recharts"

export type AnalyticsData = {
  accounts: Array<{ activeUsers: number; name: string; revenueCents: number }>
  kpis: { activeUsers: number; errorRate: number; p95Ms: number; revenueCents: number }
  plans: Array<{ name: string; value: number }>
  range: { endDate: string; startDate: string }
  series: Array<{ activeUsers: number; date: string; requestCount: number; revenueCents: number }>
}

export type AnalyticsDashboardProps = {
  endpoint: string
  initialEndDate: string
  initialStartDate: string
}

const CHART_COLORS = ["#4f46e5", "#0891b2", "#d97706"]
const REQUEST_TIMEOUT_MS = 8_000

function currency(cents: number) {
  return new Intl.NumberFormat("en-US", {
    currency: "USD",
    maximumFractionDigits: 0,
    style: "currency"
  }).format(cents / 100)
}

export default function AnalyticsDashboard({
  endpoint,
  initialEndDate,
  initialStartDate
}: AnalyticsDashboardProps) {
  const activeRequest = useRef<AbortController | null>(null)
  const [data, setData] = useState<AnalyticsData | null>(null)
  const [endDate, setEndDate] = useState(initialEndDate)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [startDate, setStartDate] = useState(initialStartDate)

  const load = useCallback(async (from: string, to: string) => {
    const controller = new AbortController()
    const timeout = window.setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)

    activeRequest.current = controller
    setError(null)
    setLoading(true)

    try {
      const query = new URLSearchParams({ end_date: to, start_date: from })
      const response = await fetch(`${endpoint}?${query}`, {
        headers: { Accept: "application/json" },
        signal: controller.signal
      })
      const body = await response.json()

      if (!response.ok) throw new Error(body.error || "Analytics could not be loaded")

      setData(body)
    } catch (reason) {
      const message = reason instanceof DOMException && reason.name === "AbortError"
        ? "Analytics refresh timed out. Try again."
        : reason instanceof Error ? reason.message : "Analytics could not be loaded"

      setError(message)
    } finally {
      activeRequest.current = null
      window.clearTimeout(timeout)
      setLoading(false)
    }
  }, [endpoint])

  useEffect(() => {
    void load(initialStartDate, initialEndDate)

    return () => activeRequest.current?.abort()
  }, [initialEndDate, initialStartDate, load])

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    void load(startDate, endDate)
  }

  return (
    <section aria-labelledby="analytics-heading" className="space-y-6" data-testid="analytics-dashboard">
      <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
        <h2 className="text-2xl font-bold" id="analytics-heading">Seeded SaaS operating analytics</h2>
        <form className="mt-4 flex flex-wrap items-end gap-4" onSubmit={submit}>
          <label className="grid gap-1 text-sm font-medium">
            Start date
            <input className="rounded border border-gray-300 px-3 py-2" max={endDate} name="start_date" onChange={(event) => setStartDate(event.target.value)} type="date" value={startDate} />
          </label>
          <label className="grid gap-1 text-sm font-medium">
            End date
            <input className="rounded border border-gray-300 px-3 py-2" min={startDate} name="end_date" onChange={(event) => setEndDate(event.target.value)} type="date" value={endDate} />
          </label>
          <button className="rounded bg-indigo-600 px-4 py-2 font-semibold text-white disabled:opacity-50" disabled={loading} type="submit">
            {loading ? "Refreshing…" : "Refresh analytics"}
          </button>
        </form>
      </div>

      {loading && !data && <p aria-live="polite" className="rounded bg-indigo-50 p-6" role="status">Loading analytics…</p>}
      {error && <div className="rounded border border-red-300 bg-red-50 p-6" role="alert"><p>{error}</p><button className="mt-3 underline" onClick={() => void load(startDate, endDate)} type="button">Try again</button></div>}
      {!loading && !error && data?.series.length === 0 && <p className="rounded border border-gray-200 bg-white p-6" data-testid="analytics-empty">No metrics exist in this date range. Choose another range to continue exploring.</p>}
      {data && data.series.length > 0 && <AnalyticsCharts data={data} refreshing={loading} />}
    </section>
  )
}

function AnalyticsCharts({ data, refreshing }: { data: AnalyticsData; refreshing: boolean }) {
  const cards = [
    ["Active users", data.kpis.activeUsers.toLocaleString("en-US")],
    ["Revenue", currency(data.kpis.revenueCents)],
    ["Error rate", `${data.kpis.errorRate.toFixed(2)}%`],
    ["Average p95", `${data.kpis.p95Ms} ms`]
  ]

  return (
    <div aria-busy={refreshing} className="space-y-6" data-testid="analytics-populated">
      <dl className="grid gap-4 md:grid-cols-4">
        {cards.map(([label, value]) => <div className="rounded-lg border border-gray-200 bg-white p-5 shadow-sm" key={label}><dt className="text-sm text-gray-500">{label}</dt><dd className="mt-1 text-2xl font-bold">{value}</dd></div>)}
      </dl>
      <div className="grid gap-6 xl:grid-cols-2">
        <ChartCard descriptionId="active-user-trend-data" label="Active-user trend">
          <LineChart data={data.series}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="date" /><YAxis /><Tooltip /><Line dataKey="activeUsers" name="Active users" stroke="#4f46e5" strokeWidth={3} /></LineChart>
          <table className="sr-only" id="active-user-trend-data">
            <caption>Active-user trend data</caption>
            <thead><tr><th scope="col">Date</th><th scope="col">Active users</th><th scope="col">Requests</th><th scope="col">Revenue</th></tr></thead>
            <tbody>{data.series.map((day) => <tr key={day.date}><th scope="row">{day.date}</th><td>{day.activeUsers}</td><td>{day.requestCount}</td><td>{currency(day.revenueCents)}</td></tr>)}</tbody>
          </table>
        </ChartCard>
        <ChartCard descriptionId="account-active-users-data" label="Active users by account">
          <BarChart data={data.accounts}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="name" hide /><YAxis /><Tooltip /><Bar dataKey="activeUsers" fill="#0891b2" name="Active users" /></BarChart>
          <table className="sr-only" id="account-active-users-data">
            <caption>Active users by account data</caption>
            <thead><tr><th scope="col">Account</th><th scope="col">Active users</th><th scope="col">Revenue</th></tr></thead>
            <tbody>{data.accounts.map((account) => <tr key={account.name}><th scope="row">{account.name}</th><td>{account.activeUsers}</td><td>{currency(account.revenueCents)}</td></tr>)}</tbody>
          </table>
        </ChartCard>
        <ChartCard descriptionId="account-plan-mix-data" label="Account plan mix in range">
          <PieChart><Pie data={data.plans} dataKey="value" nameKey="name" outerRadius={105} label>{data.plans.map((entry, index) => <Cell fill={CHART_COLORS[index % CHART_COLORS.length]} key={entry.name} />)}</Pie><Tooltip /><Legend /></PieChart>
          <table className="sr-only" id="account-plan-mix-data">
            <caption>Account plan mix in range data</caption>
            <thead><tr><th scope="col">Plan</th><th scope="col">Accounts</th></tr></thead>
            <tbody>{data.plans.map((plan) => <tr key={plan.name}><th scope="row">{plan.name}</th><td>{plan.value}</td></tr>)}</tbody>
          </table>
        </ChartCard>
      </div>
    </div>
  )
}

function ChartCard({ children, descriptionId, label }: {
  children: [ReactElement, ReactElement]
  descriptionId: string
  label: string
}) {
  return (
    <section aria-label={label} className="rounded-lg border border-gray-200 bg-white p-5 shadow-sm">
      <h3 className="mb-4 text-lg font-semibold">{label}</h3>
      <div aria-describedby={descriptionId} aria-label={`${label} chart`} className="h-72" role="img">
        <ResponsiveContainer height="100%" width="100%">{children[0]}</ResponsiveContainer>
      </div>
      {children[1]}
    </section>
  )
}
