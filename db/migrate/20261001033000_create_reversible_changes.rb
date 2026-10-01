# db/migrate/20261001033000_create_reversible_changes.rb
# frozen_string_literal: true

class CreateReversibleChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :reversible_changes do |table|
      table.references :admin_user, null: false, foreign_key: true
      table.references :account, null: false, foreign_key: true
      table.string :request_key, null: false
      table.string :before_value, null: false
      table.string :after_value, null: false
      table.integer :applied_lock_version, null: false
      table.datetime :expires_at, null: false
      table.datetime :undone_at
      table.timestamps
    end
    add_index :reversible_changes, [ :admin_user_id, :request_key ], unique: true
    create_table :reversible_change_events do |table|
      table.references :reversible_change, null: false, foreign_key: true
      table.references :admin_user, null: false, foreign_key: true
      table.string :kind, null: false
      table.string :from_value, null: false
      table.string :to_value, null: false
      table.timestamps
    end
    add_index :reversible_change_events, [ :reversible_change_id, :kind ], unique: true
  end
end
