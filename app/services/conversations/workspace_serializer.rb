# app/services/conversations/workspace_serializer.rb
# frozen_string_literal: true

module Conversations
  class WorkspaceSerializer
    def self.call(inbox_entries:, membership: nil, message_page: nil)
      new(inbox_entries:, membership:, message_page:).as_json
    end

    def self.message(message:, membership:)
      new(inbox_entries: [], membership:).message_as_json(message)
    end

    def initialize(inbox_entries:, membership: nil, message_page: nil)
      @inbox_entries = inbox_entries
      @membership = membership
      @message_page = message_page
    end

    def as_json
      {
        inbox: @inbox_entries.map { |entry| serialize_inbox_entry(entry) },
        inboxUrl: routes.admin_conversations_path(format: :json),
        selected: serialize_selected
      }
    end

    def message_as_json(message)
      serialize_message(message)
    end

    private

    def serialize_inbox_entry(entry)
      conversation = entry.membership.conversation
      {
        lastActivityAt: conversation.last_activity_at.iso8601,
        publicId: conversation.public_id,
        messagesUrl: routes.admin_conversation_messages_path(conversation.public_id, format: :json),
        showUrl: routes.admin_conversation_path(conversation.public_id),
        title: conversation.title,
        topic: conversation.topic,
        unreadCount: entry.unread_count
      }
    end

    def serialize_message(message)
      presenter = MessagePresenter.new(message, viewer_membership: @membership)
      conversation = @membership.conversation
      {
        authorName: presenter.author_name,
        body: presenter.body,
        createdAt: message.created_at.iso8601,
        editUrl: routes.admin_conversation_message_path(conversation.public_id, message.public_id, format: :json),
        editable: presenter.editable?,
        edited: presenter.edited?,
        markReadUrl: routes.admin_conversation_read_state_path(conversation.public_id, message.public_id, format: :json),
        markUnreadUrl: routes.admin_conversation_unread_state_path(conversation.public_id, message.public_id, format: :json),
        own: message.author_id == @membership.id,
        publicId: message.public_id,
        sequence: message.sequence,
        withdrawUrl: routes.admin_conversation_withdraw_message_path(conversation.public_id, message.public_id, format: :json),
        withdrawn: presenter.withdrawn?
      }
    end

    def serialize_selected
      return if @membership.nil? || @message_page.nil?

      conversation = @membership.conversation
      {
        createUrl: routes.admin_conversation_messages_path(conversation.public_id, format: :json),
        displayName: @membership.display_name,
        draftNamespace: @membership.key,
        messages: @message_page.messages.map { |message| serialize_message(message) },
        olderCursor: @message_page.older_cursor,
        publicId: conversation.public_id,
        messagesUrl: routes.admin_conversation_messages_path(conversation.public_id, format: :json),
        scheduledMessagesUrl: routes.admin_conversation_scheduled_messages_path(conversation.public_id),
        showUrl: routes.admin_conversation_path(conversation.public_id),
        title: conversation.title,
        topic: conversation.topic,
        unreadCount: @membership.unread_count
      }
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end
