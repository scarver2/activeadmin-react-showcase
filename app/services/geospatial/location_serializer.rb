# app/services/geospatial/location_serializer.rb
# frozen_string_literal: true

module Geospatial
  class LocationSerializer
    def initialize(location)
      @location = location
    end

    def as_json
      {
        category: location.category,
        id: location.id.to_s,
        latitude: location.latitude.to_f,
        longitude: location.longitude.to_f,
        name: location.name,
        summary: location.summary,
        url: Rails.application.routes.url_helpers.admin_showcase_location_path(location)
      }
    end

    private

    attr_reader :location
  end
end
