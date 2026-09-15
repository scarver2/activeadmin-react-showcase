# db/migrate/20260907430000_create_material_spheres.rb
# frozen_string_literal: true

class CreateMaterialSpheres < ActiveRecord::Migration[8.1]
  def change
    create_table :material_spheres do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :finish, null: false, default: "candy-red"
      table.integer :lock_version, null: false, default: 0
      table.string :name, null: false
      table.timestamps
    end
  end
end
