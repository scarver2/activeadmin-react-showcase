# app/services/operator_chat/serializer.rb
# frozen_string_literal: true

module OperatorChat
  class Serializer
    def initialize(message)
      @message = message
    end

    def as_json(*)
      {
        id: message.id,
        authorKey: message.author.key,
        authorName: message.author.display_name,
        body: message.body,
        sequence: message.sequence,
        occurredAt: message.created_at.iso8601
      }
    end

    private

    attr_reader :message
  end
end
