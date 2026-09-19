# app/admin/hierarchy_nodes.rb
# frozen_string_literal: true

ActiveAdmin.register HierarchyNode do
  menu false
  scope_to :current_admin_user

  permit_params :parent_id, :position, :title

  index do
    id_column
    column :title
    column :parent
    column :position
    actions
  end

  form do |form|
    form.semantic_errors
    form.inputs do
      form.input :title
      form.input :parent, collection: current_admin_user.hierarchy_nodes.where.not(id: form.object.id).order(:title)
      form.input :position
    end
    form.actions
  end
end
