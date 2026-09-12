# app/admin/social_people.rb
# frozen_string_literal: true

ActiveAdmin.register SocialPerson do
  menu false
  scope_to :current_admin_user
  permit_params :headline, :name
end
