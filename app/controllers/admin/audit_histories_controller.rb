# app/controllers/admin/audit_histories_controller.rb
# frozen_string_literal: true

module Admin
  class AuditHistoriesController < ApplicationController
    before_action :authenticate_admin_user!

    def show
      profile = current_admin_user.audit_profiles.find(params[:id])
      history = AuditHistory::ProfileHistory.new(profile)
      render json: { preview: history.preview(params.require(:version_id)) }
    rescue PaperTrailDiff::Error, ActiveRecord::RecordNotFound => error
      render json: { error: error.message }, status: :unprocessable_content
    end
  end
end
