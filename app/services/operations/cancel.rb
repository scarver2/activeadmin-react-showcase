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
      if event
        ActiveAdmin::React::Cable.broadcast(
          stream: operation.broadcast_key,
          payload: event.envelope,
          context: { operation_event_id: event.id, operation_id: operation.id, workflow: "operation" }
        )
      end
      operation.reload
    end
  end
end
