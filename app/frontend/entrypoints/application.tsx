// app/frontend/entrypoints/application.tsx

import "@activeadmin/activeadmin"
// Turbo must own navigation before the activeadmin-react lifecycle starts.
import "@hotwired/turbo-rails"
import "../styles/active_admin.css"
import "../styles/saved_workspaces.css"
import "../styles/theme_studio.css"

import { lazy, Suspense } from "react"

import { registerComponent, start } from "active_admin/react"

import AccountExplorer from "../components/AccountExplorer"
import AccountInspectorLauncher from "../components/AccountInspectorLauncher"
import ActivityCenter from "../components/ActivityCenter"
import ActivityTimeline from "../components/ActivityTimeline"
import AgentConsole from "../components/AgentConsole"
import type { AnalyticsDashboardProps } from "../components/AnalyticsDashboard"
import AuditHistory from "../components/AuditHistory"
import BulkProgress from "../components/BulkProgress"
import type { CalendarSchedulerProps } from "../components/CalendarScheduler"
import type { CkeditorEditorProps } from "../components/CkeditorEditor"
import CommandPalette from "../components/CommandPalette"
import ConversationWorkspace from "../components/ConversationWorkspace"
import ContentBuilder from "../components/ContentBuilder"
import type { ContextualRelationshipsProps } from "../components/ContextualRelationships"
import CsvImportWorkflow from "../components/CsvImportWorkflow"
import FileImageManager from "../components/FileImageManager"
import FoundationStatus from "../components/FoundationStatus"
import type { GeospatialExplorerProps } from "../components/GeospatialExplorer"
import HandoffLiveHint from "../components/HandoffLiveHint"
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
import PrivacyView from "../components/PrivacyView"
import RelationshipExplorer from "../components/RelationshipExplorer"
import SafeTerminal from "../components/SafeTerminal"
import SavedViewEditor from "../components/SavedViewEditor"
import type { SocialGraphExplorerProps } from "../components/SocialGraphExplorer"
import ThemeStudio from "../components/ThemeStudio"
import ThemeSwitcher from "../components/ThemeSwitcher"
import type { TinyMceEditorProps } from "../components/TinyMceEditor"
import { startNativeNavigation } from "../navigation/nativeNavigation"

const LexicalEditor = lazy(() => import("../components/LexicalEditor"))
const CkeditorEditor = lazy(() => import("../components/CkeditorEditor"))

function CkeditorEditorIsland(props: CkeditorEditorProps) {
  return (
    <Suspense fallback={<p aria-live="polite" role="status">Loading CKEditor…</p>}>
      <CkeditorEditor {...props} />
    </Suspense>
  )
}

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
const ContextualRelationships = lazy(() => import("../components/ContextualRelationships"))
const TinyMceEditor = lazy(() => import("../components/TinyMceEditor"))

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

function LazyContextualRelationships(props: ContextualRelationshipsProps) {
  return <Suspense fallback={<p role="status">Loading relationships…</p>}><ContextualRelationships {...props} /></Suspense>
}

function LazyAnalyticsDashboard(props: AnalyticsDashboardProps) {
  return (
    <Suspense fallback={<p aria-live="polite" role="status">Loading analytics module…</p>}>
      <AnalyticsDashboard {...props} />
    </Suspense>
  )
}

function LazyTinyMceEditor(props: TinyMceEditorProps) {
  return (
    <Suspense fallback={<p aria-live="polite" role="status">Loading TinyMCE…</p>}>
      <TinyMceEditor {...props} />
    </Suspense>
  )
}

registerComponent("AccountExplorer", AccountExplorer)
registerComponent("AccountInspectorLauncher", AccountInspectorLauncher)
registerComponent("ActivityCenter", ActivityCenter)
registerComponent("ActivityTimeline", ActivityTimeline)
registerComponent("AgentConsole", AgentConsole)
registerComponent("AnalyticsDashboard", LazyAnalyticsDashboard)
registerComponent("AuditHistory", AuditHistory)
registerComponent("BulkProgress", BulkProgress)
registerComponent("CalendarScheduler", LazyCalendarScheduler)
registerComponent("CkeditorEditor", CkeditorEditorIsland)
registerComponent("CommandPalette", CommandPalette)
registerComponent("ConversationWorkspace", ConversationWorkspace)
registerComponent("ContentBuilder", ContentBuilder)
registerComponent("ContextualRelationships", LazyContextualRelationships)
registerComponent("CsvImportWorkflow", CsvImportWorkflow)
registerComponent("FileImageManager", FileImageManager)
registerComponent("HandoffLiveHint", HandoffLiveHint)
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
registerComponent("PrivacyView", PrivacyView)
registerComponent("RelationshipExplorer", RelationshipExplorer)
registerComponent("SafeTerminal", SafeTerminal)
registerComponent("SavedViewEditor", SavedViewEditor)
registerComponent("SocialGraphExplorer", LazySocialGraphExplorer)
registerComponent("ThemeStudio", ThemeStudio)
registerComponent("ThemeSwitcher", ThemeSwitcher)
registerComponent("TinyMceEditor", LazyTinyMceEditor)
startNativeNavigation()
start()
