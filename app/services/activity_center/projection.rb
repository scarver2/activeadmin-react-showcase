# app/services/activity_center/projection.rb
# frozen_string_literal: true

module ActivityCenter
  class Projection
    def self.broadcast(notification)
      admin_user = notification.recipient
      ActivityCenterChannel.broadcast_to(
        admin_user,
        type: "notification",
        notification: ActivityCenter::Serializer.new(notification.reload).as_json
      )
      ActivityCenter::UnreadProjection.broadcast(admin_user)
      true
    rescue StandardError => error
      Rails.logger.warn("Activity Center Cable projection failed: #{error.class}: #{error.message}")
      false
    end
  end
end
