# app/services/operator_chat/legacy_room.rb
# frozen_string_literal: true

module OperatorChat
  class LegacyRoom
    def self.assert!(room)
      return room if room.public_id == Seed::ROOM_ID

      raise ActiveRecord::RecordNotFound
    end
  end
end
