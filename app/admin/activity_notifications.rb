# app/admin/activity_notifications.rb
# frozen_string_literal: true

ActiveAdmin.register ActivityNotification do
  menu false
  scope_to :current_admin_user
  actions :index, :show

  filter :kind, as: :select, collection: ActivityNotification::KINDS
  filter :subject

  index do
    column :sequence
    column :kind
    column :subject
    column :occurred_at
    column :read_at
    actions
  end
end
