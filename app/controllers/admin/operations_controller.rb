# app/controllers/admin/operations_controller.rb
# frozen_string_literal: true

module Admin
  class OperationsController < ApplicationController
    before_action :authenticate_admin_user!
    before_action :load_operation, only: %i[cancel retry show]

    def create
      operation = Operations::Create.call(admin_user: current_admin_user, kind: permitted_kind)
      respond_to do |format|
        format.html { redirect_to admin_live_jobs_path(operation_id: operation.public_id) }
        format.json { render json: serialize(operation), status: :created }
      end
    end

    def show
      render json: serialize(@operation)
    end

    def cancel
      if @operation.cancelable?
        @operation.update!(cancel_requested_at: Time.current)
        event_state = @operation.state == "queued" ? "cancelled" : "running"
        event_message = @operation.state == "queued" ? "Operation cancelled before a worker started" : "Cancellation requested"
        Operations::Transition.call(
          operation: @operation,
          state: event_state,
          progress: @operation.progress,
          message: event_message
        )
      end
      render json: serialize(@operation.reload)
    end

    def retry
      return render json: { error: "Only terminal operations can be retried" }, status: :unprocessable_content unless @operation.retryable?

      retried = Operations::Create.call(admin_user: current_admin_user, kind: @operation.kind, retry_of: @operation)
      render json: serialize(retried), status: :created
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

    def serialize(operation)
      Operations::Serializer.new(operation).as_json
    end
  end
end
