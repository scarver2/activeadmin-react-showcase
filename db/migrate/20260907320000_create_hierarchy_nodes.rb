# db/migrate/20260907320000_create_hierarchy_nodes.rb
# frozen_string_literal: true

class CreateHierarchyNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :hierarchy_nodes do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.references :parent, foreign_key: { to_table: :hierarchy_nodes }
      table.integer :lock_version, default: 0, null: false
      table.integer :position, default: 0, null: false
      table.string :title, null: false
      table.timestamps
    end

    add_index :hierarchy_nodes, %i[admin_user_id parent_id position]
    add_check_constraint :hierarchy_nodes, "parent_id IS NULL OR parent_id != id", name: "hierarchy_nodes_not_self_parented"
  end
end
