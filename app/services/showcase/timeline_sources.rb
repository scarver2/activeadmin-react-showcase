# app/services/showcase/timeline_sources.rb
# frozen_string_literal: true

module Showcase
  # Domain-owned, deterministic fixtures, not a replacement event store. Each
  # family owns its description and fields; the timeline only projects them.
  class TimelineSources
    VERSION = "synthetic-v1"
    FAMILIES = {
      "approval" => { label: "Approvals", title: "Dispatch review approved", fields: { "Decision" => "Approved", "Scope" => "Synthetic dispatch" } },
      "assignment" => { label: "Assignments", title: "Work assigned to dispatch", fields: { "Team" => "Dispatch", "Work" => "Synthetic packing review" } },
      "comment" => { label: "Comments", title: "Packing instructions clarified", fields: { "Comment" => "Use the reusable packing crates." } },
      "file" => { label: "Files", title: "Packing checklist attached", fields: { "Filename" => "synthetic-checklist.txt", "Media type" => "text/plain" } },
      "message" => { label: "Messages", title: "Dispatch handoff discussed", fields: { "Message" => "The synthetic order is ready for review.", "Channel" => "Dispatch" } },
      "status" => { label: "Status changes", title: "Order moved to review", fields: { "From" => "Draft", "To" => "Review" } },
      "system" => { label: "System events", title: "Synthetic import validated", fields: { "Result" => "Validated", "Origin" => "Demo importer" } }
    }.freeze
    ACTORS = [ "Avery Morgan", "Jules Chen", "System" ].freeze
    RECORDS_PER_FAMILY = 200

    def records
      FAMILIES.flat_map do |family, definition|
        Array.new(RECORDS_PER_FAMILY) do |index|
          {
            id: "#{family}-#{format('%04d', index)}", family:,
            occurred_at: (Time.utc(2026, 10, 1, 12) - index.hours).iso8601,
            actor: family == "system" ? "System" : ACTORS[index % 2],
            title: definition.fetch(:title), fields: definition.fetch(:fields),
            state: { 1 => "redacted", 2 => "deleted", 3 => "restricted" }.fetch(index, "available")
          }.freeze
        end
      end
    end

    # Restricted fixtures model a source policy denial. All remaining fixtures
    # are shared synthetic data visible only to authenticated administrators.
    def visible_records(admin_user:)
      raise ActiveRecord::RecordNotFound unless admin_user&.persisted?

      records.reject { |record| record.fetch(:state) == "restricted" }
    end

    def find(id:, admin_user:)
      record = visible_records(admin_user:).find { |candidate| candidate.fetch(:id) == id }
      raise ActiveRecord::RecordNotFound unless record && record.fetch(:state) == "available"

      record
    end
  end
end
