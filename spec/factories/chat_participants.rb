# spec/factories/chat_participants.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :chat_participant do
    association :chat_room
    display_name { "Maya Ortiz" }
    sequence(:key) { |number| "participant-#{number}" }
  end
end
