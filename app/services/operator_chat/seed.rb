# app/services/operator_chat/seed.rb
# frozen_string_literal: true

module OperatorChat
  class Seed
    ROOM_ID = "support-operations"
    MESSAGES = [
      [ "maya", "The synthetic Northwind import is ready for review." ],
      [ "jordan", "I checked the sample totals. Everything balances." ]
    ].freeze

    def self.call
      room = ChatRoom.find_or_create_by!(public_id: ROOM_ID) { |record| record.name = "Operator handoff" }
      return room if room.messages.exists?

      room.with_lock do
        MESSAGES.each_with_index do |(author_key, body), index|
          room.messages.create!(author_key:, author_name: ChatMessage::PARTICIPANTS.fetch(author_key), body:, sequence: index + 1)
        end
      end
      room
    end
  end
end
