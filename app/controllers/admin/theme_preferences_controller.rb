# app/controllers/admin/theme_preferences_controller.rb
# frozen_string_literal: true

module Admin
  class ThemePreferencesController < ApplicationController
    before_action :authenticate_admin_user!

    def update
      current_admin_user.update!(theme_preference: params.require(:theme_preference))
      respond_to do |format|
        format.json { render json: { theme: current_admin_user.theme_preference } }
        format.html { redirect_back fallback_location: admin_root_path, notice: "Visual theme updated." }
      end
    rescue ActiveRecord::RecordInvalid, ActionController::ParameterMissing => error
      respond_to do |format|
        format.json { render json: { error: error.message }, status: :unprocessable_content }
        format.html { redirect_back fallback_location: admin_root_path, alert: "Visual theme could not be updated." }
      end
    end
  end
end
