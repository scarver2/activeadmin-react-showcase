# app/admin/schedule_events.rb
# frozen_string_literal: true

ActiveAdmin.register ScheduleEvent do
  menu false
  scope_to :current_admin_user

  permit_params :ends_at, :location, :notes, :starts_at, :time_zone, :title

  config.sort_order = "starts_at_asc"

  index do
    selectable_column
    id_column
    column :title
    column :starts_at
    column :ends_at
    column :time_zone
    column :location
    actions
  end

  form do |form|
    form.semantic_errors
    form.inputs do
      form.input :title
      form.input :starts_at
      form.input :ends_at
      form.input :time_zone, as: :select, collection: ScheduleEvent::TIME_ZONES
      form.input :location
      form.input :notes
    end
    form.actions
  end

  show do
    attributes_table do
      row :title
      row :starts_at
      row :ends_at
      row :time_zone
      row :location
      row :notes
      row :lock_version
    end
  end
end
