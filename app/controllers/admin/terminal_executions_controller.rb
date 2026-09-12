# app/controllers/admin/terminal_executions_controller.rb
# frozen_string_literal: true

module Admin
  class TerminalExecutionsController < ApplicationController
    before_action :authenticate_admin_user!
    before_action :load_execution, only: :cancel

    def create
      execution = SafeTerminal::Create.call(
        admin_user: current_admin_user,
        command_key: params.require(:command_key),
        idempotency_key: idempotency_key
      )
      respond_to do |format|
        format.html { redirect_to admin_safe_terminal_path, notice: "Allowlisted demo command queued." }
        format.json { render json: SafeTerminal::Serializer.new(execution).as_json, status: :created }
      end
    rescue SafeTerminal::Commands::Unsupported, ActionController::ParameterMissing => e
      respond_to do |format|
        format.html { redirect_to admin_safe_terminal_path, alert: e.message }
        format.json { render json: { error: e.message }, status: :unprocessable_content }
      end
    end

    def cancel
      execution = SafeTerminal::Cancel.call(execution: @execution)
      render json: SafeTerminal::Serializer.new(execution).as_json
    end

    private

    def idempotency_key
      request.headers["Idempotency-Key"].presence || params[:idempotency_key].presence ||
        raise(ActionController::BadRequest, "Idempotency-Key is required")
    end

    def load_execution
      @execution = current_admin_user.terminal_executions.find_by!(public_id: params[:id])
    end
  end
end
