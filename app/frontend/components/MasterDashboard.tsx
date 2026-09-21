// app/frontend/components/MasterDashboard.tsx

import ThemeIcon, { type ThemeIconName } from "./ThemeIcon"

type Tool = { label: string; description: string; icon: ThemeIconName; url: string }
export type MasterDashboardProps = {
  groups: { label: string; icon: ThemeIconName; tools: Tool[] }[]
  metrics: { label: string; value: string; detail: string }[]
}

export default function MasterDashboard({ groups, metrics }: MasterDashboardProps) {
  return <main className="bluebonnet-workspace master-workspace" aria-labelledby="master-workspace-title">
    <nav className="bluebonnet-context" aria-label="Workspace context">
      <span>Workspace</span><span aria-hidden="true">/</span><span>Operating home</span>
      <a className="bluebonnet-exit" href="/admin/architecture">How this Showcase works</a>
    </nav>
    <header className="master-heading">
      <div><p className="master-eyebrow">Texas Bluebonnet <span>Operating home</span></p><h1 id="master-workspace-title">Run the whole<br className="master-title-break" /> operation<span>.</span></h1><p>See what is moving, then step directly into the work.</p></div>
      <a className="master-primary" href="/admin/data_explorer?composition=bluebonnet">Explore accounts <span aria-hidden="true">↗</span></a>
    </header>
    <section className="master-overview" aria-labelledby="master-overview-title">
      <div className="master-section-heading"><h2 id="master-overview-title">Today’s operating picture</h2><span>Synthetic data · Rails-owned snapshot</span></div>
      <dl>{metrics.map(metric => <div key={metric.label}><dt>{metric.label}</dt><dd className="master-metric-value">{metric.value}</dd><dd className="master-metric-detail">{metric.detail}</dd></div>)}</dl>
    </section>
    <div className="master-section-heading master-launcher-heading"><h2>Choose a capability</h2><span>Grouped by the work, not the technology</span></div>
    <div className="master-domains">{groups.map((group, index) => {
      return <section className="master-domain" aria-labelledby={`master-domain-${index}`} key={group.label}>
        <header><span className="master-domain-number">0{index + 1}</span><h3 id={`master-domain-${index}`}><ThemeIcon name={group.icon} />{group.label}</h3></header>
        <ul>{group.tools.map(tool => <li key={tool.url}><a href={tool.url}><ThemeIcon name={tool.icon} /><span><strong>{tool.label}</strong><small>{tool.description}</small></span><span className="master-launch-arrow" aria-hidden="true">↗</span></a></li>)}</ul>
      </section>
    })}</div>
    <footer className="master-footer"><p>Rails owns the data, routes, permissions and no-JavaScript paths. React composes the operating home.</p><span>Workflow maps belong inside focused subdashboards, where their sequence has meaning.</span></footer>
  </main>
}
