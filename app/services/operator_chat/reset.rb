# app/services/operator_chat/reset.rb
# frozen_string_literal: true

module OperatorChat
  class Reset
    def self.call(room:)
      messages = room.with_lock do
        room.memberships.where.not(last_read_message_id: nil).update_all(
          last_read_message_id: nil,
          last_read_at: nil,
          updated_at: Time.current
        )
        Message.where(conversation_id: room.id).delete_all
        Seed::MESSAGES.map.with_index(1) do |(author_key, body), sequence|
          room.messages.create!(author: Seed.participant_for(room:, key: author_key), body:, sequence:)
        end
      end
      payload = messages.map { |message| Serializer.new(message).as_json }
      ActionCable.server.broadcast(room.broadcast_key, { type: "reset", messages: payload })
      messages
    end
  end
end
