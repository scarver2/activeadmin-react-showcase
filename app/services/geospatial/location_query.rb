# app/services/geospatial/location_query.rb
# frozen_string_literal: true

module Geospatial
  class LocationQuery
    MAXIMUM_LATITUDE_SPAN = 12
    MAXIMUM_LONGITUDE_SPAN = 12
    MAXIMUM_RESULTS = 100

    def initialize(bounds:)
      @west, @south, @east, @north = parse_bounds(bounds)
      validate!
    end

    def as_json
      { locations: locations.map { |location| LocationSerializer.new(location).as_json } }
    end

    def locations
      ShowcaseLocation.where(latitude: south..north, longitude: west..east).order(:name).limit(MAXIMUM_RESULTS)
    end

    private

    attr_reader :east, :north, :south, :west

    def parse_bounds(bounds)
      bounds.to_s.split(",").map { |value| Float(value, exception: true) }
    rescue ArgumentError
      raise ArgumentError, "Bounds must contain numeric west,south,east,north"
    end

    def validate!
      raise ArgumentError, "Bounds must contain west,south,east,north" unless [ west, south, east, north ].all?
      raise ArgumentError, "Bounds are outside valid coordinate ranges" unless west.between?(-180, 180) && east.between?(-180, 180) && south.between?(-90, 90) && north.between?(-90, 90)
      raise ArgumentError, "Bounds must increase from southwest to northeast" unless west < east && south < north
      raise ArgumentError, "Viewport is too large" if east - west > MAXIMUM_LONGITUDE_SPAN || north - south > MAXIMUM_LATITUDE_SPAN
    end
  end
end
