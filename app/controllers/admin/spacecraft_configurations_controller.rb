# app/controllers/admin/spacecraft_configurations_controller.rb
# frozen_string_literal: true

module Admin
  class SpacecraftConfigurationsController < ApplicationController
    before_action :authenticate_admin_user!
    def update
      model = current_admin_user.spacecraft_models.find(params[:id])
      model.lock_version = Integer(params[:lock_version])
      model.update!(params.require(:spacecraft).permit(:finish, :selected_component_id))
      render json: { model: Spacecraft::Serializer.new(model).as_json }
    rescue ActiveRecord::StaleObjectError
      render json: { error: "The spacecraft configuration changed; reload" }, status: :conflict
    rescue ActionController::ParameterMissing, ArgumentError, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_content
    end
  end
end
