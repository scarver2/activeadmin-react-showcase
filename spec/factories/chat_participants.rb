# spec/factories/chat_participants.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :chat_participant do
    admin_user { nil }
    chat_room { association(:chat_room) }
    display_name { "Maya Ortiz" }
    legacy_identity { true }
    sequence(:key) { |number| "participant-#{number}" }
  end
end
