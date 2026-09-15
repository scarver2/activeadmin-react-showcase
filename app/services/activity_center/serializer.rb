# app/services/activity_center/serializer.rb
# frozen_string_literal: true

module ActivityCenter
  class Serializer
    def initialize(notification)
      @notification = notification
    end

    def as_json(*)
      {
        id: notification.id,
        sequence: notification.sequence,
        kind: notification.kind,
        subject: notification.subject,
        body: notification.body,
        deepLink: notification.deep_link,
        occurredAt: notification.occurred_at.iso8601,
        read: notification.read_at?
      }
    end

    private

    attr_reader :notification
  end
end
