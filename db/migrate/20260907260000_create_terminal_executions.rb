# db/migrate/20260907260000_create_terminal_executions.rb
# frozen_string_literal: true

class CreateTerminalExecutions < ActiveRecord::Migration[8.1]
  def change
    create_table :terminal_executions do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :command_key, null: false
      t.string :display_command, null: false
      t.string :state, null: false, default: "queued"
      t.string :idempotency_key, null: false
      t.datetime :cancel_requested_at
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :terminal_executions, :public_id, unique: true
    add_index :terminal_executions, %i[admin_user_id created_at]
    add_index :terminal_executions, %i[admin_user_id idempotency_key], unique: true
    add_check_constraint :terminal_executions,
                         "state IN ('queued', 'running', 'completed', 'failed', 'cancelled')",
                         name: "terminal_executions_valid_state"
  end
end
