# app/services/conversations/message_snapshot.rb
# frozen_string_literal: true

module Conversations
  class MessageSnapshot
    class NotAuthorized < StandardError; end

    def initialize(message, viewer_membership:)
      raise NotAuthorized unless viewer_membership.conversation_id == message.conversation_id

      @message = message
      @viewer_membership = viewer_membership
    end

    def as_json(*)
      {
        id: message.public_id,
        sequence: message.sequence,
        author: author_payload(message.author),
        body: visible_body(message),
        withdrawn: message.withdrawn?,
        replyTo: reply_payload,
        mentions: mention_payload,
        dispositions: dispositions,
        occurredAt: message.created_at.iso8601,
        editedAt: message.edited_at&.iso8601
      }
    end

    def dispositions
      counts = MessageDisposition::KINDS.to_h { |kind| [ kind, 0 ] }
      mine = nil
      message.dispositions.each do |disposition|
        counts[disposition.kind] += 1
        mine = disposition.kind if disposition.membership_id == viewer_membership.id
      end
      { counts:, mine: }
    end

    private

    attr_reader :message, :viewer_membership

    def author_payload(membership)
      { key: membership.key, name: membership.display_name }
    end

    def mention_payload
      message.mentions.includes(:mentioned_membership).order(:id).map do |mention|
        {
          memberKey: mention.mentioned_membership.key,
          text: mention.mention_text
        }
      end
    end

    def reply_payload
      replied_to = message.reply_to_message
      return if replied_to.nil?

      {
        id: replied_to.public_id,
        sequence: replied_to.sequence,
        author: author_payload(replied_to.author),
        body: visible_body(replied_to),
        withdrawn: replied_to.withdrawn?
      }
    end

    def visible_body(record)
      record.withdrawn? ? Message::WITHDRAWN_BODY : record.body
    end
  end
end
