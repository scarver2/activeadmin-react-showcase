# app/services/agent_console/serializer.rb
# frozen_string_literal: true

module AgentConsole
  class Serializer
    def initialize(run)
      @run = run
    end

    def as_json(*)
      {
        id: run.public_id,
        prompt: run.prompt,
        state: run.state,
        progress: run.progress,
        summary: run.summary,
        events: run.events.map(&:envelope),
        showUrl: Rails.application.routes.url_helpers.admin_agent_run_path(run.public_id),
        cancelUrl: Rails.application.routes.url_helpers.cancel_admin_agent_run_path(run.public_id)
      }
    end

    private

    attr_reader :run
  end
end
