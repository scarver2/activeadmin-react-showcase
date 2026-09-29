// app/frontend/components/ThemeStudio.tsx

import { type CSSProperties, useMemo, useState } from "react"

import ThemeIcon from "./ThemeIcon"

type Architecture = {
  activeAdminRequirement: string
  composition: { description: string, key: string, name: string, parts: string[], slots: Record<string, string> }
  recipeVersion: string
  skin: { description: string, key: string, name: string, parts: string[] }
  theme: { key: string, name: string }
}
type ColorToken = { dark: string, key: string, label: string, light: string }
type ValueToken = { key: string, label: string, value: string }
export type ThemeStudioProps = {
  architecture: Architecture
  colors: ColorToken[]
  geometry: ValueToken[]
  typography: ValueToken[]
}
type Scheme = "dark" | "light"
type Surface = "dashboard" | "detail" | "form" | "table"
type Viewport = "desktop" | "narrow" | "tablet"
type EditorState = {
  colors: Record<Scheme, Record<string, string>>
  geometry: Record<string, string>
  typography: Record<string, string>
}

const GEOMETRY_OPTIONS: Record<string, string[]> = {
  border_width: ["1px", "2px"],
  control_height: ["2.25rem", "2.75rem", "3rem"],
  page_gutter: ["1rem", "1.875rem", "2.5rem"],
  radius: ["0", "0.25rem", "0.5rem"]
}
const TYPOGRAPHY_OPTIONS: Record<string, { label: string, value: string }[]> = {
  font: [
    { label: "System sans", value: '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif' },
    { label: "Humanist sans", value: '"Trebuchet MS", ui-sans-serif, sans-serif' },
    { label: "System serif", value: 'ui-serif, Georgia, "Times New Roman", serif' }
  ],
  line_height: ["1.4", "1.5", "1.65"].map(value => ({ label: value, value })),
  text_size: [
    { label: "Compact · 13px", value: "0.8125rem" },
    { label: "Default · 14px", value: "0.875rem" },
    { label: "Large · 16px", value: "1rem" }
  ]
}

function initialState({ colors, geometry, typography }: ThemeStudioProps): EditorState {
  return {
    colors: {
      dark: Object.fromEntries(colors.map(token => [token.key, token.dark])),
      light: Object.fromEntries(colors.map(token => [token.key, token.light]))
    },
    geometry: Object.fromEntries(geometry.map(token => [token.key, token.value])),
    typography: Object.fromEntries(typography.map(token => [token.key, token.value]))
  }
}

function channel(value: string) {
  const normalized = value.replace("#", "")
  return [0, 2, 4].map(offset => Number.parseInt(normalized.slice(offset, offset + 2), 16) / 255)
}

function luminance(value: string) {
  const [red, green, blue] = channel(value).map(component => component <= 0.03928 ? component / 12.92 : ((component + 0.055) / 1.055) ** 2.4)
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue
}

function contrast(foreground: string, background: string) {
  const values = [luminance(foreground), luminance(background)].sort((left, right) => right - left)
  return (values[0] + 0.05) / (values[1] + 0.05)
}

function contrastLabel(value: number, minimum: number) {
  return `${value.toFixed(2)}:1 · ${value >= minimum ? "passes this automated check" : `below ${minimum}:1 target`}`
}

function serializeProposal(architecture: Architecture, state: EditorState) {
  const lines = [
    "# Theme Studio authoring proposal — not an importable runtime format yet",
    "theme:",
    "  key: studio_v3",
    `  extends: ${architecture.theme.key}`,
    `  recipe_version: ${JSON.stringify(architecture.recipeVersion)}`,
    "skin:",
    `  key: ${architecture.skin.key}`,
    "  manifest:",
    ...architecture.skin.parts.map(part => `    - ${part}`),
    "  tokens:"
  ]
  for (const scheme of ["light", "dark"] as const) {
    lines.push(`    ${scheme}:`)
    for (const key of Object.keys(state.colors[scheme]).sort()) lines.push(`      ${key}: ${JSON.stringify(state.colors[scheme][key])}`)
  }
  lines.push("  typography:")
  for (const key of Object.keys(state.typography).sort()) lines.push(`    ${key}: ${JSON.stringify(state.typography[key])}`)
  lines.push("  geometry:")
  for (const key of Object.keys(state.geometry).sort()) lines.push(`    ${key}: ${JSON.stringify(state.geometry[key])}`)
  lines.push("composition:", `  key: ${architecture.composition.key}`, "  manifest:")
  for (const part of architecture.composition.parts) lines.push(`    - ${part}`)
  return lines.join("\n")
}

