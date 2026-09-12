# app/controllers/admin/agent_runs_controller.rb
# frozen_string_literal: true

module Admin
  class AgentRunsController < ApplicationController
    before_action :authenticate_admin_user!
    before_action :load_run, only: %i[cancel show]

    def create
      run = AgentConsole::Create.call(admin_user: current_admin_user, prompt: params.require(:prompt))
      respond_to do |format|
        format.html { redirect_to admin_agent_console_path(run_id: run.public_id) }
        format.json { render json: serialize(run), status: :created }
      end
    rescue ActiveRecord::RecordInvalid => error
      render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    end

    def show
      render json: serialize(@run)
    end

    def cancel
      @run.with_lock do
        @run.update!(cancel_requested_at: Time.current) unless @run.terminal?
      end
      render json: serialize(@run.reload)
    end

    private

    def load_run
      @run = current_admin_user.agent_runs.find_by!(public_id: params[:public_id])
    end

    def serialize(run) = AgentConsole::Serializer.new(run).as_json
  end
end
