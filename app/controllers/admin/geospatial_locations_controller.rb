# app/controllers/admin/geospatial_locations_controller.rb
# frozen_string_literal: true

module Admin
  class GeospatialLocationsController < ApplicationController
    before_action :authenticate_admin_user!

    def index
      render json: Geospatial::LocationQuery.new(bounds: params[:bounds]).as_json
    rescue ArgumentError => error
      render json: { error: error.message }, status: :bad_request
    end
  end
end
