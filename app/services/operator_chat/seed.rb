# app/services/operator_chat/seed.rb
# frozen_string_literal: true

module OperatorChat
  class Seed
    ROOM_ID = "support-operations"
    PARTICIPANTS = {
      "jordan" => "Jordan Lee",
      "maya" => "Maya Ortiz",
      "operator" => "You"
    }.freeze
    MESSAGES = [
      [ "maya", "The synthetic Northwind import is ready for review." ],
      [ "jordan", "I checked the sample totals. Everything balances." ]
    ].freeze

    def self.call
      room = ChatRoom.find_or_create_by!(public_id: ROOM_ID) { |record| record.name = "Operator handoff" }
      participants = PARTICIPANTS.to_h do |key, display_name|
        [ key, participant_for(room:, key:, display_name:) ]
      end
      return room if room.messages.exists?

      room.with_lock do
        MESSAGES.each_with_index do |(author_key, body), index|
          room.messages.create!(author: participants.fetch(author_key), body:, sequence: index + 1)
        end
      end
      room
    end

    def self.participant_for(room:, key:, display_name: PARTICIPANTS.fetch(key))
      room.participants.find_or_initialize_by(key:).tap { |participant| participant.update!(display_name:) }
    end
  end
end
