# app/services/workflow/seed.rb
# frozen_string_literal: true

module Workflow
  class Seed
    ITEMS = [
      [ "Document import edge cases", "backlog", "Capture dogfood findings without expanding the demo domain." ],
      [ "Review account filters", "ready", "Confirm bounded query behavior with support operators." ],
      [ "Verify Cable replay", "in_progress", "Exercise reconnect after a deliberately missed event." ],
      [ "Approve release notes", "review", "Check the public prerelease guidance before publishing." ],
      [ "Ship Rails-native foundation", "done", "SQLite and the Solid stack are running on one host." ]
    ].freeze

    def self.call
      ITEMS.each do |title, state, context|
        WorkflowItem.find_or_initialize_by(title:).update!(state:, position: 0, context:)
      end
      WorkflowItem.ordered
    end
  end
end