function DashboardPreview() {
  return <div className="grid gap-3 sm:grid-cols-3">
    {["Accounts", "Open reviews", "Monthly volume"].map((label, index) => <section className="rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)] p-4" key={label}>
      <p className="text-[var(--aat-muted)]">{label}</p><strong className="mt-2 block text-2xl">{[128, 14, "$482k"][index]}</strong>
    </section>)}
  </div>
}

function DetailPreview() {
  return <section className="rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)] p-4">
    <h4 className="font-bold">Account details</h4>
    <dl className="mt-3 grid grid-cols-2 gap-3"><dt className="text-[var(--aat-muted)]">Owner</dt><dd>Avery Morgan</dd><dt className="text-[var(--aat-muted)]">Status</dt><dd><span className="rounded-[var(--aat-radius)] bg-[var(--aat-success-bg)] px-2 py-1 text-[var(--aat-success)]">Active</span></dd><dt className="text-[var(--aat-muted)]">Region</dt><dd>Central Texas</dd></dl>
  </section>
}

function FormPreview() {
  return <form className="rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)] p-4" onSubmit={event => event.preventDefault()}>
    <h4 className="font-bold">Edit account</h4><label className="mt-3 block" htmlFor="studio-name">Name</label><input className="mt-1 w-full rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-background)] px-3" defaultValue="Bluebonnet Logistics" id="studio-name" style={{ minHeight: "var(--aat-control-height)" }} />
    <p className="mt-2 rounded-[var(--aat-radius)] bg-[var(--aat-danger-bg)] p-2 text-[var(--aat-danger)]">Example validation: account code is required.</p><button className="mt-3 rounded-[var(--aat-radius)] bg-[var(--aat-chrome)] px-4 text-[var(--aat-chrome-text)]" style={{ minHeight: "var(--aat-control-height)" }} type="submit">Save account</button>
  </form>
}

function TablePreview() {
  return <div className="overflow-x-auto rounded-[var(--aat-radius)] border border-[var(--aat-border)] bg-[var(--aat-surface)]"><table className="w-full text-left"><thead className="bg-[var(--aat-subtle)]"><tr><th className="p-3">Account</th><th className="p-3">Status</th><th className="p-3">Balance</th></tr></thead><tbody>{[["Bluebonnet Logistics", "Active", "$18,420"], ["Hill Country Supply", "Review", "$7,800"], ["Rio Grande Works", "Active", "$12,110"]].map(row => <tr className="border-t border-[var(--aat-border)]" key={row[0]}>{row.map(cell => <td className="p-3" key={cell}>{cell}</td>)}</tr>)}</tbody></table></div>
}

