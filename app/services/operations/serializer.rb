# app/services/operations/serializer.rb
# frozen_string_literal: true

module Operations
  class Serializer
    def initialize(operation)
      @operation = operation
    end

    def as_json(*)
      operation.latest_envelope.merge(
        cancelUrl: Rails.application.routes.url_helpers.cancel_admin_operation_path(operation.public_id),
        retryUrl: Rails.application.routes.url_helpers.retry_admin_operation_path(operation.public_id),
        showUrl: Rails.application.routes.url_helpers.admin_operation_path(operation.public_id),
        created_at: operation.created_at.iso8601(6),
        kind: operation.kind,
        retry_of: operation.retry_of&.public_id
      )
    end

    private

    attr_reader :operation
  end
end
