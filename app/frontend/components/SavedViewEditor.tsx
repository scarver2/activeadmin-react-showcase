// app/frontend/components/SavedViewEditor.tsx

import { useState } from "react"

type Definition = { schema: number; query: string; plan: string; status: string; sort: string; direction: string; per_page: number | string; columns: string[]; group: string; density: string }
type Props = { definition: Definition; columns: string[]; plans: string[]; statuses: string[] }

export default function SavedViewEditor({ definition, columns, plans, statuses }: Props) {
  const [value, setValue] = useState(definition)
  const choices = { plan: ["", ...plans], status: ["", ...statuses], sort: ["name", "plan", "region", "status"], direction: ["asc", "desc"], per_page: ["5", "10", "20"], group: ["none", "plan", "region", "status"], density: ["compact", "comfortable", "spacious"] }
  return <fieldset className="saved-view-editor">
    <legend>Account view definition</legend>
    <input name="saved_view[definition][schema]" type="hidden" value="1" />
    <label>Search name<input maxLength={80} name="saved_view[definition][query]" onChange={event => setValue({ ...value, query: event.target.value })} value={value.query} /></label>
    {Object.entries(choices).map(([field, options]) => <label key={field}>{field.replace("_", " ")}<select name={`saved_view[definition][${field}]`} onChange={event => setValue({ ...value, [field]: event.target.value })} value={String(value[field as keyof typeof choices])}>{options.map(option => <option key={option} value={option}>{option || "All"}</option>)}</select></label>)}
    <input name="saved_view[definition][columns][]" type="hidden" value="name" />
    <p>Name is always visible.</p>
    {columns.filter(column => column !== "name").map(column => <label key={column}><input checked={value.columns.includes(column)} name="saved_view[definition][columns][]" onChange={event => setValue({ ...value, columns: event.target.checked ? [...value.columns, column] : value.columns.filter(selected => selected !== column) })} type="checkbox" value={column} />{column}</label>)}
    <p aria-live="polite">{value.columns.length} columns · {value.density} density · group: {value.group}. Save to apply this personal view.</p>
  </fieldset>
}
