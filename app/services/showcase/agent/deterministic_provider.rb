# app/services/showcase/agent/deterministic_provider.rb
# frozen_string_literal: true

module Showcase
  module Agent
    class DeterministicProvider
      Event = Data.define(:kind, :content, :progress, :metadata)

      STEPS = [
        Event.new(kind: "status", content: "Reading authorized showcase records", progress: 15, metadata: {}),
        Event.new(kind: "status", content: "Comparing account health signals", progress: 35, metadata: {}),
        Event.new(
          kind: "response",
          content: "The deterministic agent found six synthetic accounts and compared their recent activity. ",
          progress: 55,
          metadata: {}
        ),
        Event.new(
          kind: "citation",
          content: "Account explorer",
          progress: 70,
          metadata: { "label" => "Authorized account dataset", "url" => "/admin/data_explorer" }
        ),
        Event.new(
          kind: "response",
          content: "The strongest next action is to inspect trial accounts before reviewing aggregate trends.",
          progress: 85,
          metadata: {}
        )
      ].freeze

      def each_event(&)
        STEPS.each(&)
      end

      def result
        "Review trial accounts, then compare the analytics trend."
      end
    end
  end
end
