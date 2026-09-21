// app/frontend/entrypoints/application.tsx

import "@activeadmin/activeadmin"
// Turbo must own navigation before the activeadmin-react lifecycle starts.
import "@hotwired/turbo-rails"
import "../styles/active_admin.css"

import { lazy, Suspense } from "react"

import { registerComponent, start } from "active_admin/react"

import AccountExplorer from "../components/AccountExplorer"
import ActivityCenter from "../components/ActivityCenter"
import AgentConsole from "../components/AgentConsole"
import type { AnalyticsDashboardProps } from "../components/AnalyticsDashboard"
import AuditHistory from "../components/AuditHistory"
import type { CalendarSchedulerProps } from "../components/CalendarScheduler"
import CommandPalette from "../components/CommandPalette"
import ContentBuilder from "../components/ContentBuilder"
import CsvImportWorkflow from "../components/CsvImportWorkflow"
import FileImageManager from "../components/FileImageManager"
import FoundationStatus from "../components/FoundationStatus"
import type { GeospatialExplorerProps } from "../components/GeospatialExplorer"
import HierarchyExplorer from "../components/HierarchyExplorer"
import ImageAnnotationEditor from "../components/ImageAnnotationEditor"
import InlineFieldEditor from "../components/InlineFieldEditor"
import KanbanWorkflow from "../components/KanbanWorkflow"
import type { LexicalEditorProps } from "../components/LexicalEditor"
import MasterDashboard from "../components/MasterDashboard"
import type { MaterialSphereStudioProps } from "../components/MaterialSphereStudio"
import MessagePreviewCenter from "../components/MessagePreviewCenter"
import NotificationBell from "../components/NotificationBell"
import OperationsCenter from "../components/OperationsCenter"
import OnboardingWizard from "../components/OnboardingWizard"
import OperatorChat from "../components/OperatorChat"
import RelationshipExplorer from "../components/RelationshipExplorer"
import SafeTerminal from "../components/SafeTerminal"
import type { SocialGraphExplorerProps } from "../components/SocialGraphExplorer"
import ThemeSwitcher from "../components/ThemeSwitcher"
import { startNativeNavigation } from "../navigation/nativeNavigation"

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
const MaterialSphereStudio = lazy(() => import("../components/MaterialSphereStudio"))
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

function LazyMaterialSphereStudio(props: MaterialSphereStudioProps) {
  return <Suspense fallback={<p role="status">Loading Three.js module…</p>}><MaterialSphereStudio {...props} /></Suspense>
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
registerComponent("ActivityCenter", ActivityCenter)
registerComponent("AgentConsole", AgentConsole)
registerComponent("AnalyticsDashboard", LazyAnalyticsDashboard)
registerComponent("AuditHistory", AuditHistory)
registerComponent("CalendarScheduler", LazyCalendarScheduler)
registerComponent("CommandPalette", CommandPalette)
registerComponent("ContentBuilder", ContentBuilder)
registerComponent("CsvImportWorkflow", CsvImportWorkflow)
registerComponent("FileImageManager", FileImageManager)
registerComponent("FoundationStatus", FoundationStatus)
registerComponent("GeospatialExplorer", LazyGeospatialExplorer)
registerComponent("HierarchyExplorer", HierarchyExplorer)
registerComponent("ImageAnnotationEditor", ImageAnnotationEditor)
registerComponent("InlineFieldEditor", InlineFieldEditor)
registerComponent("LexicalEditor", LexicalEditorIsland)
registerComponent("MasterDashboard", MasterDashboard)
registerComponent("MaterialSphereStudio", LazyMaterialSphereStudio)
registerComponent("MessagePreviewCenter", MessagePreviewCenter)
registerComponent("KanbanWorkflow", KanbanWorkflow)
registerComponent("NotificationBell", NotificationBell)
registerComponent("OperationsCenter", OperationsCenter)
registerComponent("OnboardingWizard", OnboardingWizard)
registerComponent("OperatorChat", OperatorChat)
registerComponent("RelationshipExplorer", RelationshipExplorer)
registerComponent("SafeTerminal", SafeTerminal)
registerComponent("SocialGraphExplorer", LazySocialGraphExplorer)
registerComponent("ThemeSwitcher", ThemeSwitcher)
startNativeNavigation()
start()
