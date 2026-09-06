// app/frontend/entrypoints/application.tsx

import "@activeadmin/activeadmin"
// Turbo must own navigation before the activeadmin-react lifecycle starts.
import "@hotwired/turbo-rails"
import "../styles/active_admin.css"

import { lazy, Suspense } from "react"

import { registerComponent, start } from "active_admin/react"

import type { AnalyticsDashboardProps } from "../components/AnalyticsDashboard"
import FoundationStatus from "../components/FoundationStatus"

const AnalyticsDashboard = lazy(() => import("../components/AnalyticsDashboard"))

function LazyAnalyticsDashboard(props: AnalyticsDashboardProps) {
  return (
    <Suspense fallback={<p aria-live="polite" role="status">Loading analytics module…</p>}>
      <AnalyticsDashboard {...props} />
    </Suspense>
  )
}

registerComponent("AnalyticsDashboard", LazyAnalyticsDashboard)
registerComponent("FoundationStatus", FoundationStatus)
start()
