// app/frontend/components/AccountExplorer.tsx

import { createColumnHelper, tableFeatures, useTable } from "@tanstack/react-table"
import { type FormEvent, type MouseEvent, useCallback, useEffect, useMemo, useRef, useState } from "react"

import ContextualInspector from "./ContextualInspector"
import ThemeIcon from "./ThemeIcon"

export type AccountRow = {
  activeUsers: number
  href: string
  id: number
  inspectorHref: string
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

type CompositionSlots = {
  dataHeading: string
  dataSurface: string
  dataTable: string
  pagination: string
  primaryAction: string
  toolbar: string
  toolbarSurface: string
}

export type AccountExplorerProps = { composition?: CompositionSlots; endpoint: string }
type Direction = "asc" | "desc"
type SortField = "name" | "plan" | "region" | "status"

type InspectorSelection = {
  canonicalHref: string
  inspectorHref: string
  name: string
}

type InspectorPayload = {
  actions: { href: string; label: string }[]
  account: { id: number; name: string; plan: string; region: string; status: string }
  canonicalHref: string
  metrics: { activeUsers: number; recordedOn: string | null; revenueCents: number }
  relationships: { contacts: number; observations: number }
}

const EMPTY_ROWS: AccountRow[] = []
const REQUEST_TIMEOUT_MS = 8_000
const features = tableFeatures({})
const helper = createColumnHelper<typeof features, AccountRow>()
const columns = helper.columns([
  helper.accessor("name", { header: "Name", cell: ({ getValue, row }) => <a className="font-semibold text-indigo-700 underline" data-account-inspector={row.original.inspectorHref} href={row.original.href}>{getValue()}</a> }),
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

export default function AccountExplorer({ composition, endpoint }: AccountExplorerProps) {
  const activeRequest = useRef<AbortController | null>(null)
  const [criteria, setCriteria] = useState<Criteria>(initialCriteria)
  const [data, setData] = useState<ExplorerData | null>(null)
  const [draft, setDraft] = useState(initialCriteria)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const inspectorRequest = useRef<AbortController | null>(null)
  const inspectorReturnFocus = useRef<HTMLElement | null>(null)
  const [inspectorError, setInspectorError] = useState<string | null>(null)
  const [inspectorLoading, setInspectorLoading] = useState(false)
  const [inspectorPayload, setInspectorPayload] = useState<InspectorPayload | null>(null)
  const [inspectorSelection, setInspectorSelection] = useState<InspectorSelection | null>(null)

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

  const loadInspector = useCallback(async (selection: InspectorSelection) => {
    inspectorRequest.current?.abort()
    const controller = new AbortController()
    inspectorRequest.current = controller
    setInspectorError(null)
    setInspectorLoading(true)
    setInspectorPayload(null)

    try {
      const response = await fetch(selection.inspectorHref, { headers: { Accept: "application/json" }, signal: controller.signal })
      if (response.redirected || response.status === 401 || response.status === 403) {
        throw new Error("Your authorization changed. Reopen the canonical account page to continue.")
      }
      if (response.status === 404) throw new Error("This account is no longer available. It may have been deleted.")
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || "Account context could not be loaded")

      setInspectorPayload(body)
    } catch (reason) {
      if (reason instanceof DOMException && reason.name === "AbortError") return
      setInspectorError(reason instanceof Error ? reason.message : "Account context could not be loaded")
    } finally {
      if (inspectorRequest.current === controller) inspectorRequest.current = null
      setInspectorLoading(false)
    }
  }, [])

  const dismissInspector = useCallback(() => {
    inspectorRequest.current?.abort()
    setInspectorSelection(null)
    setInspectorPayload(null)
    setInspectorError(null)
    setInspectorLoading(false)
  }, [])

  useEffect(() => {
    function restoreFromHistory(event: PopStateEvent) {
      const selection = event.state?.contextualInspector as InspectorSelection | undefined
      if (selection) {
        setInspectorSelection(selection)
        void loadInspector(selection)
      } else {
        dismissInspector()
      }
    }

    window.addEventListener("popstate", restoreFromHistory)
    return () => {
      inspectorRequest.current?.abort()
      window.removeEventListener("popstate", restoreFromHistory)
    }
  }, [dismissInspector, loadInspector])

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

  function inspectAccount(event: MouseEvent<HTMLDivElement>) {
    const target = (event.target as HTMLElement).closest<HTMLAnchorElement>("a[data-account-inspector]")
    if (!target || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    event.preventDefault()
    const selection = {
      canonicalHref: target.href,
      inspectorHref: target.dataset.accountInspector!,
      name: target.textContent!.trim()
    }
    inspectorReturnFocus.current = target
    window.history.pushState({ ...window.history.state, contextualInspector: selection }, "", selection.canonicalHref)
    setInspectorSelection(selection)
    void loadInspector(selection)
  }

  function closeInspector() {
    if (window.history.state?.contextualInspector) {
      window.history.back()
    } else {
      dismissInspector()
    }
  }

  return (
    <section aria-labelledby="account-explorer-heading" className="showcase-themed-island space-y-5" data-testid="account-explorer">
      <div className={classes("showcase-panel", composition?.toolbarSurface, !composition && "rounded-lg border border-gray-200 bg-white p-5 shadow-sm")}>
        <h2 className={classes("text-2xl font-bold", composition?.dataHeading)} id="account-explorer-heading">Synthetic account explorer</h2>
        <form className={classes("mt-4 grid gap-4 md:grid-cols-4", composition?.toolbar)} onSubmit={submit}>
          <label className="grid gap-1 text-sm font-medium">Search name<input className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, query: event.target.value })} value={draft.query} /></label>
          <label className="grid gap-1 text-sm font-medium">Plan<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, plan: event.target.value })} value={draft.plan}><option value="">All plans</option>{data?.filters.plans.map((plan) => <option key={plan}>{plan}</option>)}</select></label>
          <label className="grid gap-1 text-sm font-medium">Status<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, status: event.target.value })} value={draft.status}><option value="">All statuses</option>{data?.filters.statuses.map((status) => <option key={status}>{status}</option>)}</select></label>
          <button className={classes("showcase-primary-action self-end rounded bg-indigo-600 px-4 py-2 font-semibold text-white disabled:opacity-50", composition?.primaryAction)} disabled={loading} type="submit">{loading ? "Loading…" : "Apply filters"}</button>
        </form>
      </div>

      {loading && !data && <p aria-live="polite" className="rounded bg-indigo-50 p-5" role="status">Loading accounts…</p>}
      {error && <div className="rounded border border-red-300 bg-red-50 p-5" role="alert"><p>{error}</p><button className="mt-2 underline" onClick={() => void load(criteria)} type="button">Try again</button></div>}
      {!loading && !error && data?.rows.length === 0 && <p className="rounded border bg-white p-5" data-testid="account-explorer-empty">No accounts match these bounded filters.</p>}
      {data && data.rows.length > 0 && (
        <div aria-busy={loading} className={classes("showcase-panel overflow-x-auto", composition?.dataSurface, !composition && "rounded-lg border bg-white shadow-sm")} data-testid="account-explorer-results" onClick={inspectAccount}>
          <div className="flex items-center justify-between border-b p-4"><p aria-live="polite">{summary}</p><label className="account-explorer-rows text-sm"><span className={classes("account-explorer-rows-label", Boolean(composition) && "sr-only")}>Rows</span> <select className={classes("ml-2 rounded border px-2 py-1", Boolean(composition) && "min-h-11")} title="Rows" onChange={(event) => setCriteria((current) => ({ ...current, page: 1, perPage: Number(event.target.value) }))} value={criteria.perPage}><option value="5">5</option><option value="10">10</option><option value="20">20</option></select></label></div>
          <table className={classes("w-full text-left text-sm", composition?.dataTable)}>
            <thead className="bg-gray-100">{table.getHeaderGroups().map((group) => <tr key={group.id}>{group.headers.map((header) => {
              const field = header.column.id as SortField
              const sortable = sortableFields.has(field)
              return <th className="px-4 py-3" key={header.id} scope="col">{sortable ? <button aria-label={`Sort by ${field}`} className="font-semibold underline" onClick={() => sortBy(field)} type="button"><table.FlexRender header={header} />{criteria.sort === field ? ` ${criteria.direction === "asc" ? "↑" : "↓"}` : ""}</button> : <table.FlexRender header={header} />}</th>
            })}</tr>)}</thead>
            <tbody>{table.getRowModel().rows.map((row) => <tr className="border-t" key={row.id}>{row.getAllCells().map((cell) => <td className="px-4 py-3" key={cell.id}><table.FlexRender cell={cell} /></td>)}</tr>)}</tbody>
          </table>
          <nav aria-label="Account pages" className={classes("flex items-center justify-between border-t p-4", composition?.pagination)}><button className="rounded border px-3 py-2 disabled:opacity-40" disabled={criteria.page <= 1 || loading} onClick={() => setCriteria((current) => ({ ...current, page: current.page - 1 }))} type="button">Previous</button><span>Page {data.page} of {data.totalPages}</span><button className="rounded border px-3 py-2 disabled:opacity-40" disabled={criteria.page >= data.totalPages || loading} onClick={() => setCriteria((current) => ({ ...current, page: current.page + 1 }))} type="button">Next</button></nav>
        </div>
      )}
      {inspectorSelection && <ContextualInspector
        canonicalHref={inspectorSelection.canonicalHref}
        error={inspectorError}
        eyebrow="Account context"
        loading={inspectorLoading}
        onClose={closeInspector}
        returnFocus={inspectorReturnFocus}
        title={inspectorPayload?.account.name ?? inspectorSelection.name}
      >
        {inspectorPayload && <AccountInspectorDetails payload={inspectorPayload} />}
      </ContextualInspector>}
    </section>
  )
}

