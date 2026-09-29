# app/services/activity_center/unread_projection.rb
# frozen_string_literal: true

module ActivityCenter
  class UnreadProjection
    def self.broadcast(admin_user)
      ActivityCenterChannel.broadcast_to(admin_user, envelope(admin_user))
    end

    def self.envelope(admin_user)
      {
        type: "unread_count",
        unreadCount: admin_user.notifications.unread.count,
        latestSequence: admin_user.notifications.maximum(:id).to_i
      }
    end
  end
end
