# app/admin/activity_center.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Activity Center" do
  menu label: "Activity Center", parent: "Collaboration", priority: 3

  content title: "Durable notification and activity center" do
    inbox = ActivityCenter::Inbox.new(admin_user: current_admin_user)
    notifications = current_admin_user.notifications.includes(event: :record).newest_first.limit(100)
    routes = Rails.application.routes.url_helpers

    panel "Demo" do
      para "Filter and group persisted activity, change unread state, follow deep links, and exercise Solid Cable replay."
    end

    react_component(
      "ActivityCenter",
      props: {
        createUrl: routes.admin_activity_center_notifications_path,
        endpoint: routes.admin_activity_center_notifications_path,
        notifications: notifications.map { |item| ActivityCenter::Serializer.new(item).as_json }
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "The latest 100 authenticated notifications remain actionable without JavaScript."),
          button_to("Create demo notification", routes.admin_activity_center_notifications_path, method: :post),
          content_tag(:ol) do
            safe_join(notifications.map do |item|
              serialized = ActivityCenter::Serializer.new(item).as_json
              content_tag(:li, safe_join([
                link_to(serialized.fetch(:subject), serialized.fetch(:deepLink)),
                content_tag(:span, " — #{serialized.fetch(:body)}"),
                content_tag(:span, " — #{serialized.fetch(:attentionKind).humanize}, #{serialized.fetch(:priority)} priority"),
                button_to(
                  "Mark #{serialized.fetch(:read) ? 'unread' : 'read'}",
                  routes.admin_activity_center_notification_path(item),
                  method: :patch,
                  params: { read: !serialized.fetch(:read) }
                ),
                serialized.fetch(:dismissed) ? nil : button_to("Snooze for one hour", routes.snooze_admin_activity_center_notification_path(item), method: :patch),
                serialized.fetch(:dismissed) ? nil : button_to("Dismiss", routes.dismiss_admin_activity_center_notification_path(item), method: :patch),
                (serialized.fetch(:dismissed) || serialized.fetch(:snoozedUntil).present?) ? button_to("Restore", routes.restore_admin_activity_center_notification_path(item), method: :patch) : nil,
                serialized.fetch(:availableAction) ? button_to("Complete review", routes.action_admin_activity_center_notification_path(item), method: :post) : nil
              ]))
            end)
          end
        ])
      },
      class: "mt-6"
    )

    para "#{inbox.unread_count} active unread notifications contribute to the bell count. Dismissed and currently snoozed items do not."

    panel("Ruby", id: "ruby-guidance") do
      para "Noticed persists recipient events before delivery; scoped reads and mutations start from current_admin_user."
    end
    panel("JavaScript", id: "javascript-guidance") do
      para "The page island filters locally and rolls back rejected read-state changes. A separate title-bar bell projects the Rails unread count without owning notification state."
    end
    panel("Architecture", id: "architecture-guidance") do
      para "SQLite owns Noticed event and read truth. Solid Cable transports committed envelopes and canonical unread-count projections; replay closes reconnect gaps without double-counting."
      para link_to("Read the activity-center guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/activity-center.md")
    end
  end
end
