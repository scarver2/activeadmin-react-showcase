# app/services/conversations/set_read_state.rb
# frozen_string_literal: true

module Conversations
  class SetReadState
    STATES = %i[read_through unread_from].freeze

    def self.call(membership:, message:, state:)
      raise ArgumentError, "unsupported read state" unless state.in?(STATES)

      ConversationMembership.transaction do
        state == :read_through ? membership.mark_read_through!(message) : membership.mark_unread_from!(message)
        if membership.previous_changes.key?("last_read_message_id")
          RealtimeChange.record!(conversation: membership.conversation, kind: "read_state")
        end
      end
      membership
    end
  end
end
