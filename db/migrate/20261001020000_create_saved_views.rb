# db/migrate/20261001020000_create_saved_views.rb
# frozen_string_literal: true

class CreateSavedViews < ActiveRecord::Migration[8.1]
  def change
    create_table :saved_views do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :name, null: false
      table.json :definition, null: false, default: {}
      table.boolean :favorite, null: false, default: false
      table.boolean :default_view, null: false, default: false
      table.integer :lock_version, null: false, default: 0
      table.timestamps
    end
    add_index :saved_views, [ :admin_user_id, :name ], unique: true
    add_index :saved_views, :admin_user_id, unique: true, where: "default_view = 1", name: "index_saved_views_one_default_per_owner"
  end
end
