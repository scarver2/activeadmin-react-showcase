# spec/factories/showcase_locations.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :showcase_location do
    category { "Laboratory" }
    latitude { 30.2672 }
    longitude { -97.7431 }
    sequence(:name) { |number| "Location #{number}" }
    summary { "Synthetic test location" }
  end
end
