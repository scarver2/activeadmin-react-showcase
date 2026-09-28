# app/services/showcase/workspace_catalog.rb
# frozen_string_literal: true

module Showcase
  # Server-owned demonstration state and authorized Rails destinations for the operating home.
  class WorkspaceCatalog
    def self.groups
      routes = Rails.application.routes.url_helpers
      [
        {
          label: "Sales & Relationships", icon: "people", state: "Healthy", stateTone: "healthy",
          summary: "The portfolio is active and the relationship pipeline is moving without a broad exception.",
          whyItMatters: "New work can enter the operation without losing the account and contact context behind it.",
          updatedAt: "moments ago",
          indicators: [
            { label: "Accounts", value: Account.count.to_s, icon: "customers" },
            { label: "Contacts", value: Contact.count.to_s, icon: "people" },
            { label: "New work", value: OnboardingDraft.where(status: "draft").count.to_s, icon: "records" }
          ],
          tools: [
            { label: "Account Data Explorer", description: "Compare portfolio plans and activity.", icon: "dashboard", url: routes.admin_data_explorer_path },
            { label: "Relationship Explorer", description: "Follow connections between accounts and people.", icon: "people", url: routes.admin_relationship_explorer_path },
            { label: "Onboarding Wizard", description: "Guide a new account through setup.", icon: "records", url: routes.admin_onboarding_wizard_path }
          ]
        },
        {
          label: "Production & Content", icon: "records", state: "Attention", stateTone: "attention",
          summary: "Content and workflow tools are available, with a small amount of work waiting for an operator.",
          whyItMatters: "Unreviewed production work can delay every downstream handoff even while the wider system looks calm.",
          updatedAt: "2 minutes ago",
          indicators: [
            { label: "Documents", value: ContentDocument.count.to_s, icon: "records" },
            { label: "Assets", value: ShowcaseAsset.count.to_s, icon: "dashboard" },
            { label: "Queued imports", value: CsvImport.where(status: "draft").count.to_s, icon: "settings" }
          ],
          tools: [
            { label: "Kanban Workflow", description: "Move work through its next stage.", icon: "settings", url: routes.admin_kanban_workflow_path },
            { label: "Content Builder", description: "Compose and preview structured content.", icon: "records", url: routes.admin_content_builder_path },
            { label: "File & Image Manager", description: "Organize supporting visual assets.", icon: "dashboard", url: routes.admin_file_image_manager_path }
          ]
        },
        {
          label: "Operations", icon: "settings", state: "Stable", stateTone: "stable",
          summary: "Scheduled work and background operations are within the synthetic operating envelope.",
          whyItMatters: "Stable execution protects the promises made elsewhere in the workspace.",
          updatedAt: "just now",
          indicators: [
            { label: "Calendar", value: "7d", icon: "calendar" },
            { label: "Live jobs", value: AgentRun.where(state: %w[queued running]).count.to_s, icon: "settings" },
            { label: "Imports", value: CsvImport.where(status: "confirmed").count.to_s, icon: "records" }
          ],
          tools: [
            { label: "Calendar Scheduler", description: "Coordinate upcoming work.", icon: "calendar", url: routes.admin_calendar_scheduler_path },
            { label: "Live Jobs", description: "Inspect background operations.", icon: "settings", url: routes.admin_live_jobs_path },
            { label: "CSV Import Workflow", description: "Validate and confirm a bounded import.", icon: "records", url: routes.admin_csv_import_workflow_path }
          ]
        },
        {
          label: "Collaboration & Reporting", icon: "reports", state: "Healthy", stateTone: "healthy",
          summary: "Activity, conversation, and reporting surfaces are current enough for the next operator decision.",
          whyItMatters: "Shared context keeps decisions explainable and lets the next person enter the work quickly.",
          updatedAt: "moments ago",
          indicators: [
            { label: "Unread activity", value: ActivityNotification.unread.count.to_s, icon: "dashboard" },
            { label: "Messages", value: ChatMessage.count.to_s, icon: "people" },
            { label: "Reports", value: "3", icon: "reports" }
          ],
          tools: [
            { label: "Activity Center", description: "Review updates needing attention.", icon: "dashboard", url: routes.admin_activity_center_path },
            { label: "Operator Chat", description: "Keep conversations close to the work.", icon: "people", url: routes.admin_operator_chat_path },
            { label: "Analytics", description: "Compare business performance.", icon: "reports", url: routes.admin_analytics_path }
          ]
        }
      ]
    end
  end
end
