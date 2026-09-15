# app/controllers/admin/material_sphere_configurations_controller.rb
# frozen_string_literal: true

module Admin
  class MaterialSphereConfigurationsController < ApplicationController
    before_action :authenticate_admin_user!

    def update
      model = current_admin_user.material_spheres.find(params[:id])
      model.lock_version = Integer(params[:lock_version])
      model.update!(params.require(:material_sphere).permit(:finish))
      render json: { model: MaterialStudio::Serializer.new(model).as_json }
    rescue ActiveRecord::StaleObjectError
      render json: { error: "The material recipe changed; reload" }, status: :conflict
    rescue ActionController::ParameterMissing, ArgumentError, ActiveRecord::RecordInvalid => error
      render json: { error: error.message }, status: :unprocessable_content
    end
  end
end
