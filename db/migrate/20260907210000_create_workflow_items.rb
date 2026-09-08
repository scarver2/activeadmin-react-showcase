# db/migrate/20260907210000_create_workflow_items.rb
# frozen_string_literal: true

class CreateWorkflowItems < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_items do |table|
      table.string :title, null: false
      table.text :context
      table.string :state, null: false
      table.integer :position, null: false
      table.timestamps
    end

    add_index :workflow_items, %i[state position]
    add_check_constraint :workflow_items, "state IN ('backlog', 'ready', 'in_progress', 'review', 'done')", name: "workflow_items_valid_state"
    add_check_constraint :workflow_items, "position >= 0", name: "workflow_items_nonnegative_position"
  end
end
