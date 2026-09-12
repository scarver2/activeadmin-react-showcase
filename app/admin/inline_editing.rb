# app/admin/inline_editing.rb
# frozen_string_literal: true

ActiveAdmin.register_page "Inline Editing" do
  menu label: "Inline Editing", parent: "Data & Workflows", priority: 8

  content title: "Small optimistic inline-editing islands" do
    routes = Rails.application.routes.url_helpers
    accounts = Account.order(:name)

    panel("Demo") { para "Activate one status or region value by click or keyboard. Each focused island proposes one allowlisted change to Rails." }
    table_for accounts do
      column(:name) { |account| link_to(account.name, admin_account_path(account)) }
      column "Status" do |account|
        react_component(
          "InlineFieldEditor",
          props: { endpoint: routes.admin_inline_account_field_path(account), field: "status", label: "Status for #{account.name}", lockVersion: account.lock_version, options: Account::STATUSES, value: account.status },
          fallback: -> { safe_join([ content_tag(:span, account.status), " ", link_to("Edit", edit_admin_account_path(account)) ]) }
        )
      end
      column "Region" do |account|
        if InlineEditing::Policy.new(admin_user: current_admin_user, account:).permitted?("region")
          react_component(
            "InlineFieldEditor",
            props: { endpoint: routes.admin_inline_account_field_path(account), field: "region", label: "Region for #{account.name}", lockVersion: account.lock_version, options: Account::REGIONS, value: account.region },
            fallback: -> { safe_join([ content_tag(:span, account.region), " ", link_to("Edit", edit_admin_account_path(account)) ]) }
          )
        else
          status_tag(account.region, label: "Region locked while trial")
        end
      end
      column("Fallback") { |account| link_to("Open full record", admin_account_path(account)) }
    end
    panel("Ruby", id: "ruby-guidance") { para "InlineEditing::Policy makes record-and-field authorization explicit. Update applies validation and Active Record optimistic locking." }
    panel("JavaScript", id: "javascript-guidance") { para "Each component is one small island with keyboard activation, optimistic display, rollback, and focus restoration." }
    panel("Architecture", id: "architecture-guidance") do
      para "The surrounding ActiveAdmin table stays server rendered. Rails returns canonical values and lock versions; ordinary edit/show pages remain complete fallbacks."
      para link_to("Read the inline-editing guide", "https://github.com/scarver2/activeadmin-react-showcase/blob/master/docs/inline-editing.md")
    end
  end
end