function camelToSnake(value: string) {
  return value.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`)
}

function AccountInspectorDetails({ payload }: { payload: InspectorPayload }) {
  return <div className="space-y-6">
    <dl className="grid grid-cols-2 gap-3">
      <Detail label="Status" value={payload.account.status} />
      <Detail label="Plan" value={payload.account.plan} />
      <Detail label="Region" value={payload.account.region} />
      <Detail label="Account ID" value={`#${payload.account.id}`} />
    </dl>

    <section aria-labelledby="inspector-activity-heading" className="border-t border-[var(--aat-border)] pt-5">
      <h3 className="font-bold" id="inspector-activity-heading">Latest activity</h3>
      <dl className="mt-3 grid grid-cols-2 gap-3">
        <Detail label="Active users" value={payload.metrics.activeUsers.toLocaleString("en-US")} />
        <Detail label="Revenue" value={currency(payload.metrics.revenueCents)} />
      </dl>
      <p className="mt-2 text-sm text-[var(--aat-muted)]">{payload.metrics.recordedOn ? `Observed ${payload.metrics.recordedOn}` : "No observations yet"}</p>
    </section>

    <section aria-labelledby="inspector-relationships-heading" className="border-t border-[var(--aat-border)] pt-5">
      <h3 className="font-bold" id="inspector-relationships-heading">Relationships</h3>
      <p className="mt-2 text-sm">{payload.relationships.contacts} contacts · {payload.relationships.observations} metric observations</p>
    </section>

    <nav aria-label="Account actions" className="grid gap-2 border-t border-[var(--aat-border)] pt-5">
      {payload.actions.map((action, index) => <a className={index === 0 ? "showcase-primary-action flex min-h-11 items-center justify-center gap-2 rounded border px-4 py-2 font-semibold no-underline" : "flex min-h-11 items-center justify-center gap-2 rounded border border-[var(--aat-border)] px-4 py-2 font-semibold no-underline"} href={action.href} key={action.href}>
        <ThemeIcon name={index === 0 ? "records" : "settings"} />
        {action.label}
      </a>)}
    </nav>
  </div>
}

function Detail({ label, value }: { label: string; value: string }) {
  return <div className="rounded border border-[var(--aat-border)] p-3"><dt className="text-xs font-bold uppercase tracking-wide text-[var(--aat-muted)]">{label}</dt><dd className="mt-1 font-semibold capitalize">{value}</dd></div>
}

function classes(...values: (false | string | undefined)[]) {
  return values.filter(Boolean).join(" ")
}
