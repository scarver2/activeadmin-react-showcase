# spec/factories/material_spheres.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :material_sphere do
    admin_user
    finish { "candy-red" }
    name { "Glossy red material sphere" }
  end
end
