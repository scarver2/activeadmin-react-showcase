# app/services/conversations/update_scheduled_message.rb
# frozen_string_literal: true

module Conversations
  class UpdateScheduledMessage
    class NotManageable < StandardError; end

    def self.call(scheduled_message:, admin_user:, body:, scheduled_for:, at: Time.current)
      authorize!(scheduled_message:, admin_user:)
      scheduled_message.with_lock do
        raise NotManageable unless scheduled_message.manageable?

        scheduled_message.update!(
          body: body.to_s.strip,
          failed_at: nil,
          failure_code: nil,
          failure_detail: nil,
          scheduled_for: ScheduleMessage.future_time!(scheduled_for, at:),
          state: "pending"
        )
      end
      ScheduleMessage.enqueue(scheduled_message)
      scheduled_message
    end

    def self.authorize!(scheduled_message:, admin_user:)
      raise NotManageable unless scheduled_message.admin_user_id == admin_user.id
      raise NotManageable unless scheduled_message.conversation.member?(admin_user)
    end
    private_class_method :authorize!
  end
end
