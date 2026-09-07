# spec/factories/chat_rooms.rb
# frozen_string_literal: true

FactoryBot.define do
  factory :chat_room do
    sequence(:name) { |number| "Synthetic room #{number}" }
    sequence(:public_id) { |number| "room-#{number}" }
  end
end
