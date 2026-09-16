# app/services/activity_center/create.rb
# frozen_string_literal: true

module ActivityCenter
  class Create
    def self.call(admin_user:, attributes:)
      notification = admin_user.with_lock do
        admin_user.activity_notifications.create!(
          attributes.slice(:body, :deep_link, :kind, :occurred_at, :subject).merge(
            sequence: admin_user.activity_notifications.maximum(:sequence).to_i + 1
          )
        )
      end

      ActionCable.server.broadcast(
        channel_for(admin_user),
        { type: "notification", notification: Serializer.new(notification).as_json }
      )
      notification
    end

    def self.channel_for(admin_user)
      "activity_center:admin:#{admin_user.id}"
    end
  end
end
