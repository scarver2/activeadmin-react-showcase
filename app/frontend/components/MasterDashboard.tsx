// app/frontend/components/MasterDashboard.tsx

import { ArrowUpRightIcon, ChartBarIcon, Cog6ToothIcon, RectangleStackIcon, UsersIcon } from "@heroicons/react/24/outline"
import { useEffect, useState } from "react"

import { privacyEvent } from "./PrivacyMode"

const icons = { operations: Cog6ToothIcon, people: UsersIcon, production: RectangleStackIcon, reporting: ChartBarIcon }
type Tool = { label: string; description: string; url: string }
export type MasterDashboardProps = {
  groups: { label: string; icon: keyof typeof icons; tools: Tool[] }[]
  metrics: { label: string; value: string }[]
  privacyEnabled: boolean
}

export default function MasterDashboard({ groups, metrics, privacyEnabled }: MasterDashboardProps) {
  const [masked, setMasked] = useState(privacyEnabled)
  useEffect(() => {
    const update = (event: Event) => setMasked((event as CustomEvent<boolean>).detail)
    document.addEventListener(privacyEvent, update)
    return () => document.removeEventListener(privacyEvent, update)
  }, [])

  return <main className="master-workspace" aria-labelledby="master-workspace-title">
    <header className="master-heading">
      <div><p className="master-eyebrow">Showcase / Your working day</p><h1 id="master-workspace-title">A place for every part<br className="master-title-break" /> of the work<span>.</span></h1><p>Find your next move. Keep the whole operation in view.</p></div>
      <a className="master-primary" href="/admin/data_explorer">Explore accounts <ArrowUpRightIcon aria-hidden="true" /></a>
    </header>
    <section className="master-overview" aria-labelledby="master-overview-title">
      <div className="master-section-heading"><h2 id="master-overview-title">Operating picture</h2><span>Synthetic data · Today’s seeded snapshot</span></div>
      <dl>{metrics.map(metric => <div key={metric.label}><dt>{metric.label}</dt><dd className="master-private-value" data-testid="private-metric">{masked ? "Hidden" : metric.value}</dd></div>)}</dl>
      <p className="master-privacy-notice" role="status">{masked ? "Privacy Mode is on — dashboard totals are hidden." : "Privacy Mode is off — dashboard totals are visible."} <span>Presentation only; not access control.</span></p>
    </section>
    <div className="master-section-heading"><h2>Choose your workspace</h2><span>Tools grouped by the work, not the technology</span></div>
    <div className="master-domains">{groups.map(group => {
      const Icon = icons[group.icon]
      return <section className="master-domain" aria-label={group.label} key={group.label}>
        <h3><Icon aria-hidden="true" />{group.label}</h3>
        <ul>{group.tools.map(tool => <li key={tool.url}><a href={tool.url}><span><strong>{tool.label}</strong><small>{tool.description}</small></span><ArrowUpRightIcon aria-hidden="true" /></a></li>)}</ul>
      </section>
    })}</div>
    <footer className="master-footer"><p>Rails owns the data and permissions. React supports the work.</p><a href="/admin/architecture">Architecture & implementation notes</a></footer>
  </main>
}
