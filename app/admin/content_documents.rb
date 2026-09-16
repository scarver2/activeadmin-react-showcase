# app/admin/content_documents.rb
# frozen_string_literal: true

ActiveAdmin.register ContentDocument do
  menu false
  scope_to :current_admin_user
  permit_params :title
end
