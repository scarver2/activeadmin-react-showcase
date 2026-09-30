# app/services/conversations/realtime_change.rb
# frozen_string_literal: true

module Conversations
  class RealtimeChange
    KINDS = %w[disposition message_created message_edited message_withdrawn read_state].freeze

    def self.record!(conversation:, kind:)
      raise ArgumentError, "unsupported realtime change" unless kind.to_s.in?(KINDS)

      Conversation.increment_counter(:realtime_version, conversation.id)
      version = Conversation.where(id: conversation.id).pick(:realtime_version)
      envelope = snapshot(conversation:, kind:, version:)
      ActiveRecord.after_all_transactions_commit { broadcast(conversation:, envelope:) }
      version
    end

    def self.snapshot(conversation:, kind: "snapshot", version: nil)
      {
        conversationPublicId: conversation.public_id,
        kind:,
        latestSequence: conversation.messages.maximum(:sequence).to_i,
        serverAt: Time.current.iso8601(6),
        version: version || conversation.reload.realtime_version
      }
    end

    def self.broadcast(conversation:, envelope:)
      ConversationChannel.broadcast_to(conversation, envelope)
      true
    rescue StandardError => error
      Rails.logger.warn("Conversation realtime broadcast failed: #{error.class}: #{error.message}")
      false
    end

    private_class_method :broadcast
  end
end
