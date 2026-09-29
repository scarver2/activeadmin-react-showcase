# spec/factories/conversation_memberships.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :conversation_membership do
    association :admin_user
    association :conversation
    display_name { "Maya Ortiz" }
    legacy_identity { false }
    sequence(:key) { |number| "member-#{number}" }

    trait :legacy do
      admin_user { nil }
      legacy_identity { true }
    end
  end
end
