# app/admin/csv_imports.rb
# frozen_string_literal: true

ActiveAdmin.register CsvImport do
  menu false
  scope_to :current_admin_user
  actions :index, :show
end
