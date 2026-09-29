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
      @saved_message_ids = saved_message_ids
    end

    def as_json
      {
        inbox: @inbox_entries.map { |entry| serialize_inbox_entry(entry) },
        inboxUrl: routes.admin_conversations_path(format: :json),
        savedMessagesUrl: routes.saved_admin_conversations_path,
        searchUrl: routes.admin_conversation_search_path,
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
        memberCount: conversation.memberships.size,
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
      snapshot = MessageSnapshot.new(message, viewer_membership: @membership)
      conversation = @membership.conversation
      {
        attachment: serialize_attachment(message),
        authorName: presenter.author_name,
        body: presenter.body,
        createdAt: message.created_at.iso8601,
        deepLinkUrl: "#{routes.admin_conversation_path(conversation.public_id)}#message-#{message.public_id}",
        dispositions: snapshot.dispositions,
        dispositionUrl: routes.admin_conversation_message_disposition_path(
          conversation.public_id,
          message.public_id,
          format: :json
        ),
        editUrl: routes.admin_conversation_message_path(conversation.public_id, message.public_id, format: :json),
        editable: presenter.editable?,
        edited: presenter.edited?,
        markReadUrl: routes.admin_conversation_read_state_path(conversation.public_id, message.public_id, format: :json),
        markUnreadUrl: routes.admin_conversation_unread_state_path(conversation.public_id, message.public_id, format: :json),
        own: message.author_id == @membership.id,
        publicId: message.public_id,
        mentions: serialize_mentions(message),
        replyTo: serialize_reply(message),
        saved: @saved_message_ids.include?(message.id),
        savedUrl: routes.admin_conversation_saved_message_path(conversation.public_id, message.public_id, format: :json),
        sequence: message.sequence,
        withdrawUrl: routes.admin_conversation_withdraw_message_path(conversation.public_id, message.public_id, format: :json),
        withdrawn: presenter.withdrawn?
      }
    end

    def serialize_mentions(message)
      return [] if message.withdrawn?

      message.mentions.includes(:mentioned_membership).order(:id).map do |mention|
        {
          memberKey: mention.mentioned_membership.key,
          text: mention.mention_text
        }
      end
    end

    def serialize_reply(message)
      replied_to = message.reply_to_message
      return if replied_to.nil?

      {
        authorName: replied_to.author.display_name,
        body: replied_to.withdrawn? ? Message::WITHDRAWN_BODY : replied_to.body,
        publicId: replied_to.public_id,
        withdrawn: replied_to.withdrawn?
      }
    end

    def serialize_attachment(message)
      attachment = message.attachment
      return if attachment.nil? || message.withdrawn?

      {
        byteSize: attachment.file.byte_size,
        contentType: attachment.file.content_type,
        filename: attachment.file.filename.to_s,
        inline: attachment.inline?,
        url: routes.admin_conversation_message_attachment_path(
          @membership.conversation.public_id,
          message.public_id,
          attachment.public_id
        )
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
        participants: conversation.memberships.order(:display_name, :id).map do |participant|
          {
            current: participant.id == @membership.id,
            displayName: participant.display_name,
            key: participant.key
          }
        end,
        publicId: conversation.public_id,
        presence: {
          channel: "ConversationPresenceChannel",
          heartbeatIntervalMs: 15_000,
          typingIdleMs: 3_000
        },
        realtime: {
          channel: "ConversationChannel",
          latestSequence: conversation.messages.maximum(:sequence).to_i,
          serverAt: Time.current.iso8601(6),
          version: conversation.realtime_version
        },
        messagesUrl: routes.admin_conversation_messages_path(conversation.public_id, format: :json),
        scheduledMessagesUrl: routes.admin_conversation_scheduled_messages_path(conversation.public_id),
        showUrl: routes.admin_conversation_path(conversation.public_id),
        title: conversation.title,
        topic: conversation.topic,
        unreadCount: @membership.unread_count
      }
    end

    def saved_message_ids
      return Set.new if @membership.nil?

      relation = @membership.saved_messages
      relation = relation.where(message_id: @message_page.messages) if @message_page
      relation.pluck(:message_id).to_set
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end
