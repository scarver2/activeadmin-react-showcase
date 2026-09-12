# db/migrate/20260907430000_create_spacecraft_models.rb
# frozen_string_literal: true

class CreateSpacecraftModels < ActiveRecord::Migration[8.1]
  def change
    create_table :spacecraft_models do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :finish, null: false, default: "titanium"
      table.integer :lock_version, null: false, default: 0
      table.string :name, null: false
      table.string :selected_component_id, null: false, default: "fuselage"
      table.timestamps
    end
  end
end
