# app/services/showcase/workspace_catalog.rb
# frozen_string_literal: true

module Showcase
  # Shared navigation vocabulary; destinations retain their own Rails authorization.
  class WorkspaceCatalog
    def self.groups
      routes = Rails.application.routes.url_helpers
      [
        { label: "Sales & Relationships", icon: "people", tools: [
          { label: "Account Data Explorer", description: "Compare the portfolio, plans and account activity.", url: routes.admin_data_explorer_path },
          { label: "Relationship Explorer", description: "Follow the connections between accounts and people.", url: routes.admin_relationship_explorer_path },
          { label: "Onboarding Wizard", description: "Guide a new account through a durable setup workflow.", url: routes.admin_onboarding_wizard_path }
        ] },
        { label: "Production & Content", icon: "production", tools: [
          { label: "Kanban Workflow", description: "Move work through its next production stage.", url: routes.admin_kanban_workflow_path },
          { label: "Content Builder", description: "Compose and preview structured content.", url: routes.admin_content_builder_path },
          { label: "File & Image Manager", description: "Organize the assets that support your work.", url: routes.admin_file_image_manager_path }
        ] },
        { label: "Operations", icon: "operations", tools: [
          { label: "Calendar Scheduler", description: "Coordinate the schedule and upcoming work.", url: routes.admin_calendar_scheduler_path },
          { label: "Live Jobs", description: "Inspect progress and manage background operations.", url: routes.admin_live_jobs_path },
          { label: "CSV Import Workflow", description: "Review, validate and confirm a bounded import.", url: routes.admin_csv_import_workflow_path }
        ] },
        { label: "Collaboration & Reporting", icon: "reporting", tools: [
          { label: "Activity Center", description: "Catch up on updates that need your attention.", url: routes.admin_activity_center_path },
          { label: "Operator Chat", description: "Keep operational conversations close to the work.", url: routes.admin_operator_chat_path },
          { label: "Analytics", description: "Read trends and compare business performance.", url: routes.admin_analytics_path }
        ] }
      ]
    end
  end
end
