# app/services/geospatial/seed.rb
# frozen_string_literal: true

module Geospatial
  class Seed
    LOCATIONS = [
      [ "Texas Embroidery Ranch", "Embroidery", 33.346905, -96.573168, "Custom embroidery and branded apparel · 2014 Rhymers Glen Dr" ],
      [ "Andy Torres State Farm", "Insurance", 33.344513, -96.576513, "Local insurance agency · 2151 W White St, Suite 300" ],
      [ "Kalamaki Greek Eatery", "Restaurant", 33.349, -96.550014, "Greek restaurant in historic downtown · 121 W 4th St" ],
      [ "Lamar National Bank", "Bank", 33.344766, -96.565698, "Anna community banking center · 1515 W White St" ],
      [ "Roma’s Italian Bistro of Anna", "Restaurant", 33.349332, -96.5513, "Family-run Italian restaurant · 111 N Powell Pkwy" ],
      [ "Paw in the Family", "Pet supplies", 33.34612, -96.5733, "Pet food, supplies, grooming, and boarding · 2010 W White St" ],
      [ "Sherley Heritage Park", "Park", 33.34977, -96.55119, "Historic rail park and restored depot · 101 S Sherley Ave" ]
    ].freeze

    def self.call
      locations = LOCATIONS.map do |name, category, latitude, longitude, summary|
        ShowcaseLocation.find_or_initialize_by(name:).tap do |location|
          location.update!(category:, latitude:, longitude:, summary:)
        end
      end
      ShowcaseLocation.where.not(id: locations.map(&:id)).delete_all
      locations
    end
  end
end
