# app/services/spacecraft/catalog.rb
# frozen_string_literal: true

module Spacecraft
  class Catalog
    COMPONENTS = [
      { id: "fuselage", material: "Titanium alloy", name: "Fuselage", partNumber: "ODY-100", status: "flight-ready", dimensions: "8.0 × 2.4 m", notes: "Primary pressure vessel" },
      { id: "port-wing", material: "Carbon composite", name: "Port wing", partNumber: "ODY-210-L", status: "inspection due", dimensions: "4.2 × 1.6 m", notes: "Port lift and radiator surface" },
      { id: "starboard-wing", material: "Carbon composite", name: "Starboard wing", partNumber: "ODY-210-R", status: "flight-ready", dimensions: "4.2 × 1.6 m", notes: "Starboard lift and radiator surface" }
    ].freeze
    def self.ids = COMPONENTS.map { |component| component.fetch(:id) }
  end
end
