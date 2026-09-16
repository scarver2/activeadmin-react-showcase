// app/frontend/components/OnboardingWizard.tsx

import { useEffect, useRef, useState } from "react"

type Draft = { account_kind: string, company_name: string, compliance_contact: string, contact_email: string, current_step: number, id: number, lock_version: number, status: string }
export type OnboardingWizardProps = { draft: Draft, updateUrl: string }

function csrfToken() { return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || "" }

export default function OnboardingWizard({ draft: initialDraft, updateUrl }: OnboardingWizardProps) {
  const [draft, setDraft] = useState(initialDraft)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const alert = useRef<HTMLParagraphElement>(null)

  useEffect(() => { if (error) alert.current?.focus() }, [error])

  async function persist(nextStep: number, submit = false) {
    setSaving(true); setError(null)
    try {
      const response = await fetch(updateUrl, { method: "PATCH", credentials: "same-origin", headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() }, body: JSON.stringify({ ...draft, current_step: nextStep, lock_version: draft.lock_version, submit }) })
      const payload = await response.json() as { draft?: Draft, error?: string, errors?: Record<string, string[]> }
      if (!response.ok || !payload.draft) throw new Error(payload.error || Object.values(payload.errors || {}).flat().join(" ") || "Draft could not be saved")
      setDraft(payload.draft)
    } catch (saveError) {
      setError((saveError as Error).message)
    } finally { setSaving(false) }
  }

  if (draft.status === "submitted") return <section aria-live="polite"><h2 className="text-xl font-semibold">Application submitted</h2><p>{draft.company_name} is ready for Rails-owned processing.</p></section>

  return <section className="space-y-5" data-testid="onboarding-wizard">
    <p aria-label={`Step ${draft.current_step} of 3`} className="font-semibold">Step {draft.current_step} of 3</p>
    {error && <p ref={alert} role="alert" tabIndex={-1} className="text-red-700">{error}</p>}
    {draft.current_step === 1 && <fieldset><legend className="text-lg font-semibold">Organization</legend><label className="block">Company name<input className="mt-1 block rounded border p-2" value={draft.company_name} onChange={(event) => setDraft({ ...draft, company_name: event.target.value })}/></label><label className="mt-3 block">Account kind<select className="mt-1 block rounded border p-2" value={draft.account_kind} onChange={(event) => setDraft({ ...draft, account_kind: event.target.value })}><option value="standard">Standard</option><option value="regulated">Regulated</option></select></label>{draft.account_kind === "regulated" && <label className="mt-3 block">Compliance contact<input className="mt-1 block rounded border p-2" value={draft.compliance_contact} onChange={(event) => setDraft({ ...draft, compliance_contact: event.target.value })}/></label>}</fieldset>}
    {draft.current_step === 2 && <fieldset><legend className="text-lg font-semibold">Primary contact</legend><label>Email<input className="mt-1 block rounded border p-2" type="email" value={draft.contact_email} onChange={(event) => setDraft({ ...draft, contact_email: event.target.value })}/></label></fieldset>}
    {draft.current_step === 3 && <section><h2 className="text-lg font-semibold">Review</h2><dl><dt>Company</dt><dd>{draft.company_name}</dd><dt>Email</dt><dd>{draft.contact_email}</dd><dt>Account kind</dt><dd>{draft.account_kind}</dd>{draft.account_kind === "regulated" && <><dt>Compliance contact</dt><dd>{draft.compliance_contact}</dd></>}</dl></section>}
    <div className="flex gap-3">{draft.current_step > 1 && <button disabled={saving} className="rounded border px-3 py-2" onClick={() => void persist(draft.current_step - 1)} type="button">Back</button>}{draft.current_step < 3 ? <button disabled={saving} className="rounded bg-blue-700 px-3 py-2 text-white" onClick={() => void persist(draft.current_step + 1)} type="button">{saving ? "Saving…" : "Save and continue"}</button> : <button disabled={saving} className="rounded bg-green-700 px-3 py-2 text-white" onClick={() => void persist(3, true)} type="button">Submit application</button>}</div>
    <p className="text-sm">Drafts are saved on every transition and resume from this step.</p>
  </section>
}
