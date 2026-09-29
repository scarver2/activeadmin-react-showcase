# app/services/conversations/cancel_scheduled_message.rb
# frozen_string_literal: true

module Conversations
  class CancelScheduledMessage
    class NotCancellable < StandardError; end

    def self.call(scheduled_message:, admin_user:, at: Time.current)
      scheduled_message.with_lock do
        authorized = scheduled_message.admin_user_id == admin_user.id &&
                     scheduled_message.conversation.member?(admin_user)
        raise NotCancellable unless authorized && scheduled_message.manageable?

        scheduled_message.update!(cancelled_at: at, state: "cancelled")
      end
      scheduled_message
    end
  end
end
