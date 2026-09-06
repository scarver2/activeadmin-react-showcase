# db/migrate/20260906090001_create_operation_events.rb
# frozen_string_literal: true

class CreateOperationEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :operation_events do |t|
      t.references :operation, null: false, foreign_key: true
      t.integer :sequence, null: false
      t.string :idempotency_key, null: false
      t.string :state, null: false
      t.integer :progress, null: false
      t.string :message, null: false
      t.string :result
      t.string :error
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :operation_events, %i[operation_id sequence], unique: true
    add_index :operation_events, :idempotency_key, unique: true
    add_check_constraint :operation_events, "progress BETWEEN 0 AND 100", name: "operation_events_progress_range"
  end
end
