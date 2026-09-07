# app/services/operations/retry.rb
# frozen_string_literal: true

module Operations
  class Retry
    def self.call(operation:, admin_user:, request_idempotency_key:)
      operation.with_lock do
        operation.reload
        raise ArgumentError, "Only terminal operations can be retried" unless operation.retryable?
      end

      Operations::Create.call(
        admin_user:,
        kind: operation.kind,
        request_idempotency_key:,
        retry_of: operation
      )
    end
  end
end
