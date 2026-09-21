# app/admin/dashboard.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu label: proc { safe_join([ showcase_icon(:dashboard, landmark: true), "Showcase Home" ]) },
       parent: "Overview", priority: 1

  content title: "Showcase Home" do
    metrics = DailyMetric.where(recorded_on: Date.current)

    react_component(
      "MasterDashboard",
      props: {
        groups: Showcase::WorkspaceCatalog.groups,
        metrics: [
          { label: "Accounts", value: number_with_delimiter(Account.count), detail: "Portfolio records" },
          { label: "Active users", value: number_with_delimiter(metrics.sum(:active_users)), detail: "Engaged today" },
          {
            label: "Monthly revenue",
            value: number_to_currency(metrics.sum(:revenue_cents) / 100.0, precision: 0),
            detail: "Seeded operating view"
          }
        ]
      },
      fallback: lambda {
        safe_join([
          content_tag(:p, "All dashboard workspaces remain available without JavaScript."),
          *Showcase::WorkspaceCatalog.groups.map do |group|
            content_tag(:section) do
              safe_join([ content_tag(:h2, group.fetch(:label)), content_tag(:ul) do
                safe_join(group.fetch(:tools).map { |tool| content_tag(:li, link_to(tool.fetch(:label), tool.fetch(:url))) })
              end ])
            end
          end
        ])
      },
      class: "master-dashboard-mount"
    )
  end
end
