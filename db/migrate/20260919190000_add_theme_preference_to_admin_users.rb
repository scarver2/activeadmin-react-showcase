# db/migrate/20260919190000_add_theme_preference_to_admin_users.rb
# frozen_string_literal: true

class AddThemePreferenceToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :theme_preference, :string, default: "v3", null: false
  end
end
