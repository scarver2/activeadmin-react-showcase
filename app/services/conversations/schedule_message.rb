# app/services/conversations/schedule_message.rb
# frozen_string_literal: true

module Conversations
  class ScheduleMessage
    class NotAuthorized < StandardError; end

    def self.call(conversation:, admin_user:, body:, scheduled_for:, at: Time.current)
      scheduled_message = ScheduledMessage.transaction do
        lock_membership!(conversation:, admin_user:)
        ScheduledMessage.create!(
          admin_user:,
          body: body.to_s.strip,
          conversation:,
          scheduled_for: future_time!(scheduled_for, at:)
        )
      end
      enqueue(scheduled_message)
      scheduled_message
    end

    def self.enqueue(scheduled_message)
      expected_revision = scheduled_message.schedule_revision
      job = DeliverScheduledMessageJob.set(wait_until: scheduled_message.scheduled_for).perform_later(
        scheduled_message.id,
        expected_revision
      )
      return scheduled_message if job

      mark_enqueue_failure(scheduled_message, "Active Job did not accept the delivery", expected_revision:)
    rescue ActiveJob::EnqueueError => error
      mark_enqueue_failure(scheduled_message, error.class.name, expected_revision:)
    end

    def self.lock_membership!(conversation:, admin_user:)
      membership = conversation.memberships.find_by(admin_user:, legacy_identity: false)
      raise NotAuthorized unless membership

      membership.lock!
      membership
    rescue ActiveRecord::RecordNotFound
      raise NotAuthorized
    end
    private_class_method :lock_membership!

    def self.future_time!(value, at:)
      scheduled_for = value.in_time_zone
      raise ActiveRecord::RecordInvalid, invalid_time_record(value) unless scheduled_for > at

      scheduled_for
    rescue ArgumentError, NoMethodError
      raise ActiveRecord::RecordInvalid, invalid_time_record(value)
    end
    def self.invalid_time_record(value)
      ScheduledMessage.new(scheduled_for: value).tap do |record|
        record.errors.add(:scheduled_for, "must be in the future")
      end
    end
    private_class_method :invalid_time_record

    def self.mark_enqueue_failure(scheduled_message, detail, expected_revision:)
      scheduled_message.with_lock do
        return scheduled_message unless scheduled_message.pending?
        return scheduled_message unless scheduled_message.schedule_revision == expected_revision

        scheduled_message.update!(
          failed_at: Time.current,
          failure_code: "enqueue_failed",
          failure_detail: detail.to_s.first(240),
          state: "failed"
        )
      end
      scheduled_message
    end
    private_class_method :mark_enqueue_failure
  end
end
