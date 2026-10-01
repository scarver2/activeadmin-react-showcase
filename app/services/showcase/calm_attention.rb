# app/services/showcase/calm_attention.rb
# frozen_string_literal: true

module Showcase
  class CalmAttention
    SCENARIOS = %w[live exceptions healthy].freeze
    GROUPS = [ [ "urgent", "Urgent" ], [ "actionable", "Needs action" ], [ "fyi", "For awareness" ] ].freeze
    LIMIT = 3

    def initialize(admin_user:, scenario: "live")
      raise ArgumentError, "Unsupported scenario" unless SCENARIOS.include?(scenario)

      @admin_user = admin_user
      @scenario = scenario
    end

    def groups
      items = @scenario == "live" ? live_items : scenario_items
      GROUPS.map do |key, label|
        matches = items.select { |item| item.fetch(:group) == key }
        { key:, label:, items: matches.first(LIMIT), remaining: [ matches.size - LIMIT, 0 ].max }
      end
    end

    private

    def live_items
      ActivityCenter::Inbox.new(admin_user: @admin_user).notifications.map do |notification|
        item = ActivityCenter::Serializer.new(notification).as_json
        actionable = item.fetch(:attentionKind) == "requires_action"
        group = actionable ? (item.fetch(:priority) == "high" ? "urgent" : "actionable") : "fyi"
        {
          group:, title: item.fetch(:subject), context: item.fetch(:body),
          reason: actionable ? "An explicit review or follow-up remains open." : "Informational only; no immediate action is required.",
          action: actionable ? "Review source" : "View source", url: item.fetch(:deepLink)
        }
      end
    end

    def scenario_items
      return [] if @scenario == "healthy"

      [
        { group: "urgent", title: "Synthetic approval deadline", reason: "A review is due before the next dispatch.", context: "Demo fixture: the deadline is deliberately fixed, not calculated from a hidden score.", action: "Open review board", url: "/admin/kanban_workflow" },
        { group: "actionable", title: "Synthetic blocked import", reason: "A validation conflict needs an operator decision.", context: "Demo fixture: inspect the canonical import preview before retrying. This scenario does not start an import.", action: "Open imports", url: "/admin/csv_import_workflow" },
        { group: "fyi", title: "Synthetic routine completion", reason: "Completed successfully; no action is required.", context: "Healthy background work stays in this collapsed awareness group.", action: "View operations", url: "/admin/live_jobs" }
      ]
    end
  end
end
