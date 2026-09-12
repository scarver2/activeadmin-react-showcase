# app/admin/image_annotations.rb
# frozen_string_literal: true

ActiveAdmin.register ImageAnnotation do
  menu false
  scope_to :current_admin_user
  permit_params(*ImageEditor::Save::ATTRIBUTES)
end
