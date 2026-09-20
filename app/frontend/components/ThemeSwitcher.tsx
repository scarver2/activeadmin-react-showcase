// app/frontend/components/ThemeSwitcher.tsx

import { useRef, useState } from "react"

type Theme = { label: string, value: string }
type Props = { currentTheme: string, themes: Theme[], updateUrl: string }

function csrfToken() {
  return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""
}

export default function ThemeSwitcher({ currentTheme, themes, updateUrl }: Props) {
  const root = useRef<HTMLDivElement>(null)
  const [selected, setSelected] = useState(currentTheme)
  const [error, setError] = useState<string | null>(null)

  function apply(theme: string) {
    root.current?.closest<HTMLElement>("[data-showcase-theme-marker]")?.setAttribute("data-showcase-theme-marker", theme)
  }

  async function change(theme: string) {
    const previous = selected
    setSelected(theme)
    setError(null)
    apply(theme)

    try {
      const response = await fetch(updateUrl, {
        body: JSON.stringify({ theme_preference: theme }),
        credentials: "same-origin",
        headers: { Accept: "application/json", "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        method: "PATCH"
      })
      const payload = await response.json()
      if (!response.ok) throw new Error(payload.error || "Palette preference could not be saved")
      setSelected(payload.theme)
      apply(payload.theme)
    } catch (requestError) {
      setSelected(previous)
      apply(previous)
      setError((requestError as Error).message)
    }
  }

  return <div className="theme-switcher" data-testid="theme-switcher" ref={root}>
    <label htmlFor="showcase-theme">Color palette</label>
    <select aria-describedby={error ? "showcase-theme-error" : undefined} id="showcase-theme" onChange={(event) => void change(event.target.value)} value={selected}>
      {themes.map((theme) => <option key={theme.value} value={theme.value}>{theme.label}</option>)}
    </select>
    {error && <span id="showcase-theme-error" role="alert">{error}</span>}
  </div>
}
