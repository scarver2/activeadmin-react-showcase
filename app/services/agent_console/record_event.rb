# app/services/agent_console/record_event.rb
# frozen_string_literal: true

module AgentConsole
  class RecordEvent
    def self.call(run:, kind:, content:, progress:, metadata: {}, state: nil, summary: nil)
      event = run.with_lock do
        run.reload
        attributes = { progress: }
        attributes[:state] = state if state
        attributes[:summary] = summary if summary
        attributes[:finished_at] = Time.current if state.in?(AgentRun::TERMINAL_STATES)
        run.update!(attributes)
        run.events.create!(
          sequence: run.events.maximum(:sequence).to_i + 1,
          kind:,
          content:,
          progress:,
          metadata:,
          occurred_at: Time.current
        )
      end
      broadcast(event)
      event
    end

    def self.broadcast(event)
      ActionCable.server.broadcast(event.agent_run.broadcast_key, event.envelope)
    rescue StandardError => error
      Rails.logger.error("Agent event #{event.id} Cable broadcast failed: #{error.class}: #{error.message}")
    end
    private_class_method :broadcast
  end
end
