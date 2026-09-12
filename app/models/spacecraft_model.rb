# app/models/spacecraft_model.rb
# frozen_string_literal: true

class SpacecraftModel < ApplicationRecord
  FINISHES = %w[ceramic titanium].freeze
  belongs_to :admin_user
  validates :finish, inclusion: { in: FINISHES }
  validates :name, presence: true
  validates :selected_component_id, inclusion: { in: ->(_) { Spacecraft::Catalog.ids } }
  def self.ransackable_attributes(_auth_object = nil) = %w[admin_user_id created_at finish id lock_version name selected_component_id updated_at]
end
