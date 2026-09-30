# app/services/conversations/inbox.rb
# frozen_string_literal: true

module Conversations
  class Inbox
    LIMIT = 50

    Entry = Data.define(:membership, :unread_count)

    def self.call(admin_user:)
      memberships = admin_user.conversation_memberships
                              .includes(:conversation, :last_read_message)
                              .joins(:conversation)
                              .merge(Conversation.by_recent_activity)
                              .limit(LIMIT)
                              .to_a

      unread_counts = unread_counts_by_conversation(memberships)

      memberships.map do |membership|
        Entry.new(membership:, unread_count: unread_counts.fetch(membership.conversation_id, 0))
      end
    end

    def self.unread_counts_by_conversation(memberships)
      messages = Message.arel_table
      predicate = memberships.filter_map do |membership|
        messages[:chat_room_id]
          .eq(membership.conversation_id)
          .and(messages[:sequence].gt(membership.last_read_message&.sequence || 0))
      end.reduce { |combined, item| combined.or(item) }
      return {} unless predicate

      Message.where(predicate).group(:chat_room_id).count
    end
    private_class_method :unread_counts_by_conversation
  end
end
