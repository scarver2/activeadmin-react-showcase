# app/services/operations/cancel.rb
# frozen_string_literal: true

module Operations
  class Cancel
    def self.call(operation:, idempotency_key:)
      event = Operations::DatabaseRetry.call do
        operation.with_lock do
          operation.reload
          next if operation.cancel_idempotency_key.present?

          operation.update!(cancel_idempotency_key: idempotency_key, cancel_requested_at: Time.current)
          next if operation.terminal?

          state = operation.state == "queued" ? "cancelled" : "running"
          message = operation.state == "queued" ? "Operation cancelled before a worker started" : "Cancellation requested"
          Operations::Transition.call_locked(operation:, state:, progress: operation.progress, message:)
        end
      end
      Operations::Transition.broadcast(event) if event
      operation.reload
    end
  end
end
