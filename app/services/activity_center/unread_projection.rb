# app/services/activity_center/unread_projection.rb
# frozen_string_literal: true

module ActivityCenter
  class UnreadProjection
    def self.broadcast(admin_user)
      ActionCable.server.broadcast(Create.channel_for(admin_user), envelope(admin_user))
    end

    def self.envelope(admin_user)
      {
        type: "unread_count",
        unreadCount: admin_user.activity_notifications.unread.count,
        latestSequence: admin_user.activity_notifications.maximum(:sequence).to_i
      }
    end
  end
end
