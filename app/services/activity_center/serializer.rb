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
        attentionKind: notification.attention_kind,
        availableAction: available_action,
        id: notification.id,
        sequence: notification.id,
        kind: attributes.fetch(:kind),
        subject: attributes.fetch(:subject),
        body: attributes.fetch(:body),
        deepLink: attributes.fetch(:deep_link),
        occurredAt: occurred_at(attributes).iso8601,
        read: notification.read?,
        priority: notification.priority,
        snoozedUntil: notification.snoozed_until&.iso8601,
        dismissed: notification.dismissed_at.present?
      }
    end

    private

    attr_reader :notification

    def available_action
      record = notification.event.record
      return unless record.is_a?(WorkflowItem) && record.state == "review"

      {
        label: "Complete review",
        url: Rails.application.routes.url_helpers.action_admin_activity_center_notification_path(notification)
      }
    end

    def occurred_at(attributes)
      value = attributes.fetch(:occurred_at, notification.created_at)
      value.is_a?(String) ? Time.zone.parse(value) : value
    end
  end
end
