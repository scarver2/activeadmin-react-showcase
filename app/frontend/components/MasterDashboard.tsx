// app/frontend/components/MasterDashboard.tsx

import ThemeIcon, { type ThemeIconName } from "./ThemeIcon"

type Tool = { label: string; description: string; url: string }
export type MasterDashboardProps = {
  groups: { label: string; icon: ThemeIconName; tools: Tool[] }[]
  metrics: { label: string; value: string }[]
}

export default function MasterDashboard({ groups, metrics }: MasterDashboardProps) {
  return <main className="master-workspace" aria-labelledby="master-workspace-title">
    <header className="master-heading">
      <div><p className="master-eyebrow">Showcase / Your working day</p><h1 id="master-workspace-title">A place for every part<br className="master-title-break" /> of the work<span>.</span></h1><p>Find your next move. Keep the whole operation in view.</p></div>
      <a className="master-primary" href="/admin/data_explorer">Explore accounts <span aria-hidden="true">↗</span></a>
    </header>
    <section className="master-overview" aria-labelledby="master-overview-title">
      <div className="master-section-heading"><h2 id="master-overview-title">Operating picture</h2><span>Synthetic data · Today’s seeded snapshot</span></div>
      <dl>{metrics.map(metric => <div key={metric.label}><dt>{metric.label}</dt><dd className="master-metric-value">{metric.value}</dd></div>)}</dl>
    </section>
    <div className="master-section-heading"><h2>Choose your workspace</h2><span>Tools grouped by the work, not the technology</span></div>
    <div className="master-domains">{groups.map(group => {
      return <section className="master-domain" aria-label={group.label} key={group.label}>
        <h3><ThemeIcon name={group.icon} />{group.label}</h3>
        <ul>{group.tools.map(tool => <li key={tool.url}><a href={tool.url}><span><strong>{tool.label}</strong><small>{tool.description}</small></span><span aria-hidden="true">↗</span></a></li>)}</ul>
      </section>
    })}</div>
    <footer className="master-footer"><p>Rails owns the data and permissions. React supports the work.</p><a href="/admin/architecture">Architecture & implementation notes</a></footer>
  </main>
}
