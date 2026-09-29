# app/services/activity_center/create.rb
# frozen_string_literal: true

module ActivityCenter
  class Create
    def self.call(admin_user:, attributes:, enqueue_delivery: true)
      event = ActivityNotifier.with(attributes.slice(:body, :deep_link, :kind, :occurred_at, :subject))
                              .deliver(admin_user, enqueue_job: enqueue_delivery)
      event.notifications.first!
    end
  end
end
