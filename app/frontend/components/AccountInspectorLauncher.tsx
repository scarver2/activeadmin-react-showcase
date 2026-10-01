// app/frontend/components/AccountInspectorLauncher.tsx

import { type MouseEvent, useCallback, useEffect, useRef, useState } from "react"

import ContextualInspector from "./ContextualInspector"
import ThemeIcon from "./ThemeIcon"

export type AccountInspectorPayload = {
  actions: { href: string; label: string }[]
  account: { id: number; name: string; plan: string; region: string; status: string }
  canonicalHref: string
  metrics: { activeUsers: number; recordedOn: string | null; revenueCents: number }
  relationships: { contacts: number; observations: number }
}

export type AccountInspectorLauncherProps = {
  canonicalHref: string
  collectionHref: string
  inspectorHref: string
  label?: string
  name: string
}

type InspectorFailure = {
  actionHref: string
  actionLabel: string
  message: string
}

type InspectorSelection = AccountInspectorLauncherProps

const HISTORY_KEY = "contextualInspector"
const HISTORY_RETURN_KEY = "contextualInspectorReturnFocus"
const REQUEST_TIMEOUT_MS = 8_000

export default function AccountInspectorLauncher({ canonicalHref, collectionHref, inspectorHref, label, name }: AccountInspectorLauncherProps) {
  const request = useRef<AbortController | null>(null)
  const returnFocus = useRef<HTMLAnchorElement | null>(null)
  const [failure, setFailure] = useState<InspectorFailure | null>(null)
  const [loading, setLoading] = useState(false)
  const [open, setOpen] = useState(false)
  const [payload, setPayload] = useState<AccountInspectorPayload | null>(null)
  const selection = { canonicalHref, collectionHref, inspectorHref, label, name }
  const inspectorHash = `#account-inspector-${new URL(canonicalHref, window.location.origin).pathname.split("/").filter(Boolean).at(-1)}`

  const close = useCallback(() => {
    request.current?.abort()
    request.current = null
    setFailure(null)
    setLoading(false)
    setOpen(false)
    setPayload(null)
  }, [])

  const load = useCallback(async () => {
    request.current?.abort()
    const controller = new AbortController()
    const timeout = window.setTimeout(() => controller.abort("timeout"), REQUEST_TIMEOUT_MS)
    request.current = controller
    setFailure(null)
    setLoading(true)
    setOpen(true)
    setPayload(null)

    try {
      const response = await fetch(inspectorHref, {
        credentials: "same-origin",
        headers: { Accept: "application/json" },
        signal: controller.signal
      })
      if (response.redirected || response.status === 401 || response.status === 403) {
        setFailure({
          actionHref: canonicalHref,
          actionLabel: "Reauthenticate on the canonical account page",
          message: "Your authorization changed. Sign in again or request access before continuing."
        })
        return
      }
      if (response.status === 404) {
        setFailure({
          actionHref: collectionHref,
          actionLabel: "Return to the account list",
          message: "This account is no longer available. It may have been deleted."
        })
        return
      }

      const body = await response.json()
      if (!response.ok) throw new Error(body.error || "Account context could not be loaded")

      setPayload(body)
    } catch (reason) {
      if (controller.signal.aborted && controller.signal.reason !== "timeout") return

      setFailure({
        actionHref: canonicalHref,
        actionLabel: "Open the canonical account page",
        message: controller.signal.reason === "timeout"
          ? "Account context timed out. Open the canonical page or try again."
          : reason instanceof Error ? reason.message : "Account context could not be loaded"
      })
    } finally {
      window.clearTimeout(timeout)
      if (request.current === controller) request.current = null
      setLoading(false)
    }
  }, [canonicalHref, collectionHref, inspectorHref])

  useEffect(() => {
    function restoreFromHistory(event: PopStateEvent) {
      const restored = event.state?.[HISTORY_KEY] as InspectorSelection | undefined
      if (restored?.inspectorHref === inspectorHref || window.location.hash === inspectorHash) {
        void load()
      } else {
        close()
        if (event.state?.[HISTORY_RETURN_KEY] === inspectorHref) {
          window.requestAnimationFrame(() => returnFocus.current?.focus())
        }
      }
    }

    window.addEventListener("popstate", restoreFromHistory)
    if (window.location.hash === inspectorHash) void load()
    if (window.history.state?.[HISTORY_RETURN_KEY] === inspectorHref) {
      window.requestAnimationFrame(() => returnFocus.current?.focus())
    }
    return () => {
      request.current?.abort()
      window.removeEventListener("popstate", restoreFromHistory)
    }
  }, [close, inspectorHash, inspectorHref, load])

  function activate(event: MouseEvent<HTMLAnchorElement>) {
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return

    event.preventDefault()
    returnFocus.current = event.currentTarget
    window.history.replaceState({ ...window.history.state, [HISTORY_RETURN_KEY]: inspectorHref }, "", window.location.href)
    const historyHref = `${window.location.pathname}${window.location.search}${inspectorHash}`
    window.history.pushState({ ...window.history.state, [HISTORY_KEY]: selection }, "", historyHref)
    void load()
  }

  function dismiss() {
    const active = window.history.state?.[HISTORY_KEY] as InspectorSelection | undefined
    if (active?.inspectorHref === inspectorHref) {
      window.history.back()
    } else {
      close()
    }
  }

  return <>
    <a
      className="account-inspector-launcher"
      data-account-inspector={inspectorHref}
      href={canonicalHref}
      onClick={activate}
      ref={returnFocus}
    >{label ?? name}</a>
    {open && <ContextualInspector
      error={failure?.message ?? null}
      errorActionHref={failure?.actionHref ?? canonicalHref}
      errorActionLabel={failure?.actionLabel ?? "Open the canonical account page"}
      eyebrow="Account context"
      loading={loading}
      onClose={dismiss}
      returnFocus={returnFocus}
      title={payload?.account.name ?? name}
    >
      {payload && <AccountInspectorDetails payload={payload} />}
    </ContextualInspector>}
  </>
}

