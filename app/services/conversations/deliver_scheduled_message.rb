# app/services/conversations/deliver_scheduled_message.rb
# frozen_string_literal: true

module Conversations
  class DeliverScheduledMessage
    def self.call(scheduled_message:, at: Time.current)
      delivered_message = nil
      ScheduledMessage.transaction do
        scheduled_message.lock!
        return scheduled_message.delivered_message if scheduled_message.state == "delivered"
        return if scheduled_message.state == "cancelled" || scheduled_message.scheduled_for > at

        scheduled_message.update!(
          attempt_count: scheduled_message.attempt_count + 1,
          last_attempted_at: at
        )
        membership = delivery_membership(scheduled_message)
        unless membership
          mark_failed(
            scheduled_message,
            at:,
            code: "membership_unavailable",
            detail: "Author is no longer a member"
          )
          return
        end

        delivered_message = scheduled_message.conversation.messages.find_by(
          author: membership,
          public_id: scheduled_message.delivery_public_id
        )
        delivered_message ||= CreateMessage.call(
          body: scheduled_message.body,
          conversation: scheduled_message.conversation,
          membership:,
          public_id: scheduled_message.delivery_public_id
        )
        scheduled_message.update!(
          delivered_at: at,
          delivered_message:,
          failed_at: nil,
          failure_code: nil,
          failure_detail: nil,
          state: "delivered"
        )
      end
      delivered_message
    rescue StandardError => error
      record_failure(scheduled_message, error, at:)
      nil
    end

    def self.delivery_membership(scheduled_message)
      scheduled_message.conversation.memberships.find_by(
        admin_user_id: scheduled_message.admin_user_id,
        legacy_identity: false
      )
    end
    private_class_method :delivery_membership

    def self.mark_failed(scheduled_message, at:, code:, detail:)
      scheduled_message.update!(
        failed_at: at,
        failure_code: code,
        failure_detail: detail.to_s.first(240),
        state: "failed"
      )
    end
    private_class_method :mark_failed

    def self.record_failure(scheduled_message, error, at:)
      scheduled_message.reload
      return if scheduled_message.state.in?(%w[cancelled delivered])

      scheduled_message.update!(
        attempt_count: scheduled_message.attempt_count + (scheduled_message.last_attempted_at == at ? 0 : 1),
        failed_at: at,
        failure_code: "delivery_failed",
        failure_detail: error.class.name.first(240),
        last_attempted_at: at,
        state: "failed"
      )
    rescue ActiveRecord::ActiveRecordError
      nil
    end
    private_class_method :record_failure
  end
end
