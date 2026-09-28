// app/frontend/components/MasterDashboard.tsx

import { useState } from "react"

import ThemeIcon, { type ThemeIconName } from "./ThemeIcon"

type Indicator = { icon: ThemeIconName; label: string; value: string }
type Tool = { label: string; description: string; icon: ThemeIconName; url: string }
type WorkspaceGroup = {
  label: string
  icon: ThemeIconName
  state: string
  stateTone: "attention" | "healthy" | "stable"
  summary: string
  whyItMatters: string
  updatedAt: string
  indicators: Indicator[]
  tools: Tool[]
}

export type MasterDashboardProps = {
  groups: WorkspaceGroup[]
  metrics: { label: string; value: string; detail: string; icon: ThemeIconName }[]
}

export default function MasterDashboard({ groups, metrics }: MasterDashboardProps) {
  const [previewedIndex, setPreviewedIndex] = useState<number | null>(null)
  const [pinnedIndex, setPinnedIndex] = useState<number | null>(null)
  const activeIndex = previewedIndex ?? pinnedIndex
  const activeGroup = activeIndex === null ? null : groups[activeIndex]

  function togglePinned(index: number) {
    setPinnedIndex(current => current === index ? null : index)
    setPreviewedIndex(null)
  }

  return <main
    className="bluebonnet-workspace master-workspace"
    aria-labelledby="master-workspace-title"
    onBlur={event => {
      if (!event.currentTarget.contains(event.relatedTarget)) setPreviewedIndex(null)
    }}
  >
    <nav className="bluebonnet-context" aria-label="Workspace context">
      <span>Workspace</span><span aria-hidden="true">/</span><span>Operating home</span>
      <a className="bluebonnet-exit" href="/admin/architecture">How this Showcase works</a>
    </nav>
    <header className="master-heading">
      <div>
        <p className="master-eyebrow">Texas Bluebonnet <span>Operating home</span></p>
        <h1 id="master-workspace-title">See the operation<span>.</span></h1>
      </div>
      <p className="master-instruction">Glance at state. Focus or tap a domain to inspect it.</p>
    </header>

    <section className="master-overview" aria-labelledby="master-overview-title">
      <div className="master-section-heading">
        <h2 id="master-overview-title">Across the operation</h2>
        <span>Synthetic Rails-owned snapshot</span>
      </div>
      <dl>{metrics.map(metric => <div key={metric.label}>
        <ThemeIcon name={metric.icon} />
        <dt>{metric.label}</dt>
        <dd className="master-metric-value">{metric.value}</dd>
        <dd className="master-metric-detail">{metric.detail}</dd>
      </div>)}</dl>
    </section>

    <div className="master-section-heading master-launcher-heading">
      <h2>Capability map</h2>
      <span>Major state first · supporting evidence second</span>
    </div>
    <div className="master-domain-grid" role="list">
      {groups.map((group, index) => {
        const active = activeIndex === index
        const pinned = pinnedIndex === index
        return <section
          className={`master-domain master-domain--${group.stateTone}${active ? " is-active" : ""}`}
          key={group.label}
          onMouseEnter={() => setPreviewedIndex(index)}
          onMouseLeave={() => setPreviewedIndex(null)}
          role="listitem"
        >
          <button
            aria-controls="master-domain-inspector"
            aria-expanded={active}
            aria-label={`${group.label}: ${group.state}. Inspect details${pinned ? ", pinned" : ""}`}
            className="master-domain-trigger"
            onClick={() => togglePinned(index)}
            onFocus={() => setPreviewedIndex(index)}
            type="button"
          >
            <span className="master-domain-icon"><ThemeIcon name={group.icon} /></span>
            <span className="master-domain-title">{group.label}</span>
            <span className="master-domain-state" data-tone={group.stateTone}>{group.state}</span>
            <span className="master-domain-indicators" aria-label={`${group.label} supporting indicators`}>
              {group.indicators.map(indicator => <span key={indicator.label} title={`${indicator.label}: ${indicator.value}`}>
                <ThemeIcon name={indicator.icon} />
                <strong>{indicator.value}</strong>
                <span className="sr-only">{indicator.label}</span>
              </span>)}
            </span>
            <span className="master-domain-cue" aria-hidden="true">{pinned ? "Pinned" : "Inspect"}</span>
          </button>
        </section>
      })}
    </div>

    <section
      aria-live="polite"
      className={`master-inspector${activeGroup ? " is-open" : ""}`}
      id="master-domain-inspector"
    >
      {activeGroup ? <>
        <header>
          <div className="master-inspector-title">
            <ThemeIcon name={activeGroup.icon} />
            <div><p>{activeGroup.state}</p><h2>{activeGroup.label}</h2></div>
          </div>
          <button aria-label="Close domain details" onClick={() => { setPinnedIndex(null); setPreviewedIndex(null) }} type="button">Close</button>
        </header>
        <div className="master-inspector-copy">
          <p>{activeGroup.summary}</p>
          <div><strong>Why it matters</strong><p>{activeGroup.whyItMatters}</p><small>Updated {activeGroup.updatedAt}</small></div>
        </div>
        <nav aria-label={`${activeGroup.label} actions`}>
          {activeGroup.tools.map((tool, index) => <a className={index === 0 ? "master-action-primary" : undefined} href={tool.url} key={tool.url}>
            <ThemeIcon name={tool.icon} />
            <span><strong>{tool.label}</strong><small>{tool.description}</small></span>
            <span aria-hidden="true">↗</span>
          </a>)}
        </nav>
      </> : <p className="master-inspector-rest">Focus, hover, or tap a domain to inspect its evidence and permitted actions.</p>}
    </section>

    <footer className="master-footer">
      <p>Rails owns state, routes, permissions and no-JavaScript paths. React owns disclosure.</p>
      <span>Workflow maps belong in focused subdashboards where sequence has meaning.</span>
    </footer>
  </main>
}
