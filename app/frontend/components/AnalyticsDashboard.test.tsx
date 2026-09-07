// app/frontend/components/AnalyticsDashboard.test.tsx

import { act, fireEvent, render, screen, waitFor } from "@testing-library/react"
import type { ReactNode } from "react"

import AnalyticsDashboard, { type AnalyticsData } from "./AnalyticsDashboard"

vi.mock("recharts", () => {
  function Element({ children }: { children?: ReactNode }) {
    return <div>{children}</div>
  }

  return {
    Bar: Element,
    BarChart: Element,
    CartesianGrid: Element,
    Cell: Element,
    Legend: Element,
    Line: Element,
    LineChart: Element,
    Pie: Element,
    PieChart: Element,
    ResponsiveContainer: Element,
    Tooltip: Element,
    XAxis: Element,
    YAxis: Element
  }
})

const populated: AnalyticsData = {
  accounts: [{ activeUsers: 42, name: "Bluebonnet", revenueCents: 125_000 }],
  kpis: { activeUsers: 42, errorRate: 1.25, p95Ms: 180, revenueCents: 125_000 },
  plans: [{ name: "Growth", value: 1 }],
  range: { endDate: "2026-09-06", startDate: "2026-09-01" },
  series: [{ activeUsers: 42, date: "2026-09-01", requestCount: 900, revenueCents: 125_000 }]
}

const empty: AnalyticsData = {
  accounts: [],
  kpis: { activeUsers: 0, errorRate: 0, p95Ms: 0, revenueCents: 0 },
  plans: [],
  range: { endDate: "2025-01-02", startDate: "2025-01-01" },
  series: []
}

function response(body: unknown, ok = true) {
  return Promise.resolve({ json: () => Promise.resolve(body), ok } as Response)
}

function renderDashboard() {
  return render(
    <AnalyticsDashboard endpoint="/admin/analytics/data" initialEndDate="2026-09-06" initialStartDate="2026-09-01" />
  )
}

describe("AnalyticsDashboard", () => {
  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it("shows loading and then the populated KPI and chart states", async () => {
    let resolveFetch: (value: Response) => void = () => undefined
    vi.stubGlobal("fetch", vi.fn(() => new Promise<Response>((resolve) => { resolveFetch = resolve })))

    renderDashboard()
    expect(screen.getByRole("status")).toHaveTextContent("Loading analytics")

    await act(async () => resolveFetch(await response(populated)))

    expect(await screen.findByTestId("analytics-populated")).toHaveTextContent("42")
    expect(screen.getByTestId("analytics-populated")).toHaveTextContent("$1,250")
    expect(screen.getByTestId("analytics-populated")).toHaveTextContent("1.25%")
    expect(screen.getByRole("img", { name: "Active-user trend chart" })).toBeVisible()
    expect(screen.getByRole("img", { name: "Active users by account chart" })).toBeVisible()
    expect(screen.getByRole("img", { name: "Account plan mix in range chart" })).toBeVisible()
    expect(screen.getByRole("img", { name: "Active-user trend chart" })).toHaveAttribute("aria-describedby", "active-user-trend-data")
    expect(screen.getByRole("img", { name: "Active users by account chart" })).toHaveAttribute("aria-describedby", "account-active-users-data")
    expect(screen.getByRole("img", { name: "Account plan mix in range chart" })).toHaveAttribute("aria-describedby", "account-plan-mix-data")
    expect(screen.getByRole("table", { name: "Active-user trend data" })).toHaveTextContent("2026-09-01")
    expect(screen.getByRole("table", { name: "Active users by account data" })).toHaveTextContent("Bluebonnet")
    expect(screen.getByRole("table", { name: "Account plan mix in range data" })).toHaveTextContent("Growth")
  })

  it("renders the empty state", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response(empty)))

    renderDashboard()

    expect(await screen.findByTestId("analytics-empty")).toHaveTextContent("No metrics exist")
  })

  it("filters by date and keeps populated data visible during a bounded refresh", async () => {
    let resolveRefresh: (value: Response) => void = () => undefined
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response(populated))
      .mockImplementationOnce(() => new Promise<Response>((resolve) => { resolveRefresh = resolve }))
    vi.stubGlobal("fetch", fetchMock)
    renderDashboard()
    await screen.findByTestId("analytics-populated")

    fireEvent.change(screen.getByLabelText("Start date"), { target: { value: "2026-09-03" } })
    fireEvent.change(screen.getByLabelText("End date"), { target: { value: "2026-09-05" } })
    fireEvent.click(screen.getByRole("button", { name: "Refresh analytics" }))

    expect(screen.getByTestId("analytics-populated")).toHaveAttribute("aria-busy", "true")
    expect(fetchMock).toHaveBeenLastCalledWith(
      "/admin/analytics/data?end_date=2026-09-05&start_date=2026-09-03",
      expect.objectContaining({ headers: { Accept: "application/json" } })
    )

    await act(async () => resolveRefresh(await response(populated)))
    expect(screen.getByTestId("analytics-populated")).toHaveAttribute("aria-busy", "false")
  })

  it("renders an endpoint error and retries successfully", async () => {
    const fetchMock = vi.fn()
      .mockImplementationOnce(() => response({ error: "Choose no more than 90 days" }, false))
      .mockImplementationOnce(() => response(populated))
    vi.stubGlobal("fetch", fetchMock)
    renderDashboard()

    expect(await screen.findByRole("alert")).toHaveTextContent("Choose no more than 90 days")
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))

    expect(await screen.findByTestId("analytics-populated")).toBeVisible()
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it("uses a safe fallback for an unsuccessful response without an error message", async () => {
    vi.stubGlobal("fetch", vi.fn(() => response({}, false)))

    renderDashboard()

    expect(await screen.findByRole("alert")).toHaveTextContent("Analytics could not be loaded")
  })

  it("reports ordinary and non-Error fetch failures", async () => {
    const fetchMock = vi.fn()
      .mockRejectedValueOnce(new Error("Network unavailable"))
      .mockRejectedValueOnce("untyped failure")
    vi.stubGlobal("fetch", fetchMock)
    renderDashboard()

    expect(await screen.findByRole("alert")).toHaveTextContent("Network unavailable")
    fireEvent.click(screen.getByRole("button", { name: "Try again" }))

    await waitFor(() => expect(screen.getByRole("alert")).toHaveTextContent("Analytics could not be loaded"))
  })

  it("aborts and reports a refresh that exceeds eight seconds", async () => {
    vi.useFakeTimers()
    vi.stubGlobal("fetch", vi.fn((_url, options: RequestInit) => new Promise((_resolve, reject) => {
      options.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
    })))
    renderDashboard()

    await act(async () => vi.advanceTimersByTime(8_000))

    expect(screen.getByRole("alert")).toHaveTextContent("Analytics refresh timed out")
  })

  it("aborts an active request when the island unmounts", async () => {
    const abortSpy = vi.spyOn(AbortController.prototype, "abort")
    vi.stubGlobal("fetch", vi.fn((_url, options: RequestInit) => new Promise((_resolve, reject) => {
      options.signal?.addEventListener("abort", () => reject(new DOMException("Aborted", "AbortError")))
    })))
    const { unmount } = renderDashboard()

    unmount()

    expect(abortSpy).toHaveBeenCalledOnce()
  })
})
