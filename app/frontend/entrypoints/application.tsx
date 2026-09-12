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
import CommandPalette from "../components/CommandPalette"
import FileImageManager from "../components/FileImageManager"
import FoundationStatus from "../components/FoundationStatus"
import KanbanWorkflow from "../components/KanbanWorkflow"
import type { LexicalEditorProps } from "../components/LexicalEditor"
import OperationsCenter from "../components/OperationsCenter"
import OperatorChat from "../components/OperatorChat"
import RelationshipExplorer from "../components/RelationshipExplorer"

const LexicalEditor = lazy(() => import("../components/LexicalEditor"))

function LexicalEditorIsland(props: LexicalEditorProps) {
  return (
    <Suspense fallback={<p>Loading rich editor…</p>}>
      <LexicalEditor {...props} />
    </Suspense>
  )
}

const AnalyticsDashboard = lazy(() => import("../components/AnalyticsDashboard"))

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
registerComponent("CommandPalette", CommandPalette)
registerComponent("FileImageManager", FileImageManager)
registerComponent("FoundationStatus", FoundationStatus)
registerComponent("LexicalEditor", LexicalEditorIsland)
registerComponent("KanbanWorkflow", KanbanWorkflow)
registerComponent("OperationsCenter", OperationsCenter)
registerComponent("OperatorChat", OperatorChat)
registerComponent("RelationshipExplorer", RelationshipExplorer)
start()
