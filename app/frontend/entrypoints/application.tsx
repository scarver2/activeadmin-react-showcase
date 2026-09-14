// app/frontend/entrypoints/application.tsx

import "@activeadmin/activeadmin"
// Turbo must own navigation before the activeadmin-react lifecycle starts.
import "@hotwired/turbo-rails"
import "../styles/active_admin.css"

import { lazy, Suspense } from "react"

import { registerComponent, start } from "active_admin/react"

import AccountExplorer from "../components/AccountExplorer"
import AgentConsole from "../components/AgentConsole"
import type { AnalyticsDashboardProps } from "../components/AnalyticsDashboard"
import type { CalendarSchedulerProps } from "../components/CalendarScheduler"
import CommandPalette from "../components/CommandPalette"
import ContentBuilder from "../components/ContentBuilder"
import FileImageManager from "../components/FileImageManager"
import FoundationStatus from "../components/FoundationStatus"
import type { GeospatialExplorerProps } from "../components/GeospatialExplorer"
import HierarchyExplorer from "../components/HierarchyExplorer"
import KanbanWorkflow from "../components/KanbanWorkflow"
import type { LexicalEditorProps } from "../components/LexicalEditor"
import OperationsCenter from "../components/OperationsCenter"
import OperatorChat from "../components/OperatorChat"
import RelationshipExplorer from "../components/RelationshipExplorer"
import SafeTerminal from "../components/SafeTerminal"
import type { SocialGraphExplorerProps } from "../components/SocialGraphExplorer"

const LexicalEditor = lazy(() => import("../components/LexicalEditor"))

function LexicalEditorIsland(props: LexicalEditorProps) {
  return (
    <Suspense fallback={<p>Loading rich editor…</p>}>
      <LexicalEditor {...props} />
    </Suspense>
  )
}

const AnalyticsDashboard = lazy(() => import("../components/AnalyticsDashboard"))

const CalendarScheduler = lazy(() => import("../components/CalendarScheduler"))
const GeospatialExplorer = lazy(() => import("../components/GeospatialExplorer"))
const SocialGraphExplorer = lazy(() => import("../components/SocialGraphExplorer"))

function LazyCalendarScheduler(props: CalendarSchedulerProps) {
  return (
    <Suspense fallback={<p aria-live="polite" role="status">Loading calendar module…</p>}>
      <CalendarScheduler {...props} />
    </Suspense>
  )
}

function LazyGeospatialExplorer(props: GeospatialExplorerProps) {
  return <Suspense fallback={<p aria-live="polite" role="status">Loading map module…</p>}><GeospatialExplorer {...props} /></Suspense>
}

function LazySocialGraphExplorer(props: SocialGraphExplorerProps) {
  return <Suspense fallback={<p role="status">Loading graph module…</p>}><SocialGraphExplorer {...props} /></Suspense>
}

function LazyAnalyticsDashboard(props: AnalyticsDashboardProps) {
  return (
    <Suspense fallback={<p aria-live="polite" role="status">Loading analytics module…</p>}>
      <AnalyticsDashboard {...props} />
    </Suspense>
  )
}

registerComponent("AccountExplorer", AccountExplorer)
registerComponent("AgentConsole", AgentConsole)
registerComponent("AnalyticsDashboard", LazyAnalyticsDashboard)
registerComponent("CalendarScheduler", LazyCalendarScheduler)
registerComponent("CommandPalette", CommandPalette)
registerComponent("ContentBuilder", ContentBuilder)
registerComponent("FileImageManager", FileImageManager)
registerComponent("FoundationStatus", FoundationStatus)
registerComponent("GeospatialExplorer", LazyGeospatialExplorer)
registerComponent("HierarchyExplorer", HierarchyExplorer)
registerComponent("LexicalEditor", LexicalEditorIsland)
registerComponent("KanbanWorkflow", KanbanWorkflow)
registerComponent("OperationsCenter", OperationsCenter)
registerComponent("OperatorChat", OperatorChat)
registerComponent("RelationshipExplorer", RelationshipExplorer)
registerComponent("SafeTerminal", SafeTerminal)
registerComponent("SocialGraphExplorer", LazySocialGraphExplorer)
start()
