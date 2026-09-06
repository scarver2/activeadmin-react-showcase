# spec/factories/accounts.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    sequence(:name) { |number| "Demo Account #{number}" }
    plan { "Growth" }
    region { "Central" }
    status { "active" }
  end
end
