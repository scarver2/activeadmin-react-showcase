# app/admin/dashboard.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu label: proc { safe_join([ showcase_icon(:dashboard, landmark: true), "Showcase Home" ]) },
       parent: "Overview", priority: 1

  content title: "Showcase Home" do
    metrics = DailyMetric.where(recorded_on: Date.current)

    panel "Rails-first, React where it earns its keep" do
      para "This application is the living reference implementation for activeadmin-react."
      para "The surrounding page, authentication, navigation, and data ownership remain Rails and ActiveAdmin concerns."
    end

    div class: "showcase-icon-actions", role: "group", "aria-label": "Showcase shortcuts" do
      a href: admin_accounts_path do
        text_node helpers.showcase_icon(:records)
        text_node "Browse accounts"
      end
      a href: "/admin/data_explorer" do
        text_node helpers.showcase_icon(:reports)
        text_node "Explore account data"
      end
    end

    react_component(
      "FoundationStatus",
      props: {
        accountCount: Account.count,
        activeUsers: metrics.sum(:active_users),
        privacyEnabled: showcase_privacy_enabled?,
        revenueCents: metrics.sum(:revenue_cents),
        source: Rails.application.config.x.activeadmin_react_source
      },
      fallback: -> { "Showcase metrics remain available from the server while JavaScript loads." },
      class: "mt-6"
    )
  end
end
