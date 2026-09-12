# app/admin/activity_center.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Activity Center" do
  menu label: "Activity Center", parent: "Collaboration", priority: 3

  content title: "Durable notification and activity center" do
    notifications = ActivityCenter::Seed.call(admin_user: current_admin_user)
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
          content_tag(:p, "The latest 100 authenticated notifications remain readable without JavaScript."),
          button_to("Create demo notification", routes.admin_activity_center_notifications_path, method: :post),
          content_tag(:ol) do
            safe_join(notifications.map do |item|
              content_tag(:li, safe_join([ link_to(item.subject, item.deep_link), content_tag(:span, " — #{item.body}") ]))
            end)
          end
        ])
      },
      class: "mt-6"
    )

    panel("Ruby", id: "ruby-guidance") { para "ActivityCenter::Create persists before broadcasting; scoped reads and mutations start from current_admin_user." }
    panel("JavaScript", id: "javascript-guidance") { para "The React island filters locally, deduplicates replay by sequence, and rolls back rejected read-state changes." }
    panel("Architecture", id: "architecture-guidance") do
      para "SQLite is authoritative. Solid Cable transports committed envelopes and replay closes reconnect gaps."
      para link_to("Read the activity-center guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/activity-center.md")
    end
  end
end
