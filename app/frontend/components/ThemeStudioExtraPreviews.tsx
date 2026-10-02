// app/frontend/components/ThemeStudioExtraPreviews.tsx

import { useState } from "react"

export type ExtraSurface = "dense" | "login"

const records = [
  { id: "northstar-101", name: "Bluebonnet Logistics", owner: "Avery Morgan", status: "Active", volume: "$18,420" },
  { id: "northstar-102", name: "Hill Country Supply", owner: "Jordan Ellis", status: "Review", volume: "$7,800" },
  { id: "northstar-103", name: "Rio Grande Works", owner: "Casey Lane", status: "Active", volume: "$12,110" },
  { id: "northstar-104", name: "Juniper Dispatch", owner: "Avery Morgan", status: "Review", volume: "$6,240" }
]

function DensePreview() {
  const [query, setQuery] = useState("")
  const [selected, setSelected] = useState<string[]>([])
  const filtered = records.filter(record => record.name.toLowerCase().includes(query.toLowerCase().trim()))

  return <section aria-label="Dense data preview" className="space-y-3">
    <h4 className="font-bold">Account review workbench</h4>
    <p>Fictional fixtures only. Selection and filtering stay inside this preview.</p>
    <label className="block" htmlFor="studio-filter">Filter preview accounts</label>
    <input className="w-full rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)] px-3" id="studio-filter" onChange={event => setQuery(event.target.value)} value={query} />
    <p role="status">{filtered.length} {filtered.length === 1 ? "account" : "accounts"} shown · {selected.length} selected</p>
    <div className="overflow-x-auto rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)]" tabIndex={0}>
      <table className="w-full text-left">
        <caption className="sr-only">Synthetic account review data</caption>
        <thead className="bg-[var(--aat-subtle)]"><tr>{["Select", "Account", "Owner", "Status", "Volume"].map(label => <th className="p-3" key={label} scope="col">{label}</th>)}</tr></thead>
        <tbody>{filtered.map(record => <tr className="border-t border-[var(--aat-border)]" key={record.id} style={{ backgroundColor: selected.includes(record.id) ? "var(--aat-selected)" : "var(--aat-surface)" }}>
          <td className="p-3"><label className="inline-flex items-center justify-center" style={{ minHeight: "var(--aat-control-height)", minWidth: "var(--aat-control-height)" }}><input aria-label={`Select ${record.name}`} checked={selected.includes(record.id)} onChange={event => setSelected(current => event.target.checked ? [...current, record.id] : current.filter(id => id !== record.id))} type="checkbox" /></label></td>
          <th className="p-3" scope="row">{record.name}</th>
          <td className="p-3">{record.owner}</td>
          <td className="p-3"><span className="rounded-[var(--aat-radius)] px-2 py-1" style={{ backgroundColor: record.status === "Active" ? "var(--aat-success-bg)" : "var(--aat-warning-bg)", color: record.status === "Active" ? "var(--aat-success)" : "var(--aat-warning)" }}>{record.status}</span></td>
          <td className="p-3 whitespace-nowrap">{record.volume}</td>
        </tr>)}</tbody>
      </table>
      {filtered.length === 0 && <p className="p-3">No preview accounts match. Clear the filter to restore the fixtures.</p>}
    </div>
  </section>
}

function LoginPreview() {
  const [submitted, setSubmitted] = useState(false)
  return <form aria-label="Login preview" className="mx-auto max-w-sm rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)] p-4" onSubmit={event => { event.preventDefault(); setSubmitted(true) }}>
    <h4 className="font-bold">Sign in to Northstar Admin</h4>
    <p className="my-3 text-[var(--aat-muted)]">Visual fixture, not an authentication form. Never enter credentials here.</p>
    <label className="block" htmlFor="studio-email">Preview email</label>
    <input autoComplete="off" className="mb-3 w-full rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-background)] px-3" id="studio-email" readOnly type="email" value="operator@example.test" />
    <label className="block" htmlFor="studio-password">Preview password</label>
    <input aria-describedby="studio-login-notice" autoComplete="off" className="mb-3 w-full rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-background)] px-3" id="studio-password" readOnly type="password" value="synthetic-preview" />
    <p className="mb-3 rounded-[var(--aat-radius)] bg-[var(--aat-danger-bg)] p-2 text-[var(--aat-danger)]" id="studio-login-notice" role="status">{submitted ? "Preview only: no request sent and no session created." : "Example error state: sign-in could not be completed."}</p>
    <button className="rounded-[var(--aat-radius)] bg-[var(--aat-chrome)] px-4 text-[var(--aat-chrome-text)]" type="submit">Simulate sign-in feedback</button>
  </form>
}

export default function ThemeStudioExtraPreviews({ surface }: { surface: ExtraSurface }) {
  return surface === "dense" ? <DensePreview /> : <LoginPreview />
}
