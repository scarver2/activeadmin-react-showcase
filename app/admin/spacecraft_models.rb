# app/admin/spacecraft_models.rb
# frozen_string_literal: true

ActiveAdmin.register SpacecraftModel do
  menu false
  scope_to :current_admin_user
  permit_params :finish, :name, :selected_component_id
end
