// app/frontend/entrypoints/application.tsx

import "@activeadmin/activeadmin"
// Turbo must own navigation before the activeadmin-react lifecycle starts.
import "@hotwired/turbo-rails"
import "../styles/active_admin.css"

import { registerComponent, start } from "active_admin/react"

import FoundationStatus from "../components/FoundationStatus"

registerComponent("FoundationStatus", FoundationStatus)
start()
