# app/admin/contacts.rb
# frozen_string_literal: true

ActiveAdmin.register Contact do
  menu parent: "Collaboration", priority: 10

  actions :index, :show

  filter :account
  filter :first_name
  filter :last_name
  filter :email
  filter :job_title
  filter :relationship_role, as: :select, collection: Contact::RELATIONSHIP_ROLES

  index do
    selectable_column
    id_column
    column("Name", &:full_name)
    column :account
    column :job_title
    column :relationship_role
    column :email
    actions
  end
end
