# app/admin/accounts.rb
# frozen_string_literal: true

ActiveAdmin.register Account do
  menu parent: "Data & Reporting", priority: 10

  actions :index, :show, :edit, :update
  permit_params :region, :status

  filter :name
  filter :plan
  filter :region
  filter :status

  member_action :inspector, method: :get do
    authorize! :read, resource

    render json: Showcase::AccountInspector.new(
      account: resource,
      can_edit: authorized?(:update, resource)
    ).as_json
  end

  index do
    selectable_column
    id_column
    column(:name) { |account| link_to(account.name, admin_account_path(account)) }
    column :plan
    column :region
    column :status
    column("Latest active users") { |account| account.daily_metrics.order(recorded_on: :desc).pick(:active_users) }
    column "Context" do |account|
      react_component(
        "AccountInspectorLauncher",
        props: {
          canonicalHref: admin_account_path(account),
          collectionHref: admin_accounts_path,
          inspectorHref: inspector_admin_account_path(account, format: :json),
          label: "Inspect",
          name: account.name
        },
        fallback: -> { link_to("Open #{account.name}", admin_account_path(account)) },
        class: "account-inspector-index-launcher"
      )
    end
    actions
  end
end
