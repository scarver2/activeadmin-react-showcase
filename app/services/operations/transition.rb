# app/services/operations/transition.rb
# frozen_string_literal: true

module Operations
  class Transition
    ALLOWED = {
      "queued" => %w[running cancelled],
      "running" => %w[running completed failed cancelled]
    }.freeze

    def self.call(operation:, state:, progress:, message:, result: nil, error: nil)
      event = operation.with_lock do
        new(operation:).record(state:, progress:, message:, result:, error:)
      end
      broadcast(event)
      event
    end

    def self.call_locked(operation:, state:, progress:, message:, result: nil, error: nil)
      new(operation:).record(state:, progress:, message:, result:, error:)
    end

    def self.broadcast(event)
      ActionCable.server.broadcast(event.operation.broadcast_key, event.envelope)
    end

    def initialize(operation:)
      @operation = operation
    end

    def record(state:, progress:, message:, result: nil, error: nil)
      operation.reload
      validate_transition!(state)
      validate_progress!(progress)
      occurred_at = Time.current
      sequence = operation.events.maximum(:sequence).to_i + 1
      attributes = timestamps_for(state, occurred_at).merge(state:, progress:, message:, result:, error:)
      operation.update!(attributes)
      operation.events.create!(
        attributes.slice(:state, :progress, :message, :result, :error).merge(
          idempotency_key: "#{operation.public_id}:#{sequence}",
          occurred_at:,
          sequence:
        )
      )
    end

    private

    attr_reader :operation

    def timestamps_for(state, occurred_at)
      case state
      when "running"
        { started_at: operation.started_at || occurred_at }
      when *Operation::TERMINAL_STATES
        { claim_expires_at: nil, claim_key: nil, finished_at: occurred_at }
      else
        {}
      end
    end

    def validate_transition!(state)
      return if ALLOWED.fetch(operation.state, []).include?(state)

      raise ArgumentError, "cannot transition operation from #{operation.state} to #{state}"
    end

    def validate_progress!(progress)
      return if progress >= operation.progress

      raise ArgumentError, "cannot regress operation progress from #{operation.progress} to #{progress}"
    end
  end
end
