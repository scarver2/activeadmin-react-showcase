// app/frontend/components/AccountExplorer.tsx

import { createColumnHelper, tableFeatures, useTable } from "@tanstack/react-table"
import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react"

export type AccountRow = {
  activeUsers: number
  href: string
  id: number
  name: string
  plan: string
  region: string
  revenueCents: number
  status: string
}

type ExplorerData = {
  filters: { plans: string[]; statuses: string[] }
  page: number
  perPage: number
  rows: AccountRow[]
  sort: { direction: Direction; field: SortField }
  total: number
  totalPages: number
}

type Criteria = {
  direction: Direction
  page: number
  perPage: number
  plan: string
  query: string
  sort: SortField
  status: string
}

export type AccountExplorerProps = { endpoint: string }
type Direction = "asc" | "desc"
type SortField = "name" | "plan" | "region" | "status"

const EMPTY_ROWS: AccountRow[] = []
const REQUEST_TIMEOUT_MS = 8_000
const features = tableFeatures({})
const helper = createColumnHelper<typeof features, AccountRow>()
const columns = helper.columns([
  helper.accessor("name", { header: "Name", cell: ({ getValue, row }) => <a className="font-semibold text-indigo-700 underline" href={row.original.href}>{getValue()}</a> }),
  helper.accessor("plan", { header: "Plan" }),
  helper.accessor("region", { header: "Region" }),
  helper.accessor("status", { header: "Status", cell: ({ getValue }) => <span className="capitalize">{getValue()}</span> }),
  helper.accessor("activeUsers", { header: "Active users", cell: ({ getValue }) => getValue().toLocaleString("en-US") }),
  helper.accessor("revenueCents", { header: "Revenue", cell: ({ getValue }) => currency(getValue()) })
])
const initialCriteria: Criteria = {
  direction: "asc",
  page: 1,
  perPage: 5,
  plan: "",
  query: "",
  sort: "name",
  status: ""
}
const sortableFields = new Set<SortField>(["name", "plan", "region", "status"])

function currency(cents: number) {
  return new Intl.NumberFormat("en-US", { currency: "USD", maximumFractionDigits: 0, style: "currency" }).format(cents / 100)
}

