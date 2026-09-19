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

  index do
    selectable_column
    id_column
    column :name
    column :plan
    column :region
    column :status
    column("Latest active users") { |account| account.daily_metrics.order(recorded_on: :desc).pick(:active_users) }
    actions
  end
end