function AccountInspectorDetails({ payload }: { payload: AccountInspectorPayload }) {
  return <div className="account-inspector-details">
    <dl className="account-inspector-summary">
      <Detail label="Status" value={payload.account.status} />
      <Detail label="Plan" value={payload.account.plan} />
      <Detail label="Region" value={payload.account.region} />
      <Detail label="Account ID" value={`#${payload.account.id}`} />
    </dl>

    <section aria-labelledby="inspector-activity-heading" className="account-inspector-section">
      <h3 id="inspector-activity-heading">Latest activity</h3>
      <dl className="account-inspector-summary">
        <Detail label="Active users" value={payload.metrics.activeUsers.toLocaleString("en-US")} />
        <Detail label="Revenue" value={currency(payload.metrics.revenueCents)} />
      </dl>
      <p className="account-inspector-muted">{payload.metrics.recordedOn ? `Observed ${payload.metrics.recordedOn}` : "No observations yet"}</p>
    </section>

    <section aria-labelledby="inspector-relationships-heading" className="account-inspector-section">
      <h3 id="inspector-relationships-heading">Relationships</h3>
      <p>{payload.relationships.contacts} contacts · {payload.relationships.observations} metric observations</p>
    </section>

    <nav aria-label="Account actions" className="account-inspector-actions">
      {payload.actions.map((action, index) => <a className={index === 0 ? "account-inspector-action account-inspector-action--primary" : "account-inspector-action"} href={action.href} key={action.href}>
        <ThemeIcon name={index === 0 ? "records" : "settings"} />
        {action.label}
      </a>)}
    </nav>
  </div>
}

function Detail({ label, value }: { label: string; value: string }) {
  return <div className="account-inspector-detail"><dt>{label}</dt><dd>{value}</dd></div>
}

function currency(cents: number) {
  return new Intl.NumberFormat("en-US", { currency: "USD", maximumFractionDigits: 0, style: "currency" }).format(cents / 100)
}