export default function AccountExplorer({ endpoint }: AccountExplorerProps) {
  const activeRequest = useRef<AbortController | null>(null)
  const [criteria, setCriteria] = useState<Criteria>(initialCriteria)
  const [data, setData] = useState<ExplorerData | null>(null)
  const [draft, setDraft] = useState(initialCriteria)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const load = useCallback(async (selected: Criteria) => {
    activeRequest.current?.abort()
    const controller = new AbortController()
    const timeout = window.setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
    activeRequest.current = controller
    setError(null)
    setLoading(true)

    try {
      const query = new URLSearchParams(Object.entries(selected).map(([key, value]) => [camelToSnake(key), String(value)]))
      const response = await fetch(`${endpoint}?${query}`, { headers: { Accept: "application/json" }, signal: controller.signal })
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || "Accounts could not be loaded")

      setData(body)
    } catch (reason) {
      const message = reason instanceof DOMException && reason.name === "AbortError"
        ? "Account search timed out. Try again."
        : reason instanceof Error ? reason.message : "Accounts could not be loaded"
      setError(message)
    } finally {
      if (activeRequest.current === controller) activeRequest.current = null
      window.clearTimeout(timeout)
      setLoading(false)
    }
  }, [endpoint])

  useEffect(() => {
    void load(criteria)
    return () => activeRequest.current?.abort()
  }, [criteria, load])

  const tableData = data?.rows ?? EMPTY_ROWS
  const table = useTable({ columns, data: tableData, features })
  const summary = useMemo(() => data ? `${data.total} account${data.total === 1 ? "" : "s"}` : "Accounts", [data])

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setCriteria({ ...draft, page: 1 })
  }

  function sortBy(field: SortField) {
    setCriteria((current) => ({
      ...current,
      direction: current.sort === field && current.direction === "asc" ? "desc" : "asc",
      page: 1,
      sort: field
    }))
  }

  return (
    <section aria-labelledby="account-explorer-heading" className="space-y-5" data-testid="account-explorer">
      <div className="rounded-lg border border-gray-200 bg-white p-5 shadow-sm">
        <h2 className="text-2xl font-bold" id="account-explorer-heading">Synthetic account explorer</h2>
        <form className="mt-4 grid gap-4 md:grid-cols-4" onSubmit={submit}>
          <label className="grid gap-1 text-sm font-medium">Search name<input className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, query: event.target.value })} value={draft.query} /></label>
          <label className="grid gap-1 text-sm font-medium">Plan<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, plan: event.target.value })} value={draft.plan}><option value="">All plans</option>{data?.filters.plans.map((plan) => <option key={plan}>{plan}</option>)}</select></label>
          <label className="grid gap-1 text-sm font-medium">Status<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, status: event.target.value })} value={draft.status}><option value="">All statuses</option>{data?.filters.statuses.map((status) => <option key={status}>{status}</option>)}</select></label>
          <button className="self-end rounded bg-indigo-600 px-4 py-2 font-semibold text-white disabled:opacity-50" disabled={loading} type="submit">{loading ? "Loading…" : "Apply filters"}</button>
        </form>
      </div>

      {loading && !data && <p aria-live="polite" className="rounded bg-indigo-50 p-5" role="status">Loading accounts…</p>}
      {error && <div className="rounded border border-red-300 bg-red-50 p-5" role="alert"><p>{error}</p><button className="mt-2 underline" onClick={() => void load(criteria)} type="button">Try again</button></div>}
      {!loading && !error && data?.rows.length === 0 && <p className="rounded border bg-white p-5" data-testid="account-explorer-empty">No accounts match these bounded filters.</p>}
      {data && data.rows.length > 0 && (
        <div aria-busy={loading} className="overflow-x-auto rounded-lg border bg-white shadow-sm" data-testid="account-explorer-results">
          <div className="flex items-center justify-between border-b p-4"><p aria-live="polite">{summary}</p><label className="text-sm">Rows <select className="ml-2 rounded border px-2 py-1" onChange={(event) => setCriteria((current) => ({ ...current, page: 1, perPage: Number(event.target.value) }))} value={criteria.perPage}><option value="5">5</option><option value="10">10</option><option value="20">20</option></select></label></div>
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100">{table.getHeaderGroups().map((group) => <tr key={group.id}>{group.headers.map((header) => {
              const field = header.column.id as SortField
              const sortable = sortableFields.has(field)
              return <th className="px-4 py-3" key={header.id} scope="col">{sortable ? <button aria-label={`Sort by ${field}`} className="font-semibold underline" onClick={() => sortBy(field)} type="button"><table.FlexRender header={header} />{criteria.sort === field ? ` ${criteria.direction === "asc" ? "↑" : "↓"}` : ""}</button> : <table.FlexRender header={header} />}</th>
            })}</tr>)}</thead>
            <tbody>{table.getRowModel().rows.map((row) => <tr className="border-t" key={row.id}>{row.getAllCells().map((cell) => <td className="px-4 py-3" key={cell.id}><table.FlexRender cell={cell} /></td>)}</tr>)}</tbody>
          </table>
          <nav aria-label="Account pages" className="flex items-center justify-between border-t p-4"><button className="rounded border px-3 py-2 disabled:opacity-40" disabled={criteria.page <= 1 || loading} onClick={() => setCriteria((current) => ({ ...current, page: current.page - 1 }))} type="button">Previous</button><span>Page {data.page} of {data.totalPages}</span><button className="rounded border px-3 py-2 disabled:opacity-40" disabled={criteria.page >= data.totalPages || loading} onClick={() => setCriteria((current) => ({ ...current, page: current.page + 1 }))} type="button">Next</button></nav>
        </div>
      )}
    </section>
  )
}

function camelToSnake(value: string) {
  return value.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`)
}
