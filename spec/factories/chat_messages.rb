# spec/factories/chat_messages.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :chat_message do
    association :chat_room
    author_key { "maya" }
    author_name { "Maya Ortiz" }
    body { "Synthetic message" }
    sequence(:sequence)
  end
end
