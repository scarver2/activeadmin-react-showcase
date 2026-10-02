# db/migrate/20261002000000_create_handoff_items.rb
# frozen_string_literal: true

class CreateHandoffItems < ActiveRecord::Migration[8.1]
  def change
    create_table :handoff_items do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :title, null: false
      t.string :state, null: false, default: "human"
      t.integer :progress, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :handoff_items, :public_id, unique: true
    add_check_constraint :handoff_items, "state IN ('human', 'agent', 'approval', 'completed', 'cancelled')", name: "handoff_items_state"
    add_check_constraint :handoff_items, "progress BETWEEN 0 AND 100", name: "handoff_items_progress"

    create_table :handoff_events do |t|
      t.references :handoff_item, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :command_id, null: false
      t.string :action, null: false
      t.string :actor, null: false
      t.text :evidence, null: false
      t.timestamps
    end
    add_index :handoff_events, %i[handoff_item_id sequence], unique: true
    add_index :handoff_events, %i[handoff_item_id command_id], unique: true
  end
end