export default function ThemeStudio(props: ThemeStudioProps) {
  const [state, setState] = useState(() => initialState(props))
  const [scheme, setScheme] = useState<Scheme>("light")
  const [surface, setSurface] = useState<Surface>("table")
  const [viewport, setViewport] = useState<Viewport>("desktop")
  const palette = state.colors[scheme]
  const previewStyle = {
    "--aat-border-width": state.geometry.border_width,
    "--aat-control-height": state.geometry.control_height,
    "--aat-font": state.typography.font,
    "--aat-line-height": state.typography.line_height,
    "--aat-page-gutter": state.geometry.page_gutter,
    "--aat-radius": state.geometry.radius,
    "--aat-text-size": state.typography.text_size,
    borderWidth: state.geometry.border_width,
    fontFamily: state.typography.font,
    fontSize: state.typography.text_size,
    lineHeight: state.typography.line_height,
    ...Object.fromEntries(Object.entries(palette).map(([key, value]) => [`--aat-${key.replaceAll("_", "-")}`, value]))
  } as CSSProperties
  const report = useMemo(() => [
    { label: "Body text / canvas", minimum: 4.5, value: contrast(palette.text, palette.background) },
    { label: "Muted text / canvas", minimum: 4.5, value: contrast(palette.muted, palette.background) },
    { label: "Link / canvas", minimum: 4.5, value: contrast(palette.link, palette.background) },
    { label: "Focus / canvas", minimum: 3, value: contrast(palette.focus, palette.background) },
    { label: "Danger / danger surface", minimum: 4.5, value: contrast(palette.danger, palette.danger_bg) },
    { label: "Success / success surface", minimum: 4.5, value: contrast(palette.success, palette.success_bg) },
    { label: "Warning / warning surface", minimum: 4.5, value: contrast(palette.warning, palette.warning_bg) }
  ], [palette])
  const proposal = useMemo(() => serializeProposal(props.architecture, state), [props.architecture, state])

  function updateColor(key: string, value: string) {
    setState(current => ({ ...current, colors: { ...current.colors, [scheme]: { ...current.colors[scheme], [key]: value } } }))
  }

  function updateValue(group: "geometry" | "typography", key: string, value: string) {
    setState(current => ({ ...current, [group]: { ...current[group], [key]: value } }))
  }

  return <section aria-labelledby="theme-studio-heading" className="theme-studio space-y-6" data-testid="theme-studio">
    <header className="rounded-lg border border-gray-300 bg-white p-5 shadow-sm dark:border-gray-700 dark:bg-gray-900">
      <p className="text-sm font-semibold uppercase tracking-wide text-indigo-700 dark:text-indigo-300">Showcase-only authoring laboratory</p>
      <h2 className="mt-1 text-2xl font-bold" id="theme-studio-heading">{props.architecture.theme.name} semantic editor</h2>
      <p className="mt-2 max-w-4xl">Theme = the {props.architecture.composition.name} composition plus the {props.architecture.skin.name} skin. This prototype edits allowlisted semantic tokens; the installed composition manifest and its slots stay immutable.</p>
      <dl className="mt-4 grid gap-3 text-sm sm:grid-cols-3"><div><dt className="font-semibold">Recipe</dt><dd>Version {props.architecture.recipeVersion}</dd></div><div><dt className="font-semibold">Skin source</dt><dd>{props.architecture.skin.parts.join(", ")}</dd></div><div><dt className="font-semibold">Composition concerns</dt><dd>{props.architecture.composition.parts.length} ordered parts</dd></div></dl>
    </header>

    <div className="grid gap-6 xl:grid-cols-[minmax(18rem,24rem)_1fr]">
      <aside aria-label="Theme controls" className="space-y-5 rounded-lg border border-gray-300 bg-white p-5 dark:border-gray-700 dark:bg-gray-900">
        <div className="flex items-center justify-between gap-3"><h3 className="text-lg font-bold"><ThemeIcon name="settings" /> Editor</h3><button className="rounded border px-3 py-2" onClick={() => setState(initialState(props))} type="button">Reset</button></div>
        <fieldset><legend className="font-semibold">Preview color scheme</legend><div className="mt-2 flex gap-2">{(["light", "dark"] as const).map(value => <button aria-pressed={scheme === value} className="rounded border px-3 py-2 capitalize aria-pressed:bg-indigo-700 aria-pressed:text-white" key={value} onClick={() => setScheme(value)} type="button">{value}</button>)}</div></fieldset>
        <fieldset><legend className="font-semibold">Semantic skin colors</legend><div className="mt-2 grid grid-cols-2 gap-3">{props.colors.map(token => <label className="text-sm" key={token.key}>{token.label}<span className="mt-1 flex items-center gap-2"><input aria-label={`${token.label} ${scheme}`} className="h-10 w-12 rounded border" onChange={event => updateColor(token.key, event.target.value)} type="color" value={palette[token.key]} /><code>{palette[token.key]}</code></span></label>)}</div></fieldset>
        <fieldset><legend className="font-semibold">Typography</legend><div className="mt-2 space-y-3">{props.typography.map(token => <label className="block text-sm" key={token.key}>{token.label}<select className="mt-1 block w-full rounded border p-2" onChange={event => updateValue("typography", token.key, event.target.value)} value={state.typography[token.key]}>{TYPOGRAPHY_OPTIONS[token.key].map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select></label>)}</div></fieldset>
        <fieldset><legend className="font-semibold">Geometry</legend><div className="mt-2 space-y-3">{props.geometry.map(token => <label className="block text-sm" key={token.key}>{token.label}<select className="mt-1 block w-full rounded border p-2" onChange={event => updateValue("geometry", token.key, event.target.value)} value={state.geometry[token.key]}>{GEOMETRY_OPTIONS[token.key].map(value => <option key={value} value={value}>{value}</option>)}</select></label>)}</div></fieldset>
        <section aria-labelledby="composition-boundary-heading" className="rounded border border-amber-500 bg-amber-50 p-3 text-amber-950 dark:bg-amber-950 dark:text-amber-50"><h4 className="font-bold" id="composition-boundary-heading">Composition is fixed</h4><p className="text-sm">{props.architecture.composition.description} Version 0.2.0 declares no interchangeable V3 layout candidates, so Studio does not fabricate them.</p></section>
      </aside>

      <div className="space-y-5">
        <div className="flex flex-wrap items-end justify-between gap-4 rounded-lg border border-gray-300 bg-white p-4 dark:border-gray-700 dark:bg-gray-900"><div><label className="block text-sm font-semibold" htmlFor="studio-surface">Surface</label><select className="mt-1 rounded border p-2" id="studio-surface" onChange={event => setSurface(event.target.value as Surface)} value={surface}><option value="table">Index / table</option><option value="detail">Show / detail</option><option value="form">Form / validation</option><option value="dashboard">Dashboard</option></select></div><div><span className="block text-sm font-semibold">Viewport</span><div className="mt-1 flex gap-2">{(["desktop", "tablet", "narrow"] as const).map(value => <button aria-pressed={viewport === value} className="rounded border px-3 py-2 capitalize aria-pressed:bg-indigo-700 aria-pressed:text-white" key={value} onClick={() => setViewport(value)} type="button">{value}</button>)}</div></div></div>
        <div className="overflow-auto rounded-lg bg-gray-200 p-3 dark:bg-gray-950"><section className={`mx-auto min-h-[30rem] max-w-full border-[var(--aat-border)] bg-[var(--aat-background)] p-[var(--aat-page-gutter)] text-[var(--aat-text)] shadow-lg transition-[width] ${viewport === "desktop" ? "w-full" : viewport === "tablet" ? "w-[48rem]" : "w-[24rem]"}`} data-scheme={scheme} style={previewStyle}>
          <nav aria-label="Preview navigation" className="mb-5 flex flex-wrap items-center gap-3 rounded-[var(--aat-radius)] bg-[var(--aat-chrome)] p-3 text-[var(--aat-chrome-text)]"><strong className="mr-auto">Northstar Admin</strong><a className="text-inherit" href="#preview-content" onClick={event => event.preventDefault()}><ThemeIcon name="dashboard" /> Dashboard</a><a className="text-inherit" href="#preview-content" onClick={event => event.preventDefault()}><ThemeIcon name="records" /> Accounts</a></nav>
          <header className="mb-5"><p className="text-[var(--aat-link)]">Operations / Accounts</p><h3 className="text-2xl font-bold">Account workspace</h3><p className="text-[var(--aat-muted)]">Representative Rails-owned data and actions.</p></header>
          <main id="preview-content">{surface === "table" ? <TablePreview /> : surface === "detail" ? <DetailPreview /> : surface === "form" ? <FormPreview /> : <DashboardPreview />}</main>
        </section></div>
      </div>
    </div>

    <section aria-labelledby="guardrails-heading" className="rounded-lg border border-gray-300 bg-white p-5 dark:border-gray-700 dark:bg-gray-900"><h3 className="text-lg font-bold" id="guardrails-heading">Live accessibility guardrails</h3><p className="mt-1 text-sm">Automated contrast and size checks are design feedback, not a WCAG conformance claim.</p><ul aria-live="polite" className="mt-3 grid gap-2 sm:grid-cols-2">{report.map(check => <li className={`rounded border p-3 ${check.value >= check.minimum ? "border-green-600" : "border-red-600"}`} key={check.label}><strong>{check.label}</strong><br />{contrastLabel(check.value, check.minimum)}</li>)}<li className={`rounded border p-3 ${Number.parseFloat(state.geometry.control_height) * 16 >= 44 ? "border-green-600" : "border-amber-600"}`}><strong>Coarse-pointer control height</strong><br />{Number.parseFloat(state.geometry.control_height) * 16}px · {Number.parseFloat(state.geometry.control_height) * 16 >= 44 ? "meets 44px studio target" : "consider at least 44px"}</li><li className="rounded border border-green-600 p-3"><strong>Token completeness</strong><br />All {props.colors.length} roles have light and dark values.</li></ul></section>

    <section aria-labelledby="recipe-preview-heading" className="rounded-lg border border-gray-300 bg-white p-5 dark:border-gray-700 dark:bg-gray-900"><h3 className="text-lg font-bold" id="recipe-preview-heading">Deterministic recipe proposal</h3><p className="mt-1">This review artifact mirrors the installed skin/composition manifests. It is deliberately labelled non-importable until the upstream composer defines an authoring schema.</p><pre className="mt-3 max-h-[32rem] overflow-auto rounded bg-gray-950 p-4 text-sm text-gray-100" data-testid="recipe-proposal"><code>{proposal}</code></pre></section>
  </section>
}
