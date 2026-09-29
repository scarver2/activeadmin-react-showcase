# app/services/conversations/cancel_scheduled_message.rb
# frozen_string_literal: true

module Conversations
  class CancelScheduledMessage
    class NotCancellable < StandardError; end

    def self.call(scheduled_message:, admin_user:, at: Time.current)
      ScheduledMessage.transaction do
        scheduled_message.lock!
        membership = scheduled_message.conversation.memberships.find_by(
          admin_user:,
          legacy_identity: false
        )
        membership&.lock!
        authorized = scheduled_message.admin_user_id == admin_user.id && membership
        raise NotCancellable unless authorized && scheduled_message.manageable?

        scheduled_message.update!(
          cancelled_at: at,
          delivered_at: nil,
          delivered_message: nil,
          failed_at: nil,
          failure_code: nil,
          failure_detail: nil,
          schedule_revision: scheduled_message.schedule_revision + 1,
          state: "cancelled"
        )
      end
      scheduled_message
    rescue ActiveRecord::RecordNotFound
      raise NotCancellable
    end
  end
end
