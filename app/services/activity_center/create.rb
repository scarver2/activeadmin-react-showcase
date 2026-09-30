# app/services/activity_center/create.rb
# frozen_string_literal: true

module ActivityCenter
  class Create
    def self.call(admin_user:, attributes:, attention_kind: "fyi", enqueue_delivery: true, priority: "normal", record: nil)
      raise ArgumentError, "unsupported attention kind" unless attention_kind.in?(ActivityCenter::ATTENTION_KINDS)
      raise ArgumentError, "unsupported priority" unless priority.in?(ActivityCenter::PRIORITIES)

      event = ActivityNotifier.with(attributes.slice(:body, :deep_link, :kind, :occurred_at, :subject).merge(record:))
                              .deliver(admin_user, enqueue_job: enqueue_delivery)
      event.notifications.first!.tap do |notification|
        notification.update!(attention_kind:, priority:)
      end
    end
  end
end
