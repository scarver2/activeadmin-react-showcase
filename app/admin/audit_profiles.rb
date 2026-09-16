# app/admin/audit_profiles.rb
# frozen_string_literal: true

ActiveAdmin.register AuditProfile do
  menu false
  scope_to :current_admin_user
  permit_params :name, :plan, :preferences
end
