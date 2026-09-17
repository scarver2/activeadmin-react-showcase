# spec/factories/audit_profiles.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :audit_profile do
    admin_user
    name { "Bluebonnet Profile" }
    plan { "Starter" }
    preferences { { alerts: [ "email" ] }.to_json }
  end
end
