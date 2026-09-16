# app/controllers/admin/wizard_drafts_controller.rb
# frozen_string_literal: true

module Admin
  class WizardDraftsController < ApplicationController
    before_action :authenticate_admin_user!

    def update
      draft = current_admin_user.onboarding_drafts.find(params[:id])
      Onboarding::SaveDraft.call(admin_user: current_admin_user, attributes: draft_params, draft:,
        expected_lock_version: params[:lock_version], submit: ActiveModel::Type::Boolean.new.cast(params[:submit]))
      respond_to do |format|
        format.html { redirect_to admin_onboarding_wizard_path, notice: "Draft saved." }
        format.json { render json: { draft: draft.as_json(only: %i[id account_kind company_name compliance_contact contact_email current_step lock_version status submitted_at]) } }
      end
    rescue ActiveRecord::RecordInvalid => error
      respond_to do |format|
        format.html { redirect_to admin_onboarding_wizard_path, alert: error.record.errors.full_messages.to_sentence }
        format.json { render json: { errors: error.record.errors.to_hash(true) }, status: :unprocessable_content }
      end
    rescue Onboarding::SaveDraft::StaleWrite => error
      render json: { error: error.message }, status: :conflict
    end

    private

    def draft_params
      params.fetch(:onboarding_draft, params).permit(:account_kind, :company_name, :compliance_contact, :contact_email,
        :current_step)
    end
  end
end
