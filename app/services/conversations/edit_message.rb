# app/services/conversations/edit_message.rb
# frozen_string_literal: true

module Conversations
  class EditMessage
    class EditWindowClosed < StandardError; end

    def self.call(message:, membership:, body:, at: nil)
      message.with_lock do
        message.reload
        effective_at = at || Time.current
        raise EditWindowClosed unless message.editable_by?(membership, at: effective_at)

        stripped_body = body.to_s.strip
        return message if stripped_body == message.body

        message.update!(body: stripped_body, edited_at: effective_at)
      end
      message
    end
  end
end
