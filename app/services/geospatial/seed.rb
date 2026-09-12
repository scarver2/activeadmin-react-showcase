# app/services/geospatial/seed.rb
# frozen_string_literal: true

module Geospatial
  class Seed
    LOCATIONS = [
      [ "Austin Workshop", "Workshop", 30.2672, -97.7431, "Central Texas fabrication lab" ],
      [ "Bastrop Field Site", "Field", 30.1105, -97.3153, "Solar instrumentation test site" ],
      [ "Georgetown Depot", "Depot", 30.6333, -97.6779, "North corridor parts depot" ],
      [ "Lockhart Studio", "Studio", 29.8849, -97.67, "Material and finish studio" ],
      [ "San Marcos Lab", "Laboratory", 29.8833, -97.9414, "Environmental validation lab" ],
      [ "Taylor Hangar", "Hangar", 30.5708, -97.4094, "Flight systems assembly hangar" ]
    ].freeze

    def self.call
      LOCATIONS.map do |name, category, latitude, longitude, summary|
        ShowcaseLocation.find_or_initialize_by(name:).tap do |location|
          location.update!(category:, latitude:, longitude:, summary:)
        end
      end
    end
  end
end
