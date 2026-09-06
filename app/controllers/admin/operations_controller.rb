# app/controllers/admin/operations_controller.rb
# frozen_string_literal: true

module Admin
  class OperationsController < ApplicationController
    before_action :authenticate_admin_user!
    before_action :load_operation, only: %i[cancel retry show]

    def create
      operation = Operations::Create.call(
        admin_user: current_admin_user,
        kind: permitted_kind,
        request_idempotency_key: request_idempotency_key
      )
      respond_to do |format|
        format.html { redirect_to admin_live_jobs_path(operation_id: operation.public_id) }
        format.json { render json: serialize(operation), status: :created }
      end
    end

    def show
      render json: serialize(@operation)
    end

    def cancel
      operation = Operations::Cancel.call(
        operation: @operation,
        idempotency_key: "cancel:#{@operation.public_id}"
      )
      render json: serialize(operation)
    end

    def retry
      retried = Operations::Retry.call(
        operation: @operation,
        admin_user: current_admin_user,
        request_idempotency_key: request_idempotency_key
      )
      render json: serialize(retried), status: :created
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_content
    end

    private

    def load_operation
      @operation = current_admin_user.operations.find_by!(public_id: params[:id])
    end

    def permitted_kind
      kind = params[:kind].presence || "successful_demo"
      return kind if Operation::KINDS.include?(kind)

      raise ActionController::BadRequest, "Unsupported operation kind"
    end

    def request_idempotency_key
      request.headers["Idempotency-Key"].presence || params[:idempotency_key].presence ||
        raise(ActionController::BadRequest, "Idempotency-Key is required")
    end

    def serialize(operation)
      Operations::Serializer.new(operation).as_json
    end
  end
end
