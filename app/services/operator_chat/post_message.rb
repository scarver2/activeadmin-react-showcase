# app/services/operator_chat/post_message.rb
# frozen_string_literal: true

module OperatorChat
  class PostMessage
    def self.call(room:, body:)
      author = Seed.participant_for(room:, key: "operator")
      message = Conversations::CreateMessage.call(conversation: room, membership: author, body:)
      broadcast(room:, message:)
      message
    end

    def self.broadcast(room:, message:)
      ActionCable.server.broadcast(room.broadcast_key, { type: "message", message: Serializer.new(message).as_json })
    rescue StandardError => error
      Rails.logger.warn("Operator Chat broadcast failed after message #{message.public_id} persisted: #{error.class}")
    end
    private_class_method :broadcast
  end
end
