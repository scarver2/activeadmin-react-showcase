// app/frontend/entrypoints/application.tsx

import "@activeadmin/activeadmin"
// Turbo must own navigation before the activeadmin-react lifecycle starts.
import "@hotwired/turbo-rails"
import "../styles/active_admin.css"

import { registerComponent, start } from "active_admin/react"
import { lazy, Suspense } from "react"

import FoundationStatus from "../components/FoundationStatus"
import type { LexicalEditorProps } from "../components/LexicalEditor"

const LexicalEditor = lazy(() => import("../components/LexicalEditor"))

function LexicalEditorIsland(props: LexicalEditorProps) {
  return (
    <Suspense fallback={<p>Loading rich editor…</p>}>
      <LexicalEditor {...props} />
    </Suspense>
  )
}

registerComponent("FoundationStatus", FoundationStatus)
registerComponent("LexicalEditor", LexicalEditorIsland)
start()
