# db/migrate/20260907320000_create_hierarchy_nodes.rb
# frozen_string_literal: true

class CreateHierarchyNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :hierarchy_nodes do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.string :ancestry, default: "/", null: false
      table.integer :ancestry_depth, default: 0, null: false
      table.integer :lock_version, default: 0, null: false
      table.integer :position, default: 0, null: false
      table.string :title, null: false
      table.timestamps
    end

    add_index :hierarchy_nodes, :ancestry
    add_index :hierarchy_nodes, %i[admin_user_id ancestry position]
  end
end
