# spec/factories/scheduled_messages.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :scheduled_message do
    association :admin_user
    association :conversation
    body { "A scheduled synthetic message" }
    scheduled_for { 1.hour.from_now }
  end
end
