# app/services/operations/create.rb
# frozen_string_literal: true

module Operations
  class Create
    def self.call(admin_user:, kind:, request_idempotency_key:, retry_of: nil)
      operation, event, created = Operations::DatabaseRetry.call do
        admin_user.with_lock do
          existing = admin_user.operations.find_by(request_idempotency_key:)
          next [ existing, nil, false ] if existing

          created_operation = admin_user.operations.create!(kind:, request_idempotency_key:, retry_of:)
          initial_event = initial_event(created_operation)
          [ created_operation, initial_event, true ]
        end
      end
      if created
        Operations::Transition.broadcast(event)
        DemoOperationJob.perform_later(operation.id)
      end
      operation
    rescue ActiveRecord::RecordNotUnique
      admin_user.operations.find_by!(request_idempotency_key:)
    end

    def self.initial_event(operation)
      operation.events.create!(
        idempotency_key: "#{operation.public_id}:1",
        message: operation.message,
        occurred_at: operation.created_at,
        progress: operation.progress,
        sequence: 1,
        state: operation.state
      )
    end
    private_class_method :initial_event
  end
end
