# db/migrate/20260906090000_create_operations.rb
# frozen_string_literal: true

class CreateOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :operations do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :retry_of, foreign_key: { to_table: :operations }
      t.string :public_id, null: false
      t.string :kind, null: false, default: "successful_demo"
      t.string :state, null: false, default: "queued"
      t.integer :progress, null: false, default: 0
      t.string :message, null: false, default: "Waiting for a worker"
      t.string :result
      t.string :error
      t.datetime :cancel_requested_at
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :operations, :public_id, unique: true
    add_index :operations, %i[admin_user_id created_at]
    add_check_constraint :operations, "progress BETWEEN 0 AND 100", name: "operations_progress_range"
  end
end
