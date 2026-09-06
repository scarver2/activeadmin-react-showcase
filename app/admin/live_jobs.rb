# app/admin/live_jobs.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Live Jobs" do
  menu label: "Live Jobs", parent: "Operations", priority: 1

  content title: "Live Jobs / Operations Center" do
    operations = current_admin_user.operations.recent_first.limit(20)

    panel "Persistent work, live transport" do
      para "Solid Queue performs bounded work and SQLite preserves every lifecycle event. Solid Cable only transports state."
      para do
        text_node "This application consumes the "
        a "activeadmin-react operation protocol", href: "https://github.com/scarver2/activeadmin-react#asynchronous-action-cable-operations"
        text_node "."
      end
    end

    react_component(
      "OperationsCenter",
      props: {
        createUrl: Rails.application.routes.url_helpers.admin_operations_path,
        operations: operations.map { |operation| Operations::Serializer.new(operation).as_json },
        telemetry: Showcase::Telemetry::Snapshot.new.as_json
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "Live updates need JavaScript, but operation state and controls remain server-owned."),
          form_with(url: Rails.application.routes.url_helpers.admin_operations_path, method: :post) do |form|
            safe_join([
              form.hidden_field(:kind, value: "successful_demo"),
              form.submit("Start bounded demo operation")
            ])
          end,
          content_tag(:ul) do
            safe_join(operations.map do |operation|
              content_tag(:li, "#{operation.public_id}: #{operation.state} — #{operation.progress}% — #{operation.message}")
            end)
          end
        ])
      },
      class: "mt-6"
    )
  end
end
