# app/models/showcase_location.rb
# frozen_string_literal: true

class ShowcaseLocation < ApplicationRecord
  validates :category, :name, :summary, presence: true
  validates :latitude, numericality: { in: -90..90 }
  validates :longitude, numericality: { in: -180..180 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[category created_at id latitude longitude name summary updated_at]
  end
end
