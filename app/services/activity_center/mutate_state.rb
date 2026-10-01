# app/services/activity_center/mutate_state.rb
# frozen_string_literal: true

module ActivityCenter
  class MutateState
    SNOOZE_DURATION = 1.hour

    def self.call(notification:, mutation:, read: nil, now: Time.current)
      new(notification:, mutation:, read:, now:).call
    end

    def initialize(notification:, mutation:, read:, now:)
      @mutation = mutation.to_s
      @notification = notification
      @now = now
      @read = read
    end

    def call
      notification.with_lock do
        case mutation
        when "dismiss" then notification.update!(dismissed_at: now)
        when "read" then set_read_state
        when "restore" then notification.update!(dismissed_at: nil, snoozed_until: nil)
        when "snooze" then notification.update!(snoozed_until: now + SNOOZE_DURATION)
        else raise ActivityCenter::InvalidState, "unsupported notification mutation"
        end
      end
      ActivityCenter::Projection.broadcast(notification)
      notification
    end

    private

    attr_reader :mutation, :notification, :now, :read

    def set_read_state
      requested = ActiveModel::Type::Boolean.new.cast(read)
      return if requested == notification.read?

      requested ? notification.mark_as_read! : notification.mark_as_unread!
    end
  end
end
