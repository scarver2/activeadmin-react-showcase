# spec/factories/spacecraft_models.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :spacecraft_model do
    admin_user
    finish { "titanium" }
    name { "Odyssey" }
    selected_component_id { "fuselage" }
  end
end
