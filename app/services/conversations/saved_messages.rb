# app/services/conversations/saved_messages.rb
# frozen_string_literal: true

module Conversations
  class SavedMessages
    LIMIT = 100

    def self.call(admin_user:)
      SavedMessage
        .joins(:membership)
        .where(chat_participants: { admin_user_id: admin_user.id })
        .includes(:conversation, message: :author)
        .order(created_at: :desc, id: :desc)
        .limit(LIMIT)
        .to_a
    end
  end
end
