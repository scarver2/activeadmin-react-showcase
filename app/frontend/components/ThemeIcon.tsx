// app/frontend/components/ThemeIcon.tsx

export type ThemeIconName = "dashboard" | "records" | "people" | "reports"

// Decorative only. The parent link/control always owns its visible label.
export default function ThemeIcon({ name, landmark = false }: { name: ThemeIconName, landmark?: boolean }) {
  return <svg aria-hidden="true" className="showcase-icon" focusable="false" viewBox="0 0 24 24">
    <use className={landmark ? "showcase-icon-default" : undefined} href={`/showcase-icons.svg#${name}`} />
    {landmark && <use className="showcase-icon-landmark" href="/showcase-icons.svg#landmark" />}
  </svg>
}
