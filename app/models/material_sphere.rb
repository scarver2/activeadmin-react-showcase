# app/models/material_sphere.rb
# frozen_string_literal: true

class MaterialSphere < ApplicationRecord
  belongs_to :admin_user
  validates :finish, inclusion: { in: ->(_) { MaterialStudio::Catalog.ids } }
  validates :name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[admin_user_id created_at finish id lock_version name updated_at]
  end
end
