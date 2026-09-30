# app/services/activity_center/serializer.rb
# frozen_string_literal: true

module ActivityCenter
  class Serializer
    def initialize(notification)
      @notification = notification
    end

    def as_json(*)
      attributes = notification.params.with_indifferent_access
      {
        id: notification.id,
        sequence: notification.id,
        kind: attributes.fetch(:kind),
        subject: attributes.fetch(:subject),
        body: attributes.fetch(:body),
        deepLink: attributes.fetch(:deep_link),
        occurredAt: occurred_at(attributes).iso8601,
        read: notification.read?
      }
    end

    private

    attr_reader :notification

    def occurred_at(attributes)
      value = attributes.fetch(:occurred_at, notification.created_at)
      value.is_a?(String) ? Time.zone.parse(value) : value
    end
  end
end
