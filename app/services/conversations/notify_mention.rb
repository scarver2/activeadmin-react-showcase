# app/services/conversations/notify_mention.rb
# frozen_string_literal: true

module Conversations
  class NotifyMention
    def self.call(mention:)
      recipient = mention.mentioned_membership.admin_user
      return if recipient.nil?

      message = mention.message
      existing = recipient.notifications.joins(:event).find_by(
        noticed_events: {
          record_id: message.id,
          record_type: message.class.polymorphic_name,
          type: ConversationMentionNotifier.name
        }
      )
      return existing if existing

      conversation = message.conversation
      event = ConversationMentionNotifier.with(
        body: "#{message.author.display_name} mentioned you in #{conversation.title}.",
        deep_link: deep_link(message),
        kind: "conversation",
        occurred_at: mention.created_at,
        record: message,
        subject: "You were mentioned"
      ).deliver(recipient)
      event.notifications.first!
    end

    def self.deep_link(message)
      routes = Rails.application.routes.url_helpers
      "#{routes.admin_conversation_path(message.conversation.public_id)}#message-#{message.public_id}"
    end
    private_class_method :deep_link
  end
end
