# app/services/operations/create.rb
# frozen_string_literal: true

module Operations
  class Create
    def self.call(admin_user:, kind:, retry_of: nil)
      operation, event = Operation.transaction do
        created_operation = admin_user.operations.create!(kind:, retry_of:)
        initial_event = created_operation.events.create!(
          idempotency_key: "#{created_operation.public_id}:1",
          message: created_operation.message,
          occurred_at: created_operation.created_at,
          progress: created_operation.progress,
          sequence: 1,
          state: created_operation.state
        )
        [ created_operation, initial_event ]
      end
      ActionCable.server.broadcast(operation.broadcast_key, event.envelope)
      DemoOperationJob.perform_later(operation.id)
      operation
    end
  end
end
