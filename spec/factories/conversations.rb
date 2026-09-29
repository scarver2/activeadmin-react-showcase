# spec/factories/conversations.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :conversation do
    last_activity_at { Time.current }
    sequence(:public_id) { |number| "conversation-#{number}" }
    sequence(:title) { |number| "Synthetic conversation #{number}" }
    topic { nil }
  end
end
