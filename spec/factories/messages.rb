# spec/factories/messages.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    association :conversation
    conversation_membership { association(:conversation_membership, conversation:) }
    body { "Synthetic message" }
    sequence(:sequence)
  end
end
