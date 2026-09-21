# app/controllers/admin/privacy_modes_controller.rb
# frozen_string_literal: true

module Admin
  class PrivacyModesController < ApplicationController
    before_action :authenticate_admin_user!

    def update
      enabled = params[:enabled]
      unless [ true, false, "true", "false" ].include?(enabled)
        return render json: { error: "enabled must be true or false" }, status: :unprocessable_content
      end

      session[:showcase_privacy] = { "user_id" => current_admin_user.id, "enabled" => [ true, "true" ].include?(enabled) }
      response.set_header("Cache-Control", "no-store")
      respond_to do |format|
        format.json { render json: { enabled: session[:showcase_privacy]["enabled"] } }
        format.html { redirect_back fallback_location: admin_root_path }
      end
    end
  end
end
