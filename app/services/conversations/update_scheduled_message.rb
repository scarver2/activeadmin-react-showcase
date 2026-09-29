# app/services/conversations/update_scheduled_message.rb
# frozen_string_literal: true

module Conversations
  class UpdateScheduledMessage
    class NotManageable < StandardError; end

    def self.call(scheduled_message:, admin_user:, body:, scheduled_for:, at: Time.current)
      ScheduledMessage.transaction do
        scheduled_message.lock!
        authorize!(scheduled_message:, admin_user:)
        raise NotManageable unless scheduled_message.manageable?

        scheduled_message.update!(
          body: body.to_s.strip,
          cancelled_at: nil,
          delivered_at: nil,
          delivered_message: nil,
          failed_at: nil,
          failure_code: nil,
          failure_detail: nil,
          schedule_revision: scheduled_message.schedule_revision + 1,
          scheduled_for: ScheduleMessage.future_time!(scheduled_for, at:),
          state: "pending"
        )
      end
      ScheduleMessage.enqueue(scheduled_message)
      scheduled_message
    end

    def self.authorize!(scheduled_message:, admin_user:)
      raise NotManageable unless scheduled_message.admin_user_id == admin_user.id

      membership = scheduled_message.conversation.memberships.find_by(admin_user:, legacy_identity: false)
      raise NotManageable unless membership

      membership.lock!
    rescue ActiveRecord::RecordNotFound
      raise NotManageable
    end
    private_class_method :authorize!
  end
end
