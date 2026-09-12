# db/migrate/20260907340000_create_showcase_locations.rb
# frozen_string_literal: true

class CreateShowcaseLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :showcase_locations do |table|
      table.string :category, null: false
      table.decimal :latitude, null: false, precision: 9, scale: 6
      table.decimal :longitude, null: false, precision: 9, scale: 6
      table.string :name, null: false
      table.string :summary, null: false
      table.timestamps

      table.index %i[latitude longitude]
      table.check_constraint "latitude BETWEEN -90 AND 90", name: "showcase_locations_latitude_range"
      table.check_constraint "longitude BETWEEN -180 AND 180", name: "showcase_locations_longitude_range"
    end
  end
end
