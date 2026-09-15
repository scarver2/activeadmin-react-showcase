# app/admin/material_spheres.rb
# frozen_string_literal: true

ActiveAdmin.register MaterialSphere do
  menu false
  scope_to :current_admin_user
  permit_params :finish, :name
end
