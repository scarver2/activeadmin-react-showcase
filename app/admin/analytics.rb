# app/admin/analytics.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Analytics" do
  menu label: "Analytics Dashboard", parent: "Data & Reporting", priority: 1

  content title: "Interactive Analytics Dashboard" do
    start_date = 29.days.ago.to_date
    end_date = Date.current
    metrics = DailyMetric.where(recorded_on: start_date..end_date)

    panel "Demo" do
      para <<~TEXT.squish
        Filter the seeded operating data, refresh it through an authenticated Rails endpoint,
        and inspect KPI, trend, account, and plan visualizations.
      TEXT
      para link_to("Jump to Ruby", "#ruby-guidance") + " · " +
           link_to("Jump to JavaScript", "#javascript-guidance") + " · " +
           link_to("Jump to Architecture", "#architecture-guidance")
    end

    react_component(
      "AnalyticsDashboard",
      props: {
        endpoint: admin_analytics_data_path,
        initialEndDate: end_date.iso8601,
        initialStartDate: start_date.iso8601
      },
      fallback: lambda {
        revenue = ActiveSupport::NumberHelper.number_to_currency(metrics.sum(:revenue_cents) / 100.0)
        "Last 30 days: #{metrics.sum(:active_users)} active-user observations, #{revenue} revenue, " \
          "across #{Account.count} accounts. Use the date controls when JavaScript is available."
      },
      class: "mt-6"
    )

    panel "Ruby", id: "ruby-guidance" do
      para <<~TEXT.squish
        Rails authenticates /admin/analytics/data, validates a maximum 90-day ISO 8601 range,
        and shapes a database-portable JSON contract.
      TEXT
      para link_to(
        "Read the endpoint source",
        "https://github.com/scarver2/activeadmin-react-showcase/blob/master/app/controllers/admin/analytics_data_controller.rb"
      )
      pre code("get \"analytics/data\", to: \"analytics_data#show\", defaults: { format: :json }")
    end

    panel "JavaScript", id: "javascript-guidance" do
      para <<~TEXT.squish
        The React island owns transient loading, error, empty, and populated UI.
        Recharts remains an application dependency rather than a gem dependency.
      TEXT
      para link_to(
        "Read the component source",
        "https://github.com/scarver2/activeadmin-react-showcase/blob/master/app/frontend/components/AnalyticsDashboard.tsx"
      )
      pre code('registerComponent("AnalyticsDashboard", AnalyticsDashboard)')
    end

    panel "Architecture", id: "architecture-guidance" do
      para <<~TEXT.squish
        Rails owns authentication and data; activeadmin-react owns the lifecycle boundary;
        the island fetches only bounded, read-only snapshots with an eight-second timeout.
        Cable is not used to perform analytics work.
      TEXT
      para link_to("Read the architecture guide", admin_architecture_path) + " · " +
           link_to("Explore Recharts", "https://recharts.github.io") + " · " +
           link_to("Explore activeadmin-react", "https://github.com/scarver2/activeadmin-react")
    end
  end
end
