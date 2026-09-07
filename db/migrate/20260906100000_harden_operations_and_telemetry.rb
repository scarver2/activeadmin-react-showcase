# db/migrate/20260906100000_harden_operations_and_telemetry.rb
# frozen_string_literal: true

class HardenOperationsAndTelemetry < ActiveRecord::Migration[8.1]
  def change
    change_table :operations, bulk: true do |t|
      t.string :claim_key
      t.datetime :claim_expires_at
      t.string :request_idempotency_key
      t.string :cancel_idempotency_key
    end

    add_index :operations, %i[admin_user_id request_idempotency_key],
              unique: true,
              where: "request_idempotency_key IS NOT NULL"

    create_table :telemetry_request_samples do |t|
      t.float :duration_ms, null: false
      t.integer :status, null: false
      t.datetime :occurred_at, null: false
    end

    add_index :telemetry_request_samples, :occurred_at
    add_check_constraint :telemetry_request_samples, "duration_ms >= 0", name: "telemetry_duration_nonnegative"
    add_check_constraint :telemetry_request_samples, "status BETWEEN 100 AND 599", name: "telemetry_valid_status"
  end
end
