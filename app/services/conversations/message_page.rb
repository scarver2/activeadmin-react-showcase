# app/services/conversations/message_page.rb
# frozen_string_literal: true

module Conversations
  class MessagePage
    LIMIT = 50

    Result = Data.define(:messages, :older_cursor)

    def self.call(conversation:, before: nil)
      cursor = parse_cursor(before)
      scope = conversation.messages.includes(:author).order(sequence: :desc, id: :desc)
      scope = scope.where(Message.arel_table[:sequence].lt(cursor)) if cursor
      messages = scope.limit(LIMIT).to_a.reverse
      older_cursor = messages.first&.sequence if messages.first && conversation.messages.where(
        Message.arel_table[:sequence].lt(messages.first.sequence)
      ).exists?
      Result.new(messages:, older_cursor:)
    end

    def self.parse_cursor(raw_cursor)
      return if raw_cursor.blank?

      cursor = Integer(raw_cursor, exception: false)
      raise ActionController::BadRequest, "before must be a positive message sequence" unless cursor&.positive?

      cursor
    end
    private_class_method :parse_cursor
  end
end
