# app/services/operator_chat/post_message.rb
# frozen_string_literal: true

module OperatorChat
  class PostMessage
    def self.call(room:, body:)
      author = Seed.participant_for(room:, key: "operator")
      message = room.with_lock do
        room.messages.create!(
          author:,
          body: body.to_s.strip,
          sequence: room.messages.maximum(:sequence).to_i + 1
        )
      end
      ActionCable.server.broadcast(room.broadcast_key, { type: "message", message: Serializer.new(message).as_json })
      message
    end
  end
end
