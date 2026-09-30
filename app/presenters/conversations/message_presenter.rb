# app/presenters/conversations/message_presenter.rb
# frozen_string_literal: true

module Conversations
  class MessagePresenter
    def initialize(message, viewer_membership:, at: Time.current)
      @at = at
      @message = message
      @viewer_membership = viewer_membership
    end

    attr_reader :message

    def author_name
      message.author.display_name
    end

    def body
      message.withdrawn? ? Message::WITHDRAWN_BODY : message.body
    end

    def dispositions
      MessageSnapshot.new(message, viewer_membership: @viewer_membership).dispositions
    end

    def editable?
      message.editable_by?(@viewer_membership, at: @at)
    end

    def edited?
      message.edited_at.present? && !message.withdrawn?
    end

    def mentions
      message.mentions.includes(:mentioned_membership).order(:id)
    end

    def reply_to_message
      message.reply_to_message
    end

    def withdrawn?
      message.withdrawn?
    end
  end
end
