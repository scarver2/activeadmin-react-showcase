// app/frontend/components/RelationshipExplorer.tsx

import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react"

type ContactRow = {
  email: string
  fullName: string
  href: string
  id: number
  jobTitle: string
  relationshipRole: string
}

type AccountSummary = {
  contactCount: number
  id: number
  name: string
  plan: string
  region: string
  status: string
}

type AccountDetail = AccountSummary & {
  contacts: ContactRow[]
  href: string
}

type ExplorerData = {
  accounts: AccountSummary[]
  filters: { plans: string[]; regions: string[]; relationshipRoles: string[] }
  selectedAccount: AccountDetail | null
  total: number
  truncated: boolean
}

type Criteria = {
  plan: string
  query: string
  region: string
  relationshipRole: string
  selectedId: string
}

export type RelationshipExplorerProps = { endpoint: string }

const REQUEST_TIMEOUT_MS = 8_000
const initialCriteria: Criteria = { plan: "", query: "", region: "", relationshipRole: "", selectedId: "" }

export default function RelationshipExplorer({ endpoint }: RelationshipExplorerProps) {
  const activeRequest = useRef<AbortController | null>(null)
  const [criteria, setCriteria] = useState(initialCriteria)
  const [data, setData] = useState<ExplorerData | null>(null)
  const [draft, setDraft] = useState(initialCriteria)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const load = useCallback(async (selected: Criteria) => {
    const controller = new AbortController()
    const timeout = window.setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS)
    activeRequest.current = controller
    setError(null)
    setLoading(true)

    try {
      const query = new URLSearchParams(Object.entries(selected).map(([key, value]) => [camelToSnake(key), value]))
      const response = await fetch(`${endpoint}?${query}`, {
        headers: { Accept: "application/json" },
        signal: controller.signal
      })
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || "Relationships could not be loaded")

      if (activeRequest.current === controller) setData(body)
    } catch (reason) {
      if (activeRequest.current !== controller) return

      const message = reason instanceof DOMException && reason.name === "AbortError"
        ? "Relationship search timed out. Try again."
        : reason instanceof Error ? reason.message : "Relationships could not be loaded"
      setError(message)
    } finally {
      window.clearTimeout(timeout)
      if (activeRequest.current === controller) {
        activeRequest.current = null
        setLoading(false)
      }
    }
  }, [endpoint])

  useEffect(() => {
    void load(criteria)
    return () => {
      const request = activeRequest.current
      activeRequest.current = null
      request?.abort()
    }
  }, [criteria, load])

  const resultSummary = useMemo(() => {
    if (!data) return "Relationships"

    return `${data.total} account${data.total === 1 ? "" : "s"}`
  }, [data])

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setCriteria({ ...draft, selectedId: "" })
  }

  return (
    <section aria-labelledby="relationship-explorer-heading" className="space-y-5" data-testid="relationship-explorer">
      <div className="rounded-lg border border-gray-200 bg-white p-5 shadow-sm">
        <h2 className="text-2xl font-bold" id="relationship-explorer-heading">Synthetic account relationships</h2>
        <form className="mt-4 grid gap-4 md:grid-cols-5" onSubmit={submit}>
          <label className="grid gap-1 text-sm font-medium">Search accounts or contacts<input className="rounded border px-3 py-2" maxLength={80} onChange={(event) => setDraft({ ...draft, query: event.target.value })} value={draft.query} /></label>
          <label className="grid gap-1 text-sm font-medium">Plan<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, plan: event.target.value })} value={draft.plan}><option value="">All plans</option>{data?.filters.plans.map((plan) => <option key={plan}>{plan}</option>)}</select></label>
          <label className="grid gap-1 text-sm font-medium">Region<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, region: event.target.value })} value={draft.region}><option value="">All regions</option>{data?.filters.regions.map((region) => <option key={region}>{region}</option>)}</select></label>
          <label className="grid gap-1 text-sm font-medium">Relationship role<select className="rounded border px-3 py-2" onChange={(event) => setDraft({ ...draft, relationshipRole: event.target.value })} value={draft.relationshipRole}><option value="">All roles</option>{data?.filters.relationshipRoles.map((role) => <option key={role}>{role}</option>)}</select></label>
          <button className="self-end rounded bg-indigo-600 px-4 py-2 font-semibold text-white disabled:opacity-50" disabled={loading} type="submit">{loading ? "Searching…" : "Apply filters"}</button>
        </form>
      </div>

      {loading && !data && <p aria-live="polite" className="rounded bg-indigo-50 p-5" role="status">Loading relationships…</p>}
      {error && <div className="rounded border border-red-300 bg-red-50 p-5" role="alert"><p>{error}</p><button className="mt-2 underline" onClick={() => void load(criteria)} type="button">Try again</button></div>}
      {!loading && !error && data?.accounts.length === 0 && <p className="rounded border bg-white p-5" data-testid="relationship-explorer-empty">No account or contact relationships match these bounded filters.</p>}

      {data && data.accounts.length > 0 && (
        <div aria-busy={loading} className="grid gap-5 lg:grid-cols-[minmax(16rem,1fr)_2fr]" data-testid="relationship-explorer-results">
          <section aria-label="Matching accounts" className="rounded-lg border bg-white shadow-sm">
            <header className="border-b p-4"><p aria-live="polite" className="font-semibold">{resultSummary}</p>{data.truncated && <p className="text-sm text-amber-700">Showing the first 20 accounts. Refine the filters for a narrower result.</p>}</header>
            <ul>{data.accounts.map((account) => <li className="border-b last:border-b-0" key={account.id}><button aria-pressed={data.selectedAccount?.id === account.id} className="w-full p-4 text-left hover:bg-indigo-50 aria-pressed:bg-indigo-100" disabled={loading} onClick={() => setCriteria({ ...criteria, selectedId: String(account.id) })} type="button"><span className="block font-semibold">{account.name}</span><span className="text-sm text-gray-600">{account.plan} · {account.region} · {account.contactCount} contacts</span></button></li>)}</ul>
          </section>
          {data.selectedAccount && <AccountRelationships account={data.selectedAccount} />}
        </div>
      )}
    </section>
  )
}

function AccountRelationships({ account }: { account: AccountDetail }) {
  return (
    <section aria-labelledby="selected-account-heading" className="rounded-lg border bg-white p-5 shadow-sm" data-testid="selected-account">
      <p className="text-sm font-semibold uppercase tracking-wide text-indigo-600">Selected account</p>
      <h3 className="mt-1 text-2xl font-bold" id="selected-account-heading"><a className="underline" href={account.href}>{account.name}</a></h3>
      <dl className="mt-4 grid grid-cols-3 gap-3 text-sm"><div><dt className="text-gray-500">Plan</dt><dd>{account.plan}</dd></div><div><dt className="text-gray-500">Region</dt><dd>{account.region}</dd></div><div><dt className="text-gray-500">Status</dt><dd className="capitalize">{account.status}</dd></div></dl>
      <h4 className="mt-6 text-lg font-semibold">Contacts</h4>
      <ul className="mt-3 grid gap-3 md:grid-cols-2">{account.contacts.map((contact) => <li className="rounded border p-4" key={contact.id}><a className="font-semibold text-indigo-700 underline" href={contact.href}>{contact.fullName}</a><p>{contact.jobTitle}</p><p className="text-sm text-gray-600">{contact.relationshipRole}</p><p className="mt-2 break-all text-sm">{contact.email}</p></li>)}</ul>
    </section>
  )
}

function camelToSnake(value: string) {
  return value.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`)
}
